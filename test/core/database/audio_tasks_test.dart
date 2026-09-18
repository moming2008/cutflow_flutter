import 'dart:async';
import 'dart:io';

// drift 与 matcher 都导出 isNull/isNotNull，这里显式隐藏 drift 的同名顶层函数
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:cutflow_flutter/core/database/app_database.dart';

AudioTasksCompanion _companion({
  String outputName = 'song.mp3',
  String status = 'PENDING',
}) {
  return AudioTasksCompanion.insert(
    sourcePath: '/test/video.mp4',
    sourceName: 'video.mp4',
    sourceDurationMs: 180000,
    trimStartMs: 0,
    trimEndMs: 165000,
    targetBitrateKbps: 320,
    outputName: outputName,
    status: status,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

void main() {
  group('AudioTasks CRUD', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTest(NativeDatabase.memory());
    });

    // 必须 await：close() 抛出的异常若无人接管会变成未处理的异步错误，
    // 而且失败的用例会把连接泄漏给下一个 setUp
    tearDown(() async {
      await database.close();
    });

    test('插入并读回音频任务', () async {
      final id = await database.insertAudioTask(_companion());
      expect(id, greaterThan(0));

      final task = await database.getAudioTaskById(id);
      expect(task, isNotNull);
      expect(task!.sourcePath, equals('/test/video.mp4'));
      expect(task.trimEndMs, equals(165000));
      expect(task.targetBitrateKbps, equals(320));
      expect(task.status, equals('PENDING'));
      // 可空字段默认空
      expect(task.title, isNull);
      expect(task.coverPath, isNull);
      expect(task.outputPath, isNull);
      expect(task.progress, equals(0));
    });

    test('更新状态、进度与完成信息', () async {
      final id = await database.insertAudioTask(_companion());

      await database.updateAudioTaskFull(
        id: id,
        status: 'EXPORTING',
        progress: 42,
      );
      var task = await database.getAudioTaskById(id);
      expect(task!.status, equals('EXPORTING'));
      expect(task.progress, equals(42));

      await database.updateAudioTaskFull(
        id: id,
        status: 'DONE',
        progress: 100,
        outputPath: '/out/song.mp3',
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      task = await database.getAudioTaskById(id);
      expect(task!.status, equals('DONE'));
      expect(task.outputPath, equals('/out/song.mp3'));
      expect(task.completedAt, isNotNull);
    });

    test('删除音频任务', () async {
      final id = await database.insertAudioTask(_companion());
      await database.deleteAudioTask(id);
      expect(await database.getAudioTaskById(id), isNull);
    });

    test('按创建时间倒序列出全部任务', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await database.insertAudioTask(
          _companion(outputName: 'old.mp3').copyWith(createdAt: Value(now - 10000)));
      await database.insertAudioTask(
          _companion(outputName: 'new.mp3').copyWith(createdAt: Value(now)));

      final tasks = await database.getAllAudioTasks();
      expect(tasks.length, equals(2));
      expect(tasks.first.outputName, equals('new.mp3'));
    });

    test('watchAllAudioTasks 在同一订阅上推送新值', () async {
      final stream = database.watchAllAudioTasks();
      final events = <List<AudioTask>>[];
      final firstEvent = Completer<void>();
      final secondEvent = Completer<void>();

      final subscription = stream.listen((rows) {
        events.add(rows);
        // 首个事件是当前（空）结果，第二个事件应由插入触发
        if (events.length == 1 && !firstEvent.isCompleted) {
          firstEvent.complete();
        } else if (events.length == 2 && !secondEvent.isCompleted) {
          secondEvent.complete();
        }
      });

      // 必须先等首个事件落地：drift 的初始查询是异步的，若在它完成前就插入，
      // 插入结果会被并进首个事件里，第二次事件就不会到来（订阅本身没问题）。
      await firstEvent.future;
      await database.insertAudioTask(_companion());
      // 等到第二个事件真的到达；若流只会在订阅时查询一次，这里会超时失败
      await secondEvent.future;
      await subscription.cancel();

      expect(events.first, isEmpty);
      expect(events.last.length, equals(1));
    });
  });

  group('数据库迁移 v2 → v3', () {
    test('新增 audio_tasks 表且视频数据完好', () async {
      final dir = await Directory.systemTemp.createTemp('cutflow_migration');
      final file = File(p.join(dir.path, 'migration.db'));

      try {
        // 1. 建库并写入一条视频数据
        var db = AppDatabase.forTest(NativeDatabase(file));
        final videoId = await db.into(db.videoItems).insert(
              VideoItemsCompanion.insert(
                path: '/test/migration.mp4',
                name: 'migration.mp4',
                duration: 120000,
                width: 1920,
                height: 1080,
                fileSize: 1024 * 1024,
                frameRate: 30.0,
                codec: 'h264',
                importedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );

        // 2. 把库「降级」成 v2 形态：v2 与 v3 的唯一差别就是没有 audio_tasks 表
        await db.customStatement('DROP TABLE IF EXISTS audio_tasks');
        await db.customStatement('PRAGMA user_version = 2');
        await db.close();

        // 3. 重新打开 —— 触发 onUpgrade(2 → 3)
        db = AppDatabase.forTest(NativeDatabase(file));
        await db.customSelect('SELECT 1').get();

        // 4. audio_tasks 已被迁移重建，可正常写入
        final audioId = await db.insertAudioTask(_companion());
        expect(audioId, greaterThan(0));

        // 5. 旧视频数据完好无损
        final video = await db.getVideoById(videoId);
        expect(video, isNotNull);
        expect(video!.path, equals('/test/migration.mp4'));
        expect(video.width, equals(1920));

        await db.close();
      } finally {
        // 清理失败不应顶掉主体抛出的真实异常：
        // 主体中途抛错时末尾的 db.close() 不会执行，库文件仍被占用，
        // delete 会抛 PathAccessException，而 finally 里的异常会替换掉原始异常。
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      }
    });
  });
}
