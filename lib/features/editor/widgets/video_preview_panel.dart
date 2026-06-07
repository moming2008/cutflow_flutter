/// 视频预览面板
///
/// 左侧面板，使用 media_kit 播放器和当前时间显示。
/// 暴露当前播放位置回调和 seek 方法。
library;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../core/model/video_item.dart';
import '../../../core/util/logger.dart';
import '../../../core/util/time_formatter.dart';

class VideoPreviewPanel extends StatefulWidget {
  final VideoItem video;
  final ValueChanged<int>? onPositionChanged;

  const VideoPreviewPanel({
    super.key,
    required this.video,
    this.onPositionChanged,
  });

  @override
  State<VideoPreviewPanel> createState() => VideoPreviewPanelState();
}

class VideoPreviewPanelState extends State<VideoPreviewPanel> {
  late final Player _player;
  late final VideoController _videoController;
  bool _isInitialized = false;
  String? _error;
  int _currentPositionMs = 0;

  /// 获取当前播放位置（毫秒）
  int get currentPositionMs => _currentPositionMs;

  /// 外部 seek 到指定毫秒
  void seekTo(int ms) {
    _player.seek(Duration(milliseconds: ms));
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final file = File(widget.video.path);
    if (!await file.exists()) {
      setState(() => _error = '视频文件不存在: ${widget.video.path}');
      log('VideoPreview').e('File not found: ${widget.video.path}');
      return;
    }

    try {
      _player = Player();
      _videoController = VideoController(_player);

      // 监听播放位置变化
      _player.stream.position.listen((position) {
        final ms = position.inMilliseconds;
        if (ms != _currentPositionMs) {
          _currentPositionMs = ms;
          widget.onPositionChanged?.call(ms);
        }
      });

      // 监听错误
      _player.stream.error.listen((error) {
        log('VideoPreview').e('Player error: $error');
        if (mounted) {
          setState(() => _error = error);
        }
      });

      // 打开视频文件
      await _player.open(Media(widget.video.path));
      log('VideoPreview').i('Video opened: ${widget.video.name}');

      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e, stack) {
      log('VideoPreview').e('Failed to initialize player', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _error = '播放器初始化失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // 视频播放区
          Expanded(
            child: _error != null
                ? _buildError()
                : _isInitialized
                    ? Video(controller: _videoController)
                    : const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
          ),
          // 时间显示
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: const Color(0xFF1A1A1A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TimeFormatter.formatDuration(_currentPositionMs),
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: Colors.white70,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(color: Colors.white30, fontSize: 13),
                ),
                Text(
                  TimeFormatter.formatDuration(widget.video.duration),
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.white38,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
