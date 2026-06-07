/// 视频元数据提取器
/// 使用ffprobe提取视频信息，支持Windows和Android平台
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../util/logger.dart';

class VideoMetadata {
  final String path;
  final String name;
  final int duration; // 毫秒
  final int width;
  final int height;
  final int fileSize;
  final double frameRate;
  final String codec;

  const VideoMetadata({
    required this.path,
    required this.name,
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.frameRate,
    required this.codec,
  });

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'duration': duration,
      'width': width,
      'height': height,
      'fileSize': fileSize,
      'frameRate': frameRate,
      'codec': codec,
    };
  }
}

class MetadataExtractor {
  /// 查找ffprobe可执行文件路径
  /// Windows: 优先从PATH查找，其次从 ffmpeg 同目录查找
  /// Android: 使用bundled FFmpeg
  static Future<String?> _findFfprobePath() async {
    if (Platform.isWindows) {
      // 尝试从PATH查找ffprobe
      try {
        final result = await Process.run('where', ['ffprobe']);
        if (result.exitCode == 0) {
          final paths = (result.stdout as String).trim().split('\n');
          if (paths.isNotEmpty) {
            return paths.first.trim();
          }
        }
      } catch (_) {
        // 忽略错误，尝试其他方法
      }

      // 尝试从当前可执行文件目录查找
      final exeDir = path.dirname(Platform.resolvedExecutable);
      final ffprobePath = path.join(exeDir, 'ffprobe.exe');
      if (await File(ffprobePath).exists()) {
        return ffprobePath;
      }

      // 从 ffmpeg.exe 同目录查找 ffprobe.exe
      try {
        final ffmpegResult = await Process.run('where', ['ffmpeg']);
        if (ffmpegResult.exitCode == 0) {
          final ffmpegPaths = (ffmpegResult.stdout as String).trim().split('\n');
          if (ffmpegPaths.isNotEmpty) {
            final dir = path.dirname(ffmpegPaths.first.trim());
            final siblingFfprobe = path.join(dir, 'ffprobe.exe');
            if (await File(siblingFfprobe).exists()) {
              return siblingFfprobe;
            }
          }
        }
      } catch (_) {}
    } else if (Platform.isAndroid) {
      // Android使用bundled FFmpeg库
      return null;
    }

    return null;
  }

  /// 提取视频元数据
  static Future<VideoMetadata?> extractMetadata(String videoPath) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = path.basename(videoPath);

      // 使用ffprobe提取元数据
      final ffprobePath = await _findFfprobePath();
      if (ffprobePath == null && Platform.isWindows) {
        // Windows下如果没有找到ffprobe，抛出异常提示用户安装
        throw Exception(
          'FFprobe not found. Please install FFmpeg and add it to PATH, '
          'or place ffprobe.exe in the application directory.',
        );
      }

      // 构建ffprobe命令
      final args = [
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        videoPath,
      ];

      final ProcessResult result;
      if (ffprobePath != null) {
        result = await Process.run(ffprobePath, args);
      } else {
        // Android或其他平台，尝试直接使用ffprobe（假设在PATH中）
        result = await Process.run('ffprobe', args);
      }

      if (result.exitCode != 0) {
        final stderr = (result.stderr as String?)?.trim() ?? '';
        final stdout = (result.stdout as String?)?.trim() ?? '';
        log().e('ffprobe error (exit ${result.exitCode}): stderr=$stderr, stdout=$stdout');
        return null;
      }

      final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;

      // 解析视频流信息
      final streams = json['streams'] as List<dynamic>? ?? [];
      Map<String, dynamic>? videoStream;

      for (final stream in streams) {
        final streamMap = stream as Map<String, dynamic>;
        if (streamMap['codec_type'] == 'video') {
          videoStream = streamMap;
          break;
        }
      }

      if (videoStream == null) {
        return null;
      }

      // 提取时长
      int durationMs = 0;
      final format = json['format'] as Map<String, dynamic>?;
      if (format != null && format['duration'] != null) {
        final durationSec = double.tryParse(format['duration'].toString()) ?? 0;
        durationMs = (durationSec * 1000).round();
      }

      // 提取分辨率
      final width = int.tryParse(videoStream['width']?.toString() ?? '0') ?? 0;
      final height = int.tryParse(videoStream['height']?.toString() ?? '0') ?? 0;

      // 提取帧率
      double frameRate = 0;
      final avgFrameRate = videoStream['avg_frame_rate']?.toString() ?? '0/0';
      if (avgFrameRate.contains('/')) {
        final parts = avgFrameRate.split('/');
        final num = double.tryParse(parts[0]) ?? 0;
        final den = double.tryParse(parts[1]) ?? 1;
        if (den > 0) {
          frameRate = num / den;
        }
      }

      // 提取编码器
      final codec = videoStream['codec_name']?.toString() ?? 'unknown';

      return VideoMetadata(
        path: videoPath,
        name: fileName,
        duration: durationMs,
        width: width,
        height: height,
        fileSize: stat.size,
        frameRate: frameRate,
        codec: codec,
      );
    } catch (e) {
      log().e('Error extracting metadata: $e');
      return null;
    }
  }
}
