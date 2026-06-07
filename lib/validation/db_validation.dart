import 'package:flutter/material.dart';
import 'package:cutflow_flutter/core/database/app_database.dart';
import '../core/util/logger.dart';

// 数据库层验证脚本
// 运行方式: flutter run -d windows lib/validation/db_validation.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  log().i('=== 数据库层验证开始 ===\n');
  
  final database = AppDatabase();
  
  try {
    // 1. 测试视频插入和查询
    log().i('1. 测试 VideoItems...');
    await testVideoItems(database);
    log().i('✓ VideoItems 测试通过\n');
    
    // 2. 测试导出任务
    log().i('2. 测试 ExportTasks...');
    await testExportTasks(database);
    log().i('✓ ExportTasks 测试通过\n');
    
    // 3. 测试裁切预设
    log().i('3. 测试 CropPresets...');
    await testCropPresets(database);
    log().i('✓ CropPresets 测试通过\n');
    
    // 4. 测试编辑草稿
    log().i('4. 测试 EditorDrafts...');
    await testEditorDrafts(database);
    log().i('✓ EditorDrafts 测试通过\n');
    
    log().i('=== 所有测试通过! ===');
  } catch (e) {
    log().e('✗ 测试失败: $e');
  } finally {
    await database.close();
  }
}

Future<void> testVideoItems(AppDatabase db) async {
  // 插入测试数据
  final video = VideoItemsCompanion.insert(
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
  
  final id = await db.into(db.videoItems).insert(video);
  log().d('  插入视频 ID: $id');
  
  // 查询验证
  final retrieved = await db.getVideoById(id);
  assert(retrieved != null, '查询返回null');
  assert(retrieved!.name == 'test_video.mp4', '名称不匹配');
  log().d('  查询验证通过');
  
  // 删除测试
  await db.deleteVideo(id);
  final afterDelete = await db.getVideoById(id);
  assert(afterDelete == null, '删除后仍能查询到');
  log().d('  删除验证通过');
}

Future<void> testExportTasks(AppDatabase db) async {
  final task = ExportTasksCompanion.insert(
    sourceVideoId: 1,
    outputName: 'output.mp4',
    trimStartMs: 1000,
    trimEndMs: 5000,
    status: 'PENDING',
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
  
  final id = await db.into(db.exportTasks).insert(task);
  log().d('  插入任务 ID: $id');
  
  // 更新状态
  await db.updateTaskStatus(id, 'EXPORTING');
  await db.updateTaskProgress(id, 50);
  
  final updated = await db.getTaskById(id);
  assert(updated != null, '查询返回null');
  assert(updated!.status == 'EXPORTING', '状态未更新');
  assert(updated!.progress == 50, '进度未更新');
  log().d('  状态更新验证通过');
  
  // 清理
  await db.deleteTask(id);
}

Future<void> testCropPresets(AppDatabase db) async {
  final preset = CropPresetsCompanion.insert(
    name: '16:9 1920×1080',
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
  
  final id = await db.into(db.cropPresets).insert(preset);
  log().d('  插入预设 ID: $id');
  
  final retrieved = await db.getPresetById(id);
  assert(retrieved != null, '查询返回null');
  assert(retrieved!.ratioW == 16, '比例宽度不匹配');
  log().d('  查询验证通过');
  
  // 清理
  await db.deletePreset(id);
}

Future<void> testEditorDrafts(AppDatabase db) async {
  final draft = EditorDraftsCompanion.insert(
    sourceVideoId: 1,
    outputName: 'draft.mp4',
    trimStartMs: 1000,
    trimEndMs: 5000,
    updatedAt: DateTime.now().millisecondsSinceEpoch,
  );
  
  final id = await db.into(db.editorDrafts).insert(draft);
  log().d('  插入草稿 ID: $id');
  
  final retrieved = await db.getDraftByVideoId(1);
  assert(retrieved != null, '查询返回null');
  assert(retrieved!.outputName == 'draft.mp4', '输出名称不匹配');
  log().d('  查询验证通过');
  
  // 清理
  await db.deleteDraft(id);
}
