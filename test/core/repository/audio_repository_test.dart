import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

// drift 生成的 AudioTask 与领域模型同名，这里只取 AppDatabase，
// 显式隐藏数据库侧的 AudioTask 以免命名冲突
import 'package:cutflow_flutter/core/database/app_database.dart' hide AudioTask;
import 'package:cutflow_flutter/core/model/audio_task.dart';
import 'package:cutflow_flutter/core/repository/audio_repository.dart';

AudioTask _task({String outputName = 'song.mp3'}) {
  return AudioTask(
    id: 0,
    sourcePath: '/test/video.mp4',
    sourceName: 'video.mp4',
    sourceDurationMs: 180000,
    sourceBitrateKbps: 192,
    trimStartMs: 30000,
    trimEndMs: 195000,
    title: '歌名',
    artist: '歌手',
    album: '专辑',
    coverPath: '/test/cover.jpg',
    targetBitrateKbps: 320,
    outputName: outputName,
    status: AudioTaskStatus.pending,
    progress: 0,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

void main() {
  late AppDatabase db;
  late AudioRepository repo;

  setUp(() {
    db = AppDatabase.forTest(NativeDatabase.memory());
    repo = AudioRepository(db);
  });

  tearDown(() => db.close());

  test('插入并读回，状态枚举往返正确', () async {
    final id = await repo.insertTask(_task());
    final loaded = await repo.getTaskById(id);

    expect(loaded, isNotNull);
    expect(loaded!.status, equals(AudioTaskStatus.pending));
    expect(loaded.title, equals('歌名'));
    expect(loaded.artist, equals('歌手'));
    expect(loaded.album, equals('专辑'));
    expect(loaded.coverPath, equals('/test/cover.jpg'));
    expect(loaded.sourceBitrateKbps, equals(192));
    expect(loaded.targetBitrateKbps, equals(320));
    expect(loaded.trimStartMs, equals(30000));
  });

  test('insertTask 保留 outputPath / completedAt / errorMessage', () async {
    final task = _task().copyWith(
      status: AudioTaskStatus.failed,
      outputPath: '/out/song.mp3',
      errorMessage: '输出文件被占用',
      completedAt: 1700000000000,
    );

    final id = await repo.insertTask(task);
    final loaded = await repo.getTaskById(id);

    expect(loaded, isNotNull);
    expect(loaded!.outputPath, equals('/out/song.mp3'));
    expect(loaded.errorMessage, equals('输出文件被占用'));
    expect(loaded.completedAt, equals(1700000000000));
  });

  test('updateTaskFull 可改状态、进度与输出路径', () async {
    final id = await repo.insertTask(_task());

    await repo.updateTaskFull(id: id, status: 'EXPORTING', progress: 55);
    var loaded = await repo.getTaskById(id);
    expect(loaded!.status, equals(AudioTaskStatus.exporting));
    expect(loaded.progress, equals(55));

    await repo.updateTaskFull(
      id: id,
      status: 'DONE',
      progress: 100,
      outputPath: '/out/song.mp3',
      completedAt: 1700000000000,
    );
    loaded = await repo.getTaskById(id);
    expect(loaded!.status, equals(AudioTaskStatus.done));
    expect(loaded.isCompleted, isTrue);
    expect(loaded.outputPath, equals('/out/song.mp3'));
    expect(loaded.completedAt, equals(1700000000000));
  });

  test('未知状态字符串回退为 pending（不抛异常）', () async {
    final id = await repo.insertTask(_task());
    await db.customStatement(
        "UPDATE audio_tasks SET status = 'WHATEVER' WHERE id = $id");
    final loaded = await repo.getTaskById(id);
    expect(loaded!.status, equals(AudioTaskStatus.pending));
  });

  test('删除任务', () async {
    final id = await repo.insertTask(_task());
    await repo.deleteTask(id);
    expect(await repo.getTaskById(id), isNull);
  });

  test('watchAllTasks 响应式推送', () async {
    final stream = repo.watchAllTasks();
    expect(await stream.first, isEmpty);

    await repo.insertTask(_task());
    final after = await stream.first;
    expect(after.length, equals(1));
    expect(after.first.outputName, equals('song.mp3'));
  });

  test('statusText 文案覆盖四种状态', () {
    expect(_task().copyWith(status: AudioTaskStatus.pending).statusText,
        equals('等待中'));
    expect(_task().copyWith(status: AudioTaskStatus.exporting).statusText,
        equals('转换中'));
    expect(_task().copyWith(status: AudioTaskStatus.done).statusText,
        equals('已完成'));
    expect(_task().copyWith(status: AudioTaskStatus.failed).statusText,
        equals('转换失败'));
  });
}
