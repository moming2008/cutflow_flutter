/// 转码页面 ViewModel
///
/// 管理 HVC1 到 H264 的转码功能
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../core/ffmpeg/command_builder.dart';
import '../../core/ffmpeg/ffmpeg_engine.dart';
import '../../core/util/logger.dart';

/// 转码状态
class TranscodeState {
  final String? inputPath;
  final String? outputPath;
  final bool isTranscoding;
  final int progress; // 0-100
  final String? error;
  final String? successMessage;

  const TranscodeState({
    this.inputPath,
    this.outputPath,
    this.isTranscoding = false,
    this.progress = 0,
    this.error,
    this.successMessage,
  });

  TranscodeState copyWith({
    String? inputPath,
    String? outputPath,
    bool? isTranscoding,
    int? progress,
    String? error,
    String? successMessage,
  }) {
    return TranscodeState(
      inputPath: inputPath ?? this.inputPath,
      outputPath: outputPath ?? this.outputPath,
      isTranscoding: isTranscoding ?? this.isTranscoding,
      progress: progress ?? this.progress,
      error: error,
      successMessage: successMessage,
    );
  }
}

/// 转码 ViewModel
class TranscodeViewModel extends StateNotifier<TranscodeState> {
  FfmpegEngine? _currentEngine;

  TranscodeViewModel() : super(const TranscodeState());

  /// 设置输入文件路径
  void setInputPath(String path) {
    final dir = p.dirname(path);
    final name = p.basenameWithoutExtension(path);
    final ext = p.extension(path);
    final defaultOutput = p.join(dir, '$name-h264$ext');

    state = state.copyWith(
      inputPath: path,
      outputPath: defaultOutput,
      error: null,
      successMessage: null,
    );
    log('TranscodeViewModel').i('Input path set: $path');
  }

  /// 设置输出文件路径
  void setOutputPath(String path) {
    state = state.copyWith(
      outputPath: path,
      error: null,
      successMessage: null,
    );
    log('TranscodeViewModel').i('Output path set: $path');
  }

  /// 开始转码
  Future<void> startTranscode() async {
    if (state.inputPath == null) {
      state = state.copyWith(error: '请先选择要转码的视频文件');
      return;
    }

    if (state.outputPath == null) {
      state = state.copyWith(error: '请设置保存路径');
      return;
    }

    final inputFile = File(state.inputPath!);
    if (!await inputFile.exists()) {
      state = state.copyWith(error: '输入文件不存在');
      return;
    }

    state = state.copyWith(
      isTranscoding: true,
      progress: 0,
      error: null,
      successMessage: null,
    );

    try {
      final outputPath = state.outputPath!;

      // 确保输出目录存在
      final outputDir = Directory(p.dirname(outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      // 构建 FFmpeg 命令
      final command = FfmpegCommandBuilder.buildTranscodeH264(
        inputPath: state.inputPath!,
        outputPath: outputPath,
      );

      log('TranscodeViewModel').i('Starting transcode: ${state.inputPath} -> $outputPath');

      // 获取视频时长用于进度计算
      final durationMs = await _getVideoDuration(state.inputPath!);

      // 执行转码
      final engine = FfmpegEngine();
      _currentEngine = engine;

      await for (final progress in engine.executeWithProgress(
        command: command,
        totalDurationMs: durationMs,
      )) {
        if (progress.hasError) {
          state = state.copyWith(
            isTranscoding: false,
            error: '转码失败: ${progress.error}',
          );
          _currentEngine = null;
          return;
        }

        state = state.copyWith(progress: progress.progress);
      }

      _currentEngine = null;

      state = state.copyWith(
        isTranscoding: false,
        progress: 100,
        successMessage: '转码完成: $outputPath',
      );

      log('TranscodeViewModel').i('Transcode completed: $outputPath');
    } catch (e) {
      state = state.copyWith(
        isTranscoding: false,
        error: '转码失败: $e',
      );
      log('TranscodeViewModel').e('Transcode failed', error: e);
      _currentEngine = null;
    }
  }

  /// 取消转码
  Future<void> cancelTranscode() async {
    if (_currentEngine != null) {
      await _currentEngine!.cancel();
      _currentEngine = null;
      state = state.copyWith(
        isTranscoding: false,
        progress: 0,
        error: '转码已取消',
      );
    }
  }

  /// 获取视频时长
  Future<int> _getVideoDuration(String path) async {
    try {
      final result = await Process.run(
        'ffprobe',
        [
          '-v', 'error',
          '-show_entries', 'format=duration',
          '-of', 'default=noprint_wrappers=1:nokey=1',
          path,
        ],
      );
      if (result.exitCode == 0) {
        final seconds = double.tryParse(result.stdout.toString().trim()) ?? 0;
        return (seconds * 1000).round();
      }
    } catch (e) {
      log('TranscodeViewModel').e('Failed to get video duration', error: e);
    }
    return 0;
  }

  /// 清除错误信息
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 清除成功信息
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }
}

/// 转码 ViewModel Provider
final transcodeProvider = StateNotifierProvider<TranscodeViewModel, TranscodeState>((ref) {
  return TranscodeViewModel();
});
