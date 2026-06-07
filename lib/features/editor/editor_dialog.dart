/// 编辑器弹窗
///
/// 1:1 左右布局：左侧视频预览 (media_kit)，右侧参数表单。
/// 通过 showDialog() 打开，返回 true 表示已成功加入队列。
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'editor_viewmodel.dart';
import 'widgets/video_preview_panel.dart';
import 'widgets/editor_form_panel.dart';
import 'widgets/crop_panel_dialog.dart';
import '../../ui/theme/colors.dart';

class EditorDialog extends ConsumerStatefulWidget {
  final int videoId;

  const EditorDialog({super.key, required this.videoId});

  /// 便捷方法：以弹窗形式打开编辑器
  static Future<bool> show(BuildContext context, int videoId) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => EditorDialog(videoId: videoId),
    ).then((result) => result ?? false);
  }

  @override
  ConsumerState<EditorDialog> createState() => _EditorDialogState();
}

class _EditorDialogState extends ConsumerState<EditorDialog> {
  final GlobalKey<VideoPreviewPanelState> _previewKey = GlobalKey();
  Timer? _positionThrottle;
  int _lastReportedMs = -1;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(editorProvider(widget.videoId).notifier).initialize();
    });
  }

  @override
  void dispose() {
    _positionThrottle?.cancel();
    super.dispose();
  }

  void _onPositionChanged(int pos) {
    // 节流：每 100ms 更新一次 Riverpod 状态，避免过于频繁
    if (pos == _lastReportedMs) return;
    _lastReportedMs = pos;

    _positionThrottle?.cancel();
    _positionThrottle = Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        ref.read(editorProvider(widget.videoId).notifier).updateCurrentPosition(pos);
      }
    });
  }

  void _onSetTrimStart() {
    // 直接从播放器读取位置，绕过节流
    final pos = _previewKey.currentState?.currentPositionMs ?? 0;
    ref.read(editorProvider(widget.videoId).notifier).updateCurrentPosition(pos);
    ref.read(editorProvider(widget.videoId).notifier).setTrimStart();
  }

  void _onSetTrimEnd() {
    final pos = _previewKey.currentState?.currentPositionMs ?? 0;
    ref.read(editorProvider(widget.videoId).notifier).updateCurrentPosition(pos);
    ref.read(editorProvider(widget.videoId).notifier).setTrimEnd();
  }

  void _onSliderChanged(double value) {
    _previewKey.currentState?.seekTo(value.round());
  }

  void _onStepForward() {
    final video = ref.read(editorProvider(widget.videoId)).video;
    if (video == null) return;
    final pos = _previewKey.currentState?.currentPositionMs ?? 0;
    final frameMs = (1000 / video.frameRate).round();
    _previewKey.currentState?.seekTo(pos + frameMs);
  }

  void _onStepBackward() {
    final video = ref.read(editorProvider(widget.videoId)).video;
    if (video == null) return;
    final pos = _previewKey.currentState?.currentPositionMs ?? 0;
    final frameMs = (1000 / video.frameRate).round();
    _previewKey.currentState?.seekTo((pos - frameMs).clamp(0, video.duration));
  }

  Future<void> _onOpenCropPanel() async {
    final video = ref.read(editorProvider(widget.videoId)).video;
    if (video == null) return;

    final currentPositionMs =
        _previewKey.currentState?.currentPositionMs ?? 0;

    final result = await CropPanelDialog.show(
      context,
      videoPath: video.path,
      currentPositionMs: currentPositionMs,
      videoWidth: video.width,
      videoHeight: video.height,
    );

    if (result != null && mounted) {
      final notifier = ref.read(editorProvider(widget.videoId).notifier);
      // 回填裁切参数
      notifier.setCustomCrop(
        w: result.cropW,
        h: result.cropH,
        x: result.offsetX,
        y: result.offsetY,
      );
      // 保存预设并切换到新预设
      if (result.presetName != null) {
        final newPresetId = await notifier.saveCropPreset(
          result.presetName!,
          result.cropW,
          result.cropH,
          result.offsetX,
          result.offsetY,
        );
        notifier.setCropMode(newPresetId);
      } else {
        // 仅本次 → 停留在自定义模式
        notifier.setCropMode(kCustomCropSentinel);
      }
    }
  }

  Future<void> _onSubmit() async {
    final notifier = ref.read(editorProvider(widget.videoId).notifier);
    final success = await notifier.submit();
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider(widget.videoId));

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: state.isInitialized && state.video != null
            ? _buildContent(state)
            : _buildLoading(state),
      ),
    );
  }

  Widget _buildLoading(EditorState state) {
    if (state.errors['general'] != null) {
      return Center(
        child: Text(
          state.errors['general']!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent(EditorState state) {
    return Row(
      children: [
        // 左侧: 视频预览 (1:1)
        Expanded(
          flex: 5,
          child: VideoPreviewPanel(
            key: _previewKey,
            video: state.video!,
            onPositionChanged: _onPositionChanged,
          ),
        ),

        // 分割线
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppColors.outline,
        ),

        // 右侧: 表单面板 (1:1)
        Expanded(
          flex: 5,
          child: EditorFormPanel(
            outputName: state.outputName,
            outputSuffix: state.outputSuffix,
            onOutputNameChanged: (name) {
              ref
                  .read(editorProvider(widget.videoId).notifier)
                  .setOutputName(name);
            },
            onOutputSuffixChanged: (suffix) {
              ref
                  .read(editorProvider(widget.videoId).notifier)
                  .setOutputSuffix(suffix);
            },
            selectedCropPresetId: state.selectedCropPresetId,
            videoWidth: state.video?.width ?? 0,
            videoHeight: state.video?.height ?? 0,
            onCropModeChanged: (mode) {
              ref
                  .read(editorProvider(widget.videoId).notifier)
                  .setCropMode(mode);
            },
            customCropW: state.customCropW,
            customCropH: state.customCropH,
            customCropX: state.customCropX,
            customCropY: state.customCropY,
            onCustomCropWChanged: (v) => ref
                .read(editorProvider(widget.videoId).notifier)
                .setCustomCrop(w: v),
            onCustomCropHChanged: (v) => ref
                .read(editorProvider(widget.videoId).notifier)
                .setCustomCrop(h: v),
            onCustomCropXChanged: (v) => ref
                .read(editorProvider(widget.videoId).notifier)
                .setCustomCrop(x: v),
            onCustomCropYChanged: (v) => ref
                .read(editorProvider(widget.videoId).notifier)
                .setCustomCrop(y: v),
            cropPresets: state.presets,
            durationMs: state.durationMs,
            trimStartMs: state.trimStartMs,
            trimEndMs: state.trimEndMs,
            currentPositionMs: state.currentPositionMs,
            onSetTrimStart: _onSetTrimStart,
            onSetTrimEnd: _onSetTrimEnd,
            onTrimStartManualChanged: (ms) => ref
                .read(editorProvider(widget.videoId).notifier)
                .setTrimStartManual(ms),
            onTrimEndManualChanged: (ms) => ref
                .read(editorProvider(widget.videoId).notifier)
                .setTrimEndManual(ms),
            onSliderChanged: _onSliderChanged,
            frameRate: state.video?.frameRate ?? 30.0,
            onStepForward: _onStepForward,
            onStepBackward: _onStepBackward,
            errors: state.errors,
            isSubmitting: state.isSubmitting,
            onCancel: () => Navigator.pop(context, false),
            onSubmit: _onSubmit,
            onOpenCropPanel: _onOpenCropPanel,
          ),
        ),
      ],
    );
  }
}
