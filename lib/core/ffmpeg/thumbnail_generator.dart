/// 跨平台缩略图生成器
/// Windows: 使用FFmpeg生成缩略图
/// Android: 使用video_thumbnail插件或FFmpeg
library;

import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import '../util/logger.dart';

class ThumbnailGenerator {
  /// 生成视频缩略图
  ///
  /// [videoPath] 视频文件路径
  /// [timeMs] 提取帧的时间点（毫秒）
  /// [width] 输出宽度
  /// [height] 输出高度
  /// [outputPath] 输出文件路径（可选，不提供则返回内存数据）
  static Future<Uint8List?> generateThumbnail({
    required String videoPath,
    int timeMs = 0,
    int width = 240,
    int height = 135,
    String? outputPath,
  }) async {
    try {
      final file = File(videoPath);
      if (!await file.exists()) {
        return null;
      }

      // 格式化时间为HH:MM:SS.mmm
      final hours = timeMs ~/ 3600000;
      final minutes = (timeMs % 3600000) ~/ 60000;
      final seconds = (timeMs % 60000) ~/ 1000;
      final millis = timeMs % 1000;
      final timestamp = '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}.'
          '${millis.toString().padLeft(3, '0')}';

      // 如果没有指定输出路径，使用临时文件
      final tempPath = outputPath ??
          path.join(
            Directory.systemTemp.path,
            'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );

      // 构建FFmpeg命令
      final args = [
        '-y', // 覆盖输出
        '-i', videoPath,
        '-ss', timestamp,
        '-vframes', '1',
        '-vf', 'scale=$width:$height:force_original_aspect_ratio=decrease',
        '-q:v', '2', // 高质量
        tempPath,
      ];

      ProcessResult result;
      if (Platform.isWindows) {
        // Windows: 尝试查找ffmpeg
        final ffmpegPath = await _findFfmpegPath();
        if (ffmpegPath == null) {
          log().w('FFmpeg not found on Windows');
          return null;
        }
        result = await Process.run(ffmpegPath, args);
      } else {
        // Android或其他平台
        result = await Process.run('ffmpeg', args);
      }

      if (result.exitCode != 0) {
        log().e('FFmpeg thumbnail error: ${result.stderr}');
        return null;
      }

      // 读取生成的图片
      final thumbFile = File(tempPath);
      if (await thumbFile.exists()) {
        final data = await thumbFile.readAsBytes();

        // 如果不是临时文件，不删除
        if (outputPath == null) {
          await thumbFile.delete();
        }

        return data;
      }

      return null;
    } catch (e) {
      log().e('Error generating thumbnail: $e');
      return null;
    }
  }

  /// 批量生成多个时间点的缩略图
  static Future<List<Uint8List?>> generateMultipleThumbnails({
    required String videoPath,
    required List<int> timePointsMs,
    int width = 240,
    int height = 135,
  }) async {
    final results = <Uint8List?>[];

    for (final timeMs in timePointsMs) {
      final thumbnail = await generateThumbnail(
        videoPath: videoPath,
        timeMs: timeMs,
        width: width,
        height: height,
      );
      results.add(thumbnail);
    }

    return results;
  }

  /// 查找FFmpeg可执行文件
  static Future<String?> _findFfmpegPath() async {
    if (Platform.isWindows) {
      // 尝试从PATH查找
      try {
        final result = await Process.run('where', ['ffmpeg']);
        if (result.exitCode == 0) {
          final paths = (result.stdout as String).trim().split('\n');
          if (paths.isNotEmpty) {
            return paths.first.trim();
          }
        }
      } catch (_) {}

      // 尝试从当前可执行文件目录查找
      final exeDir = path.dirname(Platform.resolvedExecutable);
      final ffmpegPath = path.join(exeDir, 'ffmpeg.exe');
      if (await File(ffmpegPath).exists()) {
        return ffmpegPath;
      }
    }

    return null;
  }
}
