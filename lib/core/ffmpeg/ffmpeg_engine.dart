/// FFmpeg执行引擎
/// 使用Dart Isolate实现后台异步执行，支持进度回调和取消操作
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../util/logger.dart';

class FfmpegProgress {
  final int progress; // 0-100
  final double speed; // 处理速度倍率
  final int timeMs; // 当前处理时间点（毫秒）
  final String? error;

  const FfmpegProgress({
    required this.progress,
    this.speed = 0.0,
    this.timeMs = 0,
    this.error,
  });

  bool get hasError => error != null;
}

class FfmpegEngine {
  Process? _process;
  bool _isCancelled = false;

  /// 执行FFmpeg命令并监听进度
  ///
  /// [command] FFmpeg命令参数列表（不包含ffmpeg可执行文件名）
  /// [totalDurationMs] 视频总时长（毫秒），用于计算进度百分比
  Stream<FfmpegProgress> executeWithProgress({
    required List<String> command,
    required int totalDurationMs,
  }) async* {
    _isCancelled = false;

    try {
      // 查找FFmpeg可执行文件
      final ffmpegPath = await _findFfmpegPath();
      if (ffmpegPath == null) {
        log('Ffmpeg').e('FFmpeg executable not found');
        yield const FfmpegProgress(
          progress: 0,
          error: 'FFmpeg not found',
        );
        return;
      }

      log('Ffmpeg').d('Executing: $ffmpegPath ${command.join(" ")}');

      // 启动进程
      _process = await Process.start(ffmpegPath, command);
      log('Ffmpeg').i('Process started (pid=${_process!.pid})');

      // 监听stderr输出以获取进度信息
      final stderrLines = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      int currentTimeMs = 0;
      double speed = 0.0;

      await for (final line in stderrLines) {
        if (_isCancelled) {
          log('Ffmpeg').i('Process cancelled by user');
          _process?.kill();
          yield const FfmpegProgress(
            progress: 0,
            error: 'Cancelled by user',
          );
          return;
        }

        // 解析FFmpeg输出中的时间信息
        final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+)\.(\d+)').firstMatch(line);
        if (timeMatch != null && totalDurationMs > 0) {
          final hours = int.parse(timeMatch.group(1)!);
          final minutes = int.parse(timeMatch.group(2)!);
          final seconds = int.parse(timeMatch.group(3)!);
          final millis = int.parse(timeMatch.group(4)!.padRight(3, '0').substring(0, 3));

          currentTimeMs = hours * 3600000 + minutes * 60000 + seconds * 1000 + millis;

          // 计算进度百分比
          final progress = ((currentTimeMs / totalDurationMs) * 100).clamp(0, 99).toInt();

          // 解析速度
          final speedMatch = RegExp(r'speed=\s*([\d.]+)x').firstMatch(line);
          if (speedMatch != null) {
            speed = double.tryParse(speedMatch.group(1)!) ?? 0.0;
          }

          yield FfmpegProgress(
            progress: progress,
            speed: speed,
            timeMs: currentTimeMs,
          );
        }
      }

      // 等待进程结束
      final exitCode = await _process!.exitCode;
      _process = null;

      if (_isCancelled) {
        log('Ffmpeg').i('Process was cancelled, exit ignored');
        yield const FfmpegProgress(
          progress: 0,
          error: 'Cancelled by user',
        );
        return;
      }

      if (exitCode == 0) {
        log('Ffmpeg').i('Process completed successfully');
        yield const FfmpegProgress(progress: 100);
      } else {
        log('Ffmpeg').e('Process exited with code $exitCode');
        yield FfmpegProgress(
          progress: 0,
          error: 'FFmpeg exited with code $exitCode',
        );
      }
    } catch (e) {
      log('Ffmpeg').e('Execution error', error: e);
      _process = null;
      yield FfmpegProgress(
        progress: 0,
        error: 'Execution error: $e',
      );
    }
  }

  /// 取消正在执行的FFmpeg命令
  Future<void> cancel() async {
    log('Ffmpeg').i('Cancelling FFmpeg process');
    _isCancelled = true;
    _process?.kill();
    _process = null;
  }

  /// 查找FFmpeg可执行文件路径
  Future<String?> _findFfmpegPath() async {
    if (Platform.isWindows) {
      // 尝试从PATH查找
      try {
        final result = await Process.run('where', ['ffmpeg']);
        if (result.exitCode == 0) {
          final paths = (result.stdout as String).trim().split('\n');
          if (paths.isNotEmpty) {
            log('Ffmpeg').d('Found ffmpeg in PATH: ${paths.first.trim()}');
            return paths.first.trim();
          }
        }
      } catch (_) {}

      // 尝试从当前可执行文件目录查找
      final exeDir = path.dirname(Platform.resolvedExecutable);
      final ffmpegPath = path.join(exeDir, 'ffmpeg.exe');
      if (await File(ffmpegPath).exists()) {
        log('Ffmpeg').d('Found ffmpeg in exe dir: $ffmpegPath');
        return ffmpegPath;
      }

      // 尝试从工作目录查找
      final workDirFfmpeg = path.join(Directory.current.path, 'ffmpeg.exe');
      if (await File(workDirFfmpeg).exists()) {
        log('Ffmpeg').d('Found ffmpeg in work dir: $workDirFfmpeg');
        return workDirFfmpeg;
      }
    } else if (Platform.isAndroid) {
      // Android平台：假设ffmpeg在PATH中或由系统提供
      return 'ffmpeg';
    }

    log('Ffmpeg').w('FFmpeg executable not found in any searched location');
    return null;
  }

  /// 释放资源
  void dispose() {
    cancel();
  }
}
