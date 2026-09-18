/// 音频任务仓储
///
/// 负责领域模型 [AudioTask] 与 Drift 行 [db.AudioTask] 之间的映射，
/// 与视频侧的 ExportRepository 完全隔离。
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../model/audio_task.dart';

class AudioRepository {
  final db.AppDatabase _db;

  AudioRepository(this._db);

  /// 全部任务（最近创建的在前）
  Future<List<AudioTask>> getAllTasks() async {
    final rows = await _db.getAllAudioTasks();
    return rows.map(_fromDb).toList();
  }

  Future<AudioTask?> getTaskById(int id) async {
    final row = await _db.getAudioTaskById(id);
    return row != null ? _fromDb(row) : null;
  }

  Future<int> insertTask(AudioTask task) async {
    final companion = db.AudioTasksCompanion.insert(
      sourcePath: task.sourcePath,
      sourceName: task.sourceName,
      sourceDurationMs: task.sourceDurationMs,
      sourceBitrateKbps: Value(task.sourceBitrateKbps),
      trimStartMs: task.trimStartMs,
      trimEndMs: task.trimEndMs,
      title: Value(task.title),
      artist: Value(task.artist),
      album: Value(task.album),
      coverPath: Value(task.coverPath),
      targetBitrateKbps: task.targetBitrateKbps,
      outputName: task.outputName,
      status: _statusToString(task.status),
      progress: Value(task.progress),
      createdAt: task.createdAt,
    );
    return await _db.insertAudioTask(companion);
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteAudioTask(id);
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
    await _db.updateAudioTaskFull(
      id: id,
      status: status,
      progress: progress,
      outputPath: outputPath,
      completedAt: completedAt,
      errorMessage: errorMessage,
    );
  }

  /// 响应式监听全部任务
  Stream<List<AudioTask>> watchAllTasks() {
    return _db.watchAllAudioTasks().map((rows) => rows.map(_fromDb).toList());
  }

  // ==================== Private Helpers ====================

  AudioTask _fromDb(db.AudioTask row) {
    return AudioTask(
      id: row.id,
      sourcePath: row.sourcePath,
      sourceName: row.sourceName,
      sourceDurationMs: row.sourceDurationMs,
      sourceBitrateKbps: row.sourceBitrateKbps,
      trimStartMs: row.trimStartMs,
      trimEndMs: row.trimEndMs,
      title: row.title,
      artist: row.artist,
      album: row.album,
      coverPath: row.coverPath,
      targetBitrateKbps: row.targetBitrateKbps,
      outputName: row.outputName,
      outputPath: row.outputPath,
      status: _statusFromString(row.status),
      progress: row.progress,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
    );
  }

  String _statusToString(AudioTaskStatus status) {
    switch (status) {
      case AudioTaskStatus.pending:
        return 'PENDING';
      case AudioTaskStatus.exporting:
        return 'EXPORTING';
      case AudioTaskStatus.done:
        return 'DONE';
      case AudioTaskStatus.failed:
        return 'FAILED';
    }
  }

  AudioTaskStatus _statusFromString(String status) {
    switch (status) {
      case 'PENDING':
        return AudioTaskStatus.pending;
      case 'EXPORTING':
        return AudioTaskStatus.exporting;
      case 'DONE':
        return AudioTaskStatus.done;
      case 'FAILED':
        return AudioTaskStatus.failed;
      default:
        return AudioTaskStatus.pending;
    }
  }
}
