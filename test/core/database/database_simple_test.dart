import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:cutflow_flutter/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // 使用内存数据库进行测试
    database = AppDatabase.forTest(NativeDatabase.memory());
  });

  tearDown(() {
    database.close();
  });

  group('VideoItems Tests', () {
    test('should insert and retrieve a video', () async {
      final companion = VideoItemsCompanion.insert(
        path: '/test/video.mp4',
        name: 'test_video.mp4',
        duration: 60000,
        width: 1920,
        height: 1080,
        fileSize: 1024 * 1024 * 10,
        frameRate: 30.0,
        codec: 'h264',
        importedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Insert video
      final id = await database.into(database.videoItems).insert(companion);
      expect(id, greaterThan(0));

      // Retrieve video
      final retrieved = await database.getVideoById(id);
      expect(retrieved != null, true);
      expect(retrieved!.path, equals('/test/video.mp4'));
      expect(retrieved.name, equals('test_video.mp4'));
      expect(retrieved.duration, equals(60000));
    });

    test('should delete a video', () async {
      final companion = VideoItemsCompanion.insert(
        path: '/test/video2.mp4',
        name: 'test_video2.mp4',
        duration: 30000,
        width: 1280,
        height: 720,
        fileSize: 5 * 1024 * 1024,
        frameRate: 24.0,
        codec: 'h264',
        importedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await database.into(database.videoItems).insert(companion);
      
      // Delete video
      await database.deleteVideo(id);

      // Verify deletion
      final retrieved = await database.getVideoById(id);
      expect(retrieved == null, true);
    });
  });

  group('ExportTasks Tests', () {
    test('should insert and update task status', () async {
      final companion = ExportTasksCompanion.insert(
        sourceVideoId: 1,
        outputName: 'output.mp4',
        trimStartMs: 1000,
        trimEndMs: 5000,
        status: 'PENDING',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final id = await database.into(database.exportTasks).insert(companion);
      expect(id, greaterThan(0));

      // Update status
      await database.updateTaskStatus(id, 'EXPORTING');
      await database.updateTaskProgress(id, 50);

      final updated = await database.getTaskById(id);
      expect(updated != null, true);
      expect(updated!.status, equals('EXPORTING'));
      expect(updated.progress, equals(50));
    });

    test('should get pending tasks', () async {
      final task1 = ExportTasksCompanion.insert(
        sourceVideoId: 1,
        outputName: 'task1.mp4',
        trimStartMs: 0,
        trimEndMs: 10000,
        status: 'PENDING',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      final task2 = ExportTasksCompanion.insert(
        sourceVideoId: 1,
        outputName: 'task2.mp4',
        trimStartMs: 0,
        trimEndMs: 10000,
        status: 'DONE',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await database.into(database.exportTasks).insert(task1);
      await database.into(database.exportTasks).insert(task2);

      final pending = await database.getPendingTasks();
      expect(pending.length, equals(1));
      expect(pending[0].outputName, equals('task1.mp4'));
    });
  });

  group('CropPresets Tests', () {
    test('should insert and retrieve presets in order', () async {
      final preset1 = CropPresetsCompanion.insert(
        name: 'Preset 3',
        ratioLabel: '1:1',
        ratioW: 1,
        ratioH: 1,
        outputW: 1080,
        outputH: 1080,
        offsetX: 0,
        offsetY: 0,
        isBuiltin: true,
        sortOrder: 3,
      );

      final preset2 = CropPresetsCompanion.insert(
        name: 'Preset 1',
        ratioLabel: '16:9',
        ratioW: 16,
        ratioH: 9,
        outputW: 1920,
        outputH: 1080,
        offsetX: 0,
        offsetY: 0,
        isBuiltin: true,
        sortOrder: 1,
      );

      await database.into(database.cropPresets).insert(preset1);
      await database.into(database.cropPresets).insert(preset2);

      final presets = await database.getAllPresets();
      
      expect(presets.length, equals(2));
      expect(presets[0].name, equals('Preset 1')); // sortOrder 1
      expect(presets[1].name, equals('Preset 3')); // sortOrder 3
    });
  });

  group('EditorDrafts Tests', () {
    test('should upsert draft', () async {
      final draft1 = EditorDraftsCompanion.insert(
        sourceVideoId: 1,
        outputName: 'original.mp4',
        trimStartMs: 0,
        trimEndMs: 10000,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Insert first draft
      await database.into(database.editorDrafts).insert(draft1);

      // Update with new values
      final draft2 = EditorDraftsCompanion(
        sourceVideoId: Value(1),
        outputName: Value('updated.mp4'),
        trimStartMs: Value(1000),
        trimEndMs: Value(5000),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch + 1000),
      );

      await (database.update(database.editorDrafts)
        ..where((t) => t.sourceVideoId.equals(1)))
        .write(draft2);

      final retrieved = await database.getDraftByVideoId(1);
      expect(retrieved != null, true);
      expect(retrieved!.outputName, equals('updated.mp4'));
      expect(retrieved.trimStartMs, equals(1000));
    });
  });
}
