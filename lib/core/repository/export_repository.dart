import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../model/export_task.dart';

class ExportRepository {
  final db.AppDatabase _db;

  ExportRepository(this._db);

  /// 获取所有任务(按创建时间倒序)
  Future<List<ExportTask>> getAllTasks() async {
    final rows = await _db.getAllTasks();
    return rows.map(_fromDb).toList();
  }

  /// 获取待处理任务
  Future<List<ExportTask>> getPendingTasks() async {
    final rows = await _db.getPendingTasks();
    return rows.map(_fromDb).toList();
  }

  /// 根据ID获取任务
  Future<ExportTask?> getTaskById(int id) async {
    final row = await _db.getTaskById(id);
    return row != null ? _fromDb(row) : null;
  }

  /// 插入任务
  Future<int> insertTask(ExportTask task) async {
    final companion = db.ExportTasksCompanion.insert(
      sourceVideoId: task.sourceVideoId,
      outputName: task.outputName,
      trimStartMs: task.trimStartMs,
      trimEndMs: task.trimEndMs,
      cropPresetId: Value(task.cropPresetId),
      cropSnapshot: Value(task.cropSnapshot),
      cropPresetName: Value(task.cropPresetName),
      cropRatioLabel: Value(task.cropRatioLabel),
      sourceVideoName: Value(task.sourceVideoName),
      status: _statusToString(task.status),
      progress: Value(task.progress),
      createdAt: task.createdAt,
      outputPath: Value(task.outputPath),
      completedAt: Value(task.completedAt),
      archivedAt: Value(task.archivedAt),
      errorMessage: Value(task.errorMessage),
    );
    return await _db.into(_db.exportTasks).insert(companion);
  }

  /// 更新任务状态
  Future<void> updateTaskStatus(int id, TaskStatus status) async {
    await _db.updateTaskStatus(id, _statusToString(status));
  }

  /// 更新任务进度
  Future<void> updateTaskProgress(int id, int progress) async {
    await _db.updateTaskProgress(id, progress);
  }

  /// 更新任务
  Future<void> updateTask(ExportTask task) async {
    final companion = db.ExportTasksCompanion(
      id: Value(task.id),
      sourceVideoId: Value(task.sourceVideoId),
      outputName: Value(task.outputName),
      trimStartMs: Value(task.trimStartMs),
      trimEndMs: Value(task.trimEndMs),
      cropPresetId: Value(task.cropPresetId),
      cropSnapshot: Value(task.cropSnapshot),
      cropPresetName: Value(task.cropPresetName),
      cropRatioLabel: Value(task.cropRatioLabel),
      sourceVideoName: Value(task.sourceVideoName),
      status: Value(_statusToString(task.status)),
      progress: Value(task.progress),
      createdAt: Value(task.createdAt),
      outputPath: Value(task.outputPath),
      completedAt: Value(task.completedAt),
      archivedAt: Value(task.archivedAt),
      errorMessage: Value(task.errorMessage),
    );
    await _db.updateTask(companion);
  }

  /// 删除任务
  Future<void> deleteTask(int id) async {
    await _db.deleteTask(id);
  }

  /// 响应式监听所有任务
  Stream<List<ExportTask>> watchAllTasks() {
    return _db.watchAllTasks().map((rows) => rows.map(_fromDb).toList());
  }

  /// 响应式监听待处理任务
  Stream<List<ExportTask>> watchPendingTasks() {
    return _db.watchPendingTasks().map((rows) => rows.map(_fromDb).toList());
  }

  // ==================== v2: 新增查询方法 ====================

  /// 获取已完成且未归档的任务（已转码列表）
  Future<List<ExportTask>> getCompletedTasks() async {
    final rows = await _db.getCompletedTasks();
    return rows.map(_fromDb).toList();
  }

  /// 响应式监听已完成且未归档的任务
  Stream<List<ExportTask>> watchCompletedTasks() {
    return _db.watchCompletedTasks().map((rows) => rows.map(_fromDb).toList());
  }

  /// 获取队列中的任务（pending/preparing/exporting/failed）
  Future<List<ExportTask>> getQueuedTasks() async {
    final rows = await _db.getQueuedTasks();
    return rows.map(_fromDb).toList();
  }

  /// 响应式监听队列中的任务
  Stream<List<ExportTask>> watchQueuedTasks() {
    return _db.watchQueuedTasks().map((rows) => rows.map(_fromDb).toList());
  }

  /// 归档任务
  Future<void> archiveTask(int id) async {
    await _db.archiveTask(id, DateTime.now().millisecondsSinceEpoch);
  }

  /// 获取已归档的任务
  Future<List<ExportTask>> getArchivedTasks() async {
    final rows = await _db.getArchivedTasks();
    return rows.map(_fromDb).toList();
  }

  /// 取消归档
  Future<void> unarchiveTask(int id) async {
    await _db.unarchiveTask(id);
  }

  /// 批量更新任务字段（状态、进度、输出路径、完成时间、错误信息）
  Future<void> updateTaskFull({
    required int id,
    String? status,
    int? progress,
    String? outputPath,
    int? completedAt,
    String? errorMessage,
  }) async {
    await _db.updateTaskFull(
      id: id,
      status: status,
      progress: progress,
      outputPath: outputPath,
      completedAt: completedAt,
      errorMessage: errorMessage,
    );
  }

  // ==================== Private Helpers ====================

  ExportTask _fromDb(db.ExportTask row) {
    return ExportTask(
      id: row.id,
      sourceVideoId: row.sourceVideoId,
      outputName: row.outputName,
      trimStartMs: row.trimStartMs,
      trimEndMs: row.trimEndMs,
      cropPresetId: row.cropPresetId,
      cropSnapshot: row.cropSnapshot,
      cropPresetName: row.cropPresetName,
      cropRatioLabel: row.cropRatioLabel,
      sourceVideoName: row.sourceVideoName,
      status: _statusFromString(row.status),
      progress: row.progress,
      createdAt: row.createdAt,
      outputPath: row.outputPath,
      completedAt: row.completedAt,
      archivedAt: row.archivedAt,
      errorMessage: row.errorMessage,
    );
  }

  String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'PENDING';
      case TaskStatus.preparing:
        return 'PREPARING';
      case TaskStatus.exporting:
        return 'EXPORTING';
      case TaskStatus.done:
        return 'DONE';
      case TaskStatus.failed:
        return 'FAILED';
    }
  }

  TaskStatus _statusFromString(String status) {
    switch (status) {
      case 'PENDING':
        return TaskStatus.pending;
      case 'PREPARING':
        return TaskStatus.preparing;
      case 'EXPORTING':
        return TaskStatus.exporting;
      case 'DONE':
        return TaskStatus.done;
      case 'FAILED':
        return TaskStatus.failed;
      default:
        return TaskStatus.pending;
    }
  }
}
