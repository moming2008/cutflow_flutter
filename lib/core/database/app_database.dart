import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ==================== Table Definitions ====================

class VideoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text()();
  TextColumn get name => text()();
  IntColumn get duration => integer()(); // 毫秒
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  IntColumn get fileSize => integer()();
  RealColumn get frameRate => real()();
  TextColumn get codec => text()();
  IntColumn get importedAt => integer()(); // 时间戳
}

class ExportTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceVideoId => integer()();
  TextColumn get outputName => text()();
  IntColumn get trimStartMs => integer()();
  IntColumn get trimEndMs => integer()();
  IntColumn get cropPresetId => integer().nullable()();
  TextColumn get cropSnapshot => text().nullable()();
  TextColumn get cropPresetName => text().nullable()();
  TextColumn get cropRatioLabel => text().nullable()();
  TextColumn get sourceVideoName => text().nullable()();
  TextColumn get status => text()(); // PENDING/PREPARING/EXPORTING/DONE/FAILED
  IntColumn get progress => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  // v2 新增字段
  TextColumn get outputPath => text().nullable()(); // 导出文件完整路径
  IntColumn get completedAt => integer().nullable()(); // 完成时间戳
  IntColumn get archivedAt => integer().nullable()(); // 归档时间戳
  TextColumn get errorMessage => text().nullable()(); // FFmpeg 错误信息
  
  Set<Index> get indexes => {
    Index('source_video_id_idx', 'CREATE INDEX source_video_id_idx ON export_tasks (sourceVideoId)'),
    Index('status_idx', 'CREATE INDEX status_idx ON export_tasks (status)'),
  };
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class CropPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get ratioLabel => text()();
  IntColumn get ratioW => integer()();
  IntColumn get ratioH => integer()();
  IntColumn get outputW => integer()(); // 固定输出宽度(0表示比例模式)
  IntColumn get outputH => integer()(); // 固定输出高度
  IntColumn get offsetX => integer()();
  IntColumn get offsetY => integer()();
  BoolColumn get isBuiltin => boolean()();
  IntColumn get sortOrder => integer()();
}

class EditorDrafts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sourceVideoId => integer().unique()(); // 唯一索引
  TextColumn get outputName => text()();
  IntColumn get trimStartMs => integer()();
  IntColumn get trimEndMs => integer()();
  IntColumn get selectedCropPresetId => integer().nullable()();
  IntColumn get updatedAt => integer()(); // 时间戳
  
  Set<Index> get indexes => {
    Index('source_video_id_unique_idx', 'CREATE UNIQUE INDEX source_video_id_unique_idx ON editor_drafts (sourceVideoId)'),
  };
}

/// 音频提取任务
///
/// 单表方案：一条记录 = 一次音频转换，输入参数与输出结果同存。
/// 与视频侧表（VideoItems / ExportTasks）结构上完全隔离。
class AudioTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourcePath => text()();
  TextColumn get sourceName => text()();
  IntColumn get sourceDurationMs => integer()();
  IntColumn get sourceBitrateKbps => integer().nullable()(); // null = 探测不到
  IntColumn get trimStartMs => integer()();
  IntColumn get trimEndMs => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  IntColumn get targetBitrateKbps => integer()();
  TextColumn get outputName => text()();
  TextColumn get outputPath => text().nullable()();
  TextColumn get status => text()(); // PENDING/EXPORTING/DONE/FAILED
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  // 本表刻意不声明自定义索引。
  // 视频侧表（ExportTasks / EditorDrafts）里的 `Set<Index> get indexes` 是遗留死代码：
  // drift 从未读取该 getter（生成器只识别 primaryKey / uniqueKeys / tableName，
  // 官方机制是类级注解 @TableIndex），它们的索引实际从未在 SQLite 中建立。
  // 与其复制一段看似生效、实则无效的声明，不如不写；本功能也没有需要索引的查询。
}

// ==================== Database ====================

@DriftDatabase(tables: [
  VideoItems,
  ExportTasks,
  CropPresets,
  EditorDrafts,
  AppSettings,
  AudioTasks,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// 测试用构造函数，接受自定义 QueryExecutor (如 NativeDatabase.memory())
  AppDatabase.forTest(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // v1 -> v2: 新增 ExportTasks 字段
          await m.addColumn(exportTasks, exportTasks.outputPath);
          await m.addColumn(exportTasks, exportTasks.completedAt);
          await m.addColumn(exportTasks, exportTasks.archivedAt);
          await m.addColumn(exportTasks, exportTasks.errorMessage);
          // v1 -> v2: 新增 AppSettings 表
          await m.createTable(appSettings);
        }
        if (from < 3) {
          // v2 -> v3: 新增 AudioTasks 表（音频提取功能）
          // 视频侧表结构不变，旧数据零影响
          await m.createTable(audioTasks);
        }
      },
    );
  }

  // ==================== VideoItems DAO ====================
  
  Future<List<VideoItem>> getAllVideos() async {
    return await (select(videoItems)
      ..orderBy([(t) => OrderingTerm.desc(t.importedAt)])
    ).get();
  }

  Future<VideoItem?> getVideoById(int id) async {
    return await (select(videoItems)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> deleteVideo(int id) async {
    await (delete(videoItems)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateVideo(Insertable<VideoItem> video) async {
    await update(videoItems).replace(video);
  }

  // ==================== ExportTasks DAO ====================
  
  Future<List<ExportTask>> getAllTasks() async {
    return await (select(exportTasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).get();
  }

  Future<List<ExportTask>> getPendingTasks() async {
    return await (select(exportTasks)
      ..where((t) => t.status.equals('PENDING'))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
    ).get();
  }

  Future<ExportTask?> getTaskById(int id) async {
    return await (select(exportTasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateTaskStatus(int id, String status) async {
    await (update(exportTasks)..where((t) => t.id.equals(id)))
        .write(ExportTasksCompanion(status: Value(status)));
  }

  Future<void> updateTaskProgress(int id, int progress) async {
    await (update(exportTasks)..where((t) => t.id.equals(id)))
        .write(ExportTasksCompanion(progress: Value(progress)));
  }

  Future<void> updateTask(Insertable<ExportTask> task) async {
    await update(exportTasks).replace(task);
  }

  Future<void> deleteTask(int id) async {
    await (delete(exportTasks)..where((t) => t.id.equals(id))).go();
  }

  // 响应式监听
  Stream<List<ExportTask>> watchAllTasks() {
    return select(exportTasks).watch();
  }

  Stream<List<ExportTask>> watchPendingTasks() {
    return (select(exportTasks)..where((t) => t.status.equals('PENDING'))).watch();
  }

  // ==================== CropPresets DAO ====================
  
  Future<List<CropPreset>> getAllPresets() async {
    return await (select(cropPresets)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])
    ).get();
  }

  Future<CropPreset?> getPresetById(int id) async {
    return await (select(cropPresets)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPreset(CropPreset preset) async {
    return await into(cropPresets).insert(preset);
  }

  Future<void> deletePreset(int id) async {
    await (delete(cropPresets)..where((t) => t.id.equals(id))).go();
  }

  // ==================== EditorDrafts DAO ====================
  
  Future<EditorDraft?> getDraftByVideoId(int videoId) async {
    return await (select(editorDrafts)
      ..where((t) => t.sourceVideoId.equals(videoId))
    ).getSingleOrNull();
  }

  Future<void> updateDraft(Insertable<EditorDraft> draft) async {
    await update(editorDrafts).replace(draft);
  }

  /// Upsert draft (insert or update)
  Future<void> upsertDraft(EditorDraft draft) async {
    final existing = await getDraftByVideoId(draft.sourceVideoId);
    if (existing != null) {
      await updateDraft(draft);
    } else {
      await into(editorDrafts).insert(draft);
    }
  }

  Future<void> deleteDraft(int id) async {
    await (delete(editorDrafts)..where((t) => t.id.equals(id))).go();
  }

  Future<List<EditorDraft>> getAllDrafts() async {
    return await (select(editorDrafts)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
    ).get();
  }

  // ==================== v2: ExportTasks 扩展查询 ====================

  /// 获取已完成且未归档的任务（已转码列表）
  Future<List<ExportTask>> getCompletedTasks() async {
    return await (select(exportTasks)
      ..where((t) =>
          t.status.equals('DONE') & t.archivedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
    ).get();
  }

  /// 响应式监听已完成且未归档的任务
  Stream<List<ExportTask>> watchCompletedTasks() {
    return (select(exportTasks)
      ..where((t) =>
          t.status.equals('DONE') & t.archivedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
    ).watch();
  }

  /// 获取已归档的任务
  Future<List<ExportTask>> getArchivedTasks() async {
    return await (select(exportTasks)
      ..where((t) =>
          t.status.equals('DONE') & t.archivedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)])
    ).get();
  }

  /// 响应式监听已归档的任务
  Stream<List<ExportTask>> watchArchivedTasks() {
    return (select(exportTasks)
      ..where((t) =>
          t.status.equals('DONE') & t.archivedAt.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.archivedAt)])
    ).watch();
  }

  /// 取消归档任务（清除 archivedAt 时间戳）
  Future<void> unarchiveTask(int id) async {
    await (update(exportTasks)..where((t) => t.id.equals(id)))
        .write(const ExportTasksCompanion(archivedAt: Value(null)));
  }

  /// 获取队列中的任务（pending/preparing/exporting/failed）
  Future<List<ExportTask>> getQueuedTasks() async {
    return await (select(exportTasks)
      ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'EXPORTING', 'FAILED']))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
    ).get();
  }

  /// 响应式监听队列中的任务
  Stream<List<ExportTask>> watchQueuedTasks() {
    return (select(exportTasks)
      ..where((t) => t.status.isIn(['PENDING', 'PREPARING', 'EXPORTING', 'FAILED']))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
    ).watch();
  }

  /// 获取没有关联 ExportTask 的视频 ID 列表（准备列表用）
  Future<List<int>> getUnconfiguredVideoIds() async {
    final allTaskVideoIds = await (select(exportTasks)
      ..orderBy([])
    ).map((t) => t.sourceVideoId).get();
    final uniqueIds = allTaskVideoIds.toSet();

    final allVideos = await getAllVideos();
    return allVideos
        .where((v) => !uniqueIds.contains(v.id))
        .map((v) => v.id)
        .toList();
  }

  /// 归档任务（设置 archivedAt 时间戳）
  Future<void> archiveTask(int id, int archivedAt) async {
    await (update(exportTasks)..where((t) => t.id.equals(id)))
        .write(ExportTasksCompanion(archivedAt: Value(archivedAt)));
  }

  /// 批量更新任务状态、进度、输出路径、完成时间、错误信息
  Future<void> updateTaskFull({
    required int id,
    String? status,
    int? progress,
    String? outputPath,
    int? completedAt,
    String? errorMessage,
  }) async {
    await (update(exportTasks)..where((t) => t.id.equals(id))).write(
      ExportTasksCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        progress: progress != null ? Value(progress) : const Value.absent(),
        outputPath: outputPath != null ? Value(outputPath) : const Value.absent(),
        completedAt: completedAt != null ? Value(completedAt) : const Value.absent(),
        errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
      ),
    );
  }

  // ==================== v3: AudioTasks DAO ====================

  Future<List<AudioTask>> getAllAudioTasks() async {
    return await (select(audioTasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).get();
  }

  Future<AudioTask?> getAudioTaskById(int id) async {
    return await (select(audioTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertAudioTask(AudioTasksCompanion companion) async {
    return await into(audioTasks).insert(companion);
  }

  Future<void> deleteAudioTask(int id) async {
    await (delete(audioTasks)..where((t) => t.id.equals(id))).go();
  }

  /// 批量更新音频任务字段（状态/进度/输出路径/完成时间/错误信息）
  Future<void> updateAudioTaskFull({
    required int id,
    String? status,
    int? progress,
    String? outputPath,
    int? completedAt,
    String? errorMessage,
  }) async {
    await (update(audioTasks)..where((t) => t.id.equals(id))).write(
      AudioTasksCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        progress: progress != null ? Value(progress) : const Value.absent(),
        outputPath: outputPath != null ? Value(outputPath) : const Value.absent(),
        completedAt: completedAt != null ? Value(completedAt) : const Value.absent(),
        errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
      ),
    );
  }

  /// 响应式监听全部音频任务（最近创建的在前）
  Stream<List<AudioTask>> watchAllAudioTasks() {
    return (select(audioTasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).watch();
  }

  // ==================== v2: AppSettings DAO ====================

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> upsertSetting(String key, String value) async {
    await into(appSettings)
        .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
  }

  Future<void> deleteSetting(String key) async {
    await (delete(appSettings)..where((t) => t.key.equals(key))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/cutflow.db');
    return NativeDatabase(file);
  });
}
