import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../model/video_item.dart';

class VideoRepository {
  final db.AppDatabase _db;

  VideoRepository(this._db);

  /// 获取所有视频(按导入时间倒序)
  Future<List<VideoItem>> getAllVideos() async {
    final rows = await _db.getAllVideos();
    return rows.map(_fromDb).toList();
  }

  /// 根据ID获取视频
  Future<VideoItem?> getVideoById(int id) async {
    final row = await _db.getVideoById(id);
    return row != null ? _fromDb(row) : null;
  }

  /// 插入视频
  Future<int> insertVideo(VideoItem video) async {
    final companion = db.VideoItemsCompanion.insert(
      path: video.path,
      name: video.name,
      duration: video.duration,
      width: video.width,
      height: video.height,
      fileSize: video.fileSize,
      frameRate: video.frameRate,
      codec: video.codec,
      importedAt: video.importedAt,
    );
    return await _db.into(_db.videoItems).insert(companion);
  }

  /// 删除视频
  Future<void> deleteVideo(int id) async {
    await _db.deleteVideo(id);
  }

  /// 更新视频
  Future<void> updateVideo(VideoItem video) async {
    final companion = db.VideoItemsCompanion(
      id: Value(video.id),
      path: Value(video.path),
      name: Value(video.name),
      duration: Value(video.duration),
      width: Value(video.width),
      height: Value(video.height),
      fileSize: Value(video.fileSize),
      frameRate: Value(video.frameRate),
      codec: Value(video.codec),
      importedAt: Value(video.importedAt),
    );
    await _db.updateVideo(companion);
  }

  /// 获取未配置的视频（没有关联 ExportTask 的视频，用于准备列表）
  Future<List<VideoItem>> getUnconfiguredVideos() async {
    final unconfiguredIds = await _db.getUnconfiguredVideoIds();
    if (unconfiguredIds.isEmpty) return [];
    final allVideos = await _db.getAllVideos();
    final idSet = unconfiguredIds.toSet();
    return allVideos.where((v) => idSet.contains(v.id)).map(_fromDb).toList();
  }

  // ==================== Private Helpers ====================

  VideoItem _fromDb(db.VideoItem row) {
    return VideoItem(
      id: row.id,
      path: row.path,
      name: row.name,
      duration: row.duration,
      width: row.width,
      height: row.height,
      fileSize: row.fileSize,
      frameRate: row.frameRate,
      codec: row.codec,
      importedAt: row.importedAt,
    );
  }
}
