/// 可视化裁切面板弹窗
library;

import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/ffmpeg/thumbnail_generator.dart';
import '../../../ui/theme/colors.dart';
import 'crop_canvas.dart';
import 'crop_info_panel.dart';

/// 裁切面板返回结果
class CropResult {
  final int cropW;
  final int cropH;
  final int offsetX;
  final int offsetY;
  final String? presetName;

  const CropResult({
    required this.cropW,
    required this.cropH,
    required this.offsetX,
    required this.offsetY,
    this.presetName,
  });
}

class CropPanelDialog extends StatefulWidget {
  final String videoPath;
  final int currentPositionMs;
  final int videoWidth;
  final int videoHeight;

  const CropPanelDialog({
    super.key,
    required this.videoPath,
    required this.currentPositionMs,
    required this.videoWidth,
    required this.videoHeight,
  });

  static Future<CropResult?> show(
    BuildContext context, {
    required String videoPath,
    required int currentPositionMs,
    required int videoWidth,
    required int videoHeight,
  }) {
    return showDialog<CropResult>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => CropPanelDialog(
        videoPath: videoPath,
        currentPositionMs: currentPositionMs,
        videoWidth: videoWidth,
        videoHeight: videoHeight,
      ),
    );
  }

  @override
  State<CropPanelDialog> createState() => _CropPanelDialogState();
}

class _CropPanelDialogState extends State<CropPanelDialog> {
  String? _framePath;
  bool _isLoading = true;
  String? _error;
  CropGuides? _currentGuides;
  final GlobalKey<CropCanvasState> _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _extractFrame();
  }

  @override
  void dispose() {
    if (_framePath != null) {
      final file = File(_framePath!);
      if (file.existsSync()) file.deleteSync();
    }
    super.dispose();
  }

  Future<void> _extractFrame() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final path = await ThumbnailGenerator.extractFullFrame(
      videoPath: widget.videoPath,
      timeMs: widget.currentPositionMs,
    );

    if (!mounted) return;

    if (path != null) {
      setState(() {
        _framePath = path;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = '帧提取失败，请确认 FFmpeg 已安装';
        _isLoading = false;
      });
    }
  }

  void _onGuidesChanged(CropGuides guides) {
    setState(() => _currentGuides = guides);
  }

  void _applyOnce() {
    final guides = _canvasKey.currentState?.currentGuides;
    if (guides == null) return;

    Navigator.pop(
      context,
      CropResult(
        cropW: guides.cropW,
        cropH: guides.cropH,
        offsetX: guides.offsetX,
        offsetY: guides.offsetY,
      ),
    );
  }

  Future<void> _applyAndSavePreset() async {
    final guides = _canvasKey.currentState?.currentGuides;
    if (guides == null) return;

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => const _PresetNameDialog(),
    );

    if (!mounted || name == null || name.isEmpty) return;

    Navigator.pop(
      context,
      CropResult(
        cropW: guides.cropW,
        cropH: guides.cropH,
        offsetX: guides.offsetX,
        offsetY: guides.offsetY,
        presetName: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: screenSize.width * 0.85,
        height: screenSize.height * 0.85,
        child: _isLoading
            ? _buildLoading()
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            '正在截取视频帧...',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            _error!,
            style: const TextStyle(fontSize: 13, color: AppColors.error),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _extractFrame,
                child: const Text('重试'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // 标题栏
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.outline)),
          ),
          child: Row(
            children: [
              const Text(
                '可视化裁切',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),

        // 主内容区
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CropCanvas(
                    key: _canvasKey,
                    framePath: _framePath!,
                    frameWidth: widget.videoWidth,
                    frameHeight: widget.videoHeight,
                    onGuidesChanged: _onGuidesChanged,
                  ),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: AppColors.outline),
              SizedBox(
                width: 260,
                child: CropInfoPanel(
                  sourceWidth: widget.videoWidth,
                  sourceHeight: widget.videoHeight,
                  guides: _currentGuides,
                ),
              ),
            ],
          ),
        ),

        // 底部按钮
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.outline)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _currentGuides != null ? _applyOnce : null,
                child: const Text('仅本次'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _currentGuides != null ? _applyAndSavePreset : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: const Text('应用并保存预设'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetNameDialog extends StatefulWidget {
  const _PresetNameDialog();

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('保存为预设'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: '预设名称',
          hintText: '如: 横屏 1920x1080',
        ),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('保存'),
        ),
      ],
    );
  }
}
