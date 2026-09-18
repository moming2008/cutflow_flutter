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
  late Player _player;
  late VideoController _videoController;

  /// 是否已创建过 Player（决定 dispose 时是否需要释放）
  bool _playerInitialized = false;

  /// 防止快速切换文件时旧的异步初始化覆盖新的
  int _loadToken = 0;

  bool _isInitialized = false;
  String? _error;
  int _currentPositionMs = 0;

  /// 获取当前播放位置（毫秒）
  int get currentPositionMs => _currentPositionMs;

  /// 外部 seek 到指定毫秒
  ///
  /// 播放器尚未就绪（未创建 / 已释放）时静默忽略：
  /// 音频页的区间滑块可能在探测完成后、播放器初始化前被拖动。
  void seekTo(int ms) {
    if (!_playerInitialized) return;
    _player.seek(Duration(milliseconds: ms));
  }

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(covariant VideoPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换到另一个文件时重建播放器；同路径的不同 VideoItem 实例不触发
    if (oldWidget.video.path != widget.video.path) {
      log('VideoPreview').i(
          'Source changed: ${oldWidget.video.path} -> ${widget.video.path}');
      _initPlayer();
    }
  }

  Future<void> _initPlayer() async {
    final token = ++_loadToken;

    // 释放上一个播放器（切文件时）
    // 注意：先清标记再 await —— Player.dispose() 重复调用会抛 AssertionError，
    // 快速连续切文件时后一次调用不能再次释放同一个实例
    if (_playerInitialized) {
      _playerInitialized = false;
      try {
        await _player.dispose();
      } catch (e) {
        log('VideoPreview').w('Failed to dispose previous player', error: e);
      }
    }
    if (token != _loadToken) return; // 期间又切了文件，本次作废

    _isInitialized = false;
    _error = null;
    _currentPositionMs = 0;

    final file = File(widget.video.path);
    final exists = await file.exists();
    // 等待文件检查期间可能已被 dispose 或又切了文件，
    // 此时继续往下走会创建出无人释放的 Player
    if (!mounted || token != _loadToken) return;

    if (!exists) {
      log('VideoPreview').e('File not found: ${widget.video.path}');
      setState(() => _error = '视频文件不存在: ${widget.video.path}');
      return;
    }

    try {
      _player = Player();
      _playerInitialized = true;
      _videoController = VideoController(_player);

      // 监听播放位置变化
      _player.stream.position.listen((position) {
        if (token != _loadToken) return; // 旧播放器的回调，忽略
        final ms = position.inMilliseconds;
        if (ms != _currentPositionMs) {
          _currentPositionMs = ms;
          widget.onPositionChanged?.call(ms);
        }
      });

      // 监听错误
      _player.stream.error.listen((error) {
        log('VideoPreview').e('Player error: $error');
        if (mounted && token == _loadToken) {
          setState(() => _error = error);
        }
      });

      // 打开视频文件
      await _player.open(Media(widget.video.path));
      if (token != _loadToken) return; // 打开期间又切了文件，本次作废
      // 打开后暂停，不自动播放
      await _player.pause();
      log('VideoPreview').i('Video opened: ${widget.video.name}');

      if (mounted && token == _loadToken) {
        setState(() => _isInitialized = true);
      }
    } catch (e, stack) {
      log('VideoPreview').e('Failed to initialize player', error: e, stackTrace: stack);
      if (mounted && token == _loadToken) {
        setState(() => _error = '播放器初始化失败: $e');
      }
    }
  }

  @override
  void dispose() {
    _loadToken++; // 让在途的初始化作废，避免 dispose 后再 setState
    if (_playerInitialized) {
      _player.dispose();
    }
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
                  TimeFormatter.formatDurationPrecise(_currentPositionMs),
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
                  TimeFormatter.formatDurationPrecise(widget.video.duration),
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
