/// 编辑器 ViewModel
///
/// 管理编辑器弹窗的状态和业务逻辑：
/// - 视频信息、输出文件名
/// - 裁切预设选择
/// - 剪辑范围 (trimStart/trimEnd)
/// - 草稿自动保存
/// - 验证和提交 (创建 ExportTask)
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/video_item.dart';
import '../../core/model/crop_preset.dart';
import '../../core/model/editor_draft.dart';
import '../../core/model/export_task.dart';
import '../../core/repository/video_repository.dart';
import '../../core/repository/crop_preset_repository.dart';
import '../../core/repository/editor_draft_repository.dart';
import '../../core/repository/export_repository.dart';
import '../../core/services/export_service.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

/// 自定义裁切模式哨兵值
const int kCustomCropSentinel = -1;

final editorProvider =
    StateNotifierProvider.autoDispose
        .family<EditorViewModel, EditorState, int>(
  (ref, videoId) => EditorViewModel(
    videoId: videoId,
    videoRepo: VideoRepository(database),
    presetRepo: CropPresetRepository(database),
    draftRepo: EditorDraftRepository(database),
    exportRepo: ExportRepository(database),
  ),
);

class EditorState {
  final VideoItem? video;
  final String outputName;
  final int? selectedCropPresetId; // null=原始, -1=自定义
  final int trimStartMs;
  final int trimEndMs;
  final int currentPositionMs;
  final int customCropW;
  final int customCropH;
  final int customCropX;
  final int customCropY;
  final List<CropPreset> presets;
  final Map<String, String> errors;
  final bool isSubmitting;
  final bool isInitialized;

  const EditorState({
    this.video,
    this.outputName = '',
    this.selectedCropPresetId,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.currentPositionMs = 0,
    this.customCropW = 0,
    this.customCropH = 0,
    this.customCropX = 0,
    this.customCropY = 0,
    this.presets = const [],
    this.errors = const {},
    this.isSubmitting = false,
    this.isInitialized = false,
  });

  /// 视频总时长
  int get durationMs => video?.duration ?? 0;

  /// 剪辑时长
  int get trimDurationMs {
    if (trimEndMs > trimStartMs) {
      return trimEndMs - trimStartMs;
    }
    return 0;
  }

  EditorState copyWith({
    VideoItem? video,
    String? outputName,
    int? selectedCropPresetId,
    int? trimStartMs,
    int? trimEndMs,
    int? currentPositionMs,
    int? customCropW,
    int? customCropH,
    int? customCropX,
    int? customCropY,
    List<CropPreset>? presets,
    Map<String, String>? errors,
    bool? isSubmitting,
    bool? isInitialized,
    bool clearCropPreset = false,
    bool clearErrors = false,
  }) {
    return EditorState(
      video: video ?? this.video,
      outputName: outputName ?? this.outputName,
      selectedCropPresetId: clearCropPreset
          ? null
          : (selectedCropPresetId ?? this.selectedCropPresetId),
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      customCropW: customCropW ?? this.customCropW,
      customCropH: customCropH ?? this.customCropH,
      customCropX: customCropX ?? this.customCropX,
      customCropY: customCropY ?? this.customCropY,
      presets: presets ?? this.presets,
      errors: clearErrors ? {} : (errors ?? this.errors),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class EditorViewModel extends StateNotifier<EditorState> {
  final int _videoId;
  final VideoRepository _videoRepo;
  final CropPresetRepository _presetRepo;
  final EditorDraftRepository _draftRepo;
  final ExportRepository _exportRepo;

  Timer? _debounceTimer;

  EditorViewModel({
    required int videoId,
    required VideoRepository videoRepo,
    required CropPresetRepository presetRepo,
    required EditorDraftRepository draftRepo,
    required ExportRepository exportRepo,
  })  : _videoId = videoId,
        _videoRepo = videoRepo,
        _presetRepo = presetRepo,
        _draftRepo = draftRepo,
        _exportRepo = exportRepo,
        super(const EditorState());

  /// 初始化: 加载视频、预设、已有草稿
  Future<void> initialize() async {
    log('Editor').i('Initializing editor for videoId=$_videoId');
    try {
      final video = await _videoRepo.getVideoById(_videoId);
      if (video == null) {
        state = state.copyWith(errors: {'general': '视频不存在'});
        return;
      }

      final presets = await _presetRepo.getAllPresets();

      // 检查是否有已有草稿
      final draft = await _draftRepo.getDraftByVideoId(_videoId);

      // 从文件名去掉扩展名作为默认输出名
      final nameWithoutExt = video.name.replaceAll(
        RegExp(r'\.[^.]+$'),
        '',
      );

      state = state.copyWith(
        video: video,
        outputName: draft?.outputName ?? nameWithoutExt,
        selectedCropPresetId: draft?.selectedCropPresetId,
        trimStartMs: draft?.trimStartMs ?? 0,
        trimEndMs: draft?.trimEndMs ?? video.duration,
        presets: presets,
        isInitialized: true,
        clearErrors: true,
      );
      log('Editor').i('Editor ready: ${video.name}, draft=${draft != null}, presets=${presets.length}');
    } catch (e) {
      log('Editor').e('Init failed', error: e);
      state = state.copyWith(errors: {'general': '初始化失败: $e'});
    }
  }

  /// 设置输出文件名
  void setOutputName(String name) {
    state = state.copyWith(outputName: name, clearErrors: true);
    _autoSaveDraft();
  }

  /// 选择裁切预设
  void setSelectedCropPreset(int? presetId) {
    if (presetId == null) {
      state = state.copyWith(clearCropPreset: true, clearErrors: true);
    } else {
      state = state.copyWith(
        selectedCropPresetId: presetId,
        clearErrors: true,
      );
    }
    _autoSaveDraft();
  }

  /// 设置裁切模式 (null=原始, -1=自定义)
  void setCropMode(int? mode) {
    state = state.copyWith(
      selectedCropPresetId: mode,
      clearErrors: true,
    );
    _autoSaveDraft();
  }

  /// 设置自定义裁切参数
  void setCustomCrop({int? w, int? h, int? x, int? y}) {
    state = state.copyWith(
      customCropW: w ?? state.customCropW,
      customCropH: h ?? state.customCropH,
      customCropX: x ?? state.customCropX,
      customCropY: y ?? state.customCropY,
      clearErrors: true,
    );
    _autoSaveDraft();
  }

  /// 更新播放器当前位置（由对话框同步调用）
  void updateCurrentPosition(int ms) {
    state = state.copyWith(currentPositionMs: ms);
  }

  /// 设定剪辑起点（使用当前播放位置）
  void setTrimStart() {
    final clamped = state.currentPositionMs.clamp(0, state.durationMs);
    state = state.copyWith(trimStartMs: clamped, clearErrors: true);
    _autoSaveDraft();
  }

  /// 设定剪辑终点（使用当前播放位置）
  void setTrimEnd() {
    final clamped = state.currentPositionMs.clamp(0, state.durationMs);
    state = state.copyWith(trimEndMs: clamped, clearErrors: true);
    _autoSaveDraft();
  }

  /// 手动输入剪辑起点
  void setTrimStartManual(int ms) {
    final clamped = ms.clamp(0, state.durationMs);
    state = state.copyWith(trimStartMs: clamped, clearErrors: true);
    _autoSaveDraft();
  }

  /// 手动输入剪辑终点
  void setTrimEndManual(int ms) {
    final clamped = ms.clamp(0, state.durationMs);
    state = state.copyWith(trimEndMs: clamped, clearErrors: true);
    _autoSaveDraft();
  }

  /// 防抖 500ms 自动保存草稿
  void _autoSaveDraft() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }

  /// 保存草稿到数据库
  Future<void> _saveDraft() async {
    if (!state.isInitialized || state.video == null) return;

    try {
      final draft = EditorDraft(
        id: 0,
        sourceVideoId: _videoId,
        outputName: state.outputName,
        trimStartMs: state.trimStartMs,
        trimEndMs: state.trimEndMs,
        selectedCropPresetId: state.selectedCropPresetId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _draftRepo.upsertDraft(draft);
      log('Editor').d('Draft auto-saved for videoId=$_videoId');
    } catch (e) {
      log('Editor').w('Draft save failed (silent)', error: e);
    }
  }

  /// 验证表单
  bool validate() {
    final errors = <String, String>{};

    if (state.outputName.trim().isEmpty) {
      errors['outputName'] = '请输入输出文件名';
    }

    if (state.trimEndMs <= state.trimStartMs) {
      errors['trim'] = '终点必须大于起点';
    }

    state = state.copyWith(errors: errors, clearErrors: errors.isEmpty);
    return errors.isEmpty;
  }

  /// 提交: 验证 → 创建 ExportTask → 删除草稿 → 返回 true
  Future<bool> submit() async {
    if (!validate()) return false;

    state = state.copyWith(isSubmitting: true);

    try {
      final video = state.video!;

      // 获取选中的预设信息（仅非自定义模式时）
      CropPreset? selectedPreset;
      if (state.selectedCropPresetId != null &&
          state.selectedCropPresetId != kCustomCropSentinel) {
        selectedPreset = state.presets.firstWhere(
          (p) => p.id == state.selectedCropPresetId,
          orElse: () => state.presets.first,
        );
      }

      // 构建裁切信息
      String? cropPresetName;
      String? cropRatioLabel;

      if (state.selectedCropPresetId == kCustomCropSentinel) {
        cropPresetName = '自定义';
        cropRatioLabel = 'custom';
      } else if (selectedPreset != null) {
        cropPresetName = selectedPreset.name;
        cropRatioLabel = selectedPreset.ratioLabel;
      }

      // 构建 cropSnapshot（自定义裁切时存储参数）
      String? cropSnapshot;
      if (state.selectedCropPresetId == kCustomCropSentinel) {
        cropSnapshot =
            '${state.customCropW}x${state.customCropH}+${state.customCropX}+${state.customCropY}';
      }

      // 创建 ExportTask
      final task = ExportTask(
        id: 0,
        sourceVideoId: video.id,
        outputName: state.outputName.trim(),
        trimStartMs: state.trimStartMs,
        trimEndMs: state.trimEndMs,
        cropPresetId: state.selectedCropPresetId == kCustomCropSentinel
            ? null
            : state.selectedCropPresetId,
        cropSnapshot: cropSnapshot,
        cropPresetName: cropPresetName,
        cropRatioLabel: cropRatioLabel,
        sourceVideoName: video.name,
        status: TaskStatus.pending,
        progress: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      await _exportRepo.insertTask(task);

      // 删除草稿
      await _draftRepo.deleteDraftByVideoId(_videoId);

      // 通知队列页面有新任务
      ExportService.notifyTaskInserted();

      log('Editor').i('Task created: "${state.outputName}" (trim=${state.trimStartMs}-${state.trimEndMs}ms, crop=${state.selectedCropPresetId ?? "none"})');
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      log('Editor').e('Submit failed', error: e);
      state = state.copyWith(
        isSubmitting: false,
        errors: {'general': '提交失败: $e'},
      );
      return false;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
