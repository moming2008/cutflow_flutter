/// 准备列表 ViewModel
///
/// 管理未配置 ExportTask 的视频列表（准备列表），
/// 以及哪些视频有 EditorDraft 草稿。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/video_item.dart';
import '../../core/repository/video_repository.dart';
import '../../core/repository/editor_draft_repository.dart';
import '../../core/ffmpeg/metadata_extractor.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

final preparationProvider =
    StateNotifierProvider<PreparationViewModel, PreparationState>(
  (ref) => PreparationViewModel(
    VideoRepository(database),
    EditorDraftRepository(database),
  ),
);

class PreparationState {
  final List<VideoItem> videos;
  final Set<int> draftVideoIds;
  final bool isLoading;
  final String? error;

  const PreparationState({
    this.videos = const [],
    this.draftVideoIds = const {},
    this.isLoading = false,
    this.error,
  });

  PreparationState copyWith({
    List<VideoItem>? videos,
    Set<int>? draftVideoIds,
    bool? isLoading,
    String? error,
  }) {
    return PreparationState(
      videos: videos ?? this.videos,
      draftVideoIds: draftVideoIds ?? this.draftVideoIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PreparationViewModel extends StateNotifier<PreparationState> {
  final VideoRepository _videoRepo;
  final EditorDraftRepository _draftRepo;

  PreparationViewModel(this._videoRepo, this._draftRepo)
      : super(const PreparationState());

  /// 加载未配置的视频 + 有草稿的视频 ID 集合
  Future<void> loadVideos() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final videos = await _videoRepo.getUnconfiguredVideos();

      // 获取所有草稿，筛选出在当前视频列表中的
      final allDrafts = await _draftRepo.getAllDrafts();
      final videoIdSet = videos.map((v) => v.id).toSet();
      final draftIds = allDrafts
          .where((d) => videoIdSet.contains(d.sourceVideoId))
          .map((d) => d.sourceVideoId)
          .toSet();

      state = state.copyWith(
        videos: videos,
        draftVideoIds: draftIds,
        isLoading: false,
      );
      log('Preparation').i('Loaded ${videos.length} videos, ${draftIds.length} with drafts');
    } catch (e) {
      log('Preparation').e('Failed to load videos', error: e);
      state = state.copyWith(
        isLoading: false,
        error: '加载视频失败: $e',
      );
    }
  }

  /// 导入视频文件
  Future<bool> importVideo(String filePath) async {
    log('Preparation').i('Importing video: $filePath');
    try {
      final metadata = await MetadataExtractor.extractMetadata(filePath);
      if (metadata == null) {
        log('Preparation').e('Failed to extract metadata: $filePath');
        state = state.copyWith(error: '无法提取视频元数据');
        return false;
      }

      final video = VideoItem(
        id: 0,
        path: metadata.path,
        name: metadata.name,
        duration: metadata.duration,
        width: metadata.width,
        height: metadata.height,
        fileSize: metadata.fileSize,
        frameRate: metadata.frameRate,
        codec: metadata.codec,
        importedAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _videoRepo.insertVideo(video);
      log('Preparation').i('Video imported: ${video.name} (id=${video.id})');
      await loadVideos();
      return true;
    } catch (e) {
      log('Preparation').e('Import failed', error: e);
      state = state.copyWith(error: '导入视频失败: $e');
      return false;
    }
  }

  /// 删除视频及其关联草稿
  Future<void> deleteVideo(int id) async {
    try {
      // 检查并删除关联草稿
      final draft = await _draftRepo.getDraftByVideoId(id);
      if (draft != null) {
        await _draftRepo.deleteDraft(draft.id);
      }
      await _videoRepo.deleteVideo(id);
      log('Preparation').i('Video deleted id=$id');
      await loadVideos();
    } catch (e) {
      log('Preparation').e('Delete failed id=$id', error: e);
      state = state.copyWith(error: '删除视频失败: $e');
    }
  }
}
