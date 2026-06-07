/// FFmpeg命令构建器
/// 迁移自Android原版的FfmpegCommandBuilder.kt
library;

import '../util/logger.dart';

class CropParams {
  final int cropW;
  final int cropH;
  final int offsetX;
  final int offsetY;

  const CropParams({
    required this.cropW,
    required this.cropH,
    required this.offsetX,
    required this.offsetY,
  });

  /// 转换为FFmpeg crop滤镜参数格式: "crop=W:H:X:Y"
  String toFfmpegString() {
    return 'crop=$cropW:$cropH:$offsetX:$offsetY';
  }
}

class FfmpegCommandBuilder {
  /// 计算裁切参数 (完全迁移Android原版算法)
  ///
  /// [sourceW] 源视频宽度
  /// [sourceH] 源视频高度
  /// [targetRatioW] 目标比例宽度
  /// [targetRatioH] 目标比例高度
  static CropParams computeCropParams({
    required int sourceW,
    required int sourceH,
    required int targetRatioW,
    required int targetRatioH,
  }) {
    final sourceRatio = sourceW / sourceH;
    final targetRatio = targetRatioW / targetRatioH;

    int cropW, cropH;

    if (sourceRatio > targetRatio) {
      // 源视频更宽，裁切左右两侧
      cropH = sourceH;
      cropW = (sourceH * targetRatio).round();
    } else {
      // 源视频更高，裁切上下两侧
      cropW = sourceW;
      cropH = (sourceW / targetRatio).round();
    }

    // 确保偶数尺寸 (H.264要求)
    final evenW = cropW & ~1;
    final evenH = cropH & ~1;

    final offsetX = (sourceW - evenW) ~/ 2;
    final offsetY = (sourceH - evenH) ~/ 2;

    final result = CropParams(
      cropW: evenW,
      cropH: evenH,
      offsetX: offsetX,
      offsetY: offsetY,
    );
    log('CmdBuilder').d('Crop params: source=${sourceW}x$sourceH, ratio=$targetRatioW:$targetRatioH -> $evenW x$evenH offset($offsetX,$offsetY)');
    return result;
  }

  /// 格式化时间为FFmpeg时间码格式: HH:MM:SS.mmm
  static String formatForFfmpeg(int milliseconds) {
    final hours = milliseconds ~/ 3600000;
    final minutes = (milliseconds % 3600000) ~/ 60000;
    final seconds = (milliseconds % 60000) ~/ 1000;
    final millis = milliseconds % 1000;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(3, '0')}';
  }

  /// 构建纯裁剪命令 (-c copy快速复制，无需重新编码)
  static List<String> buildTrimOnly({
    required String inputPath,
    required String outputPath,
    required int startMs,
    required int endMs,
  }) {
    final startTime = formatForFfmpeg(startMs);
    final duration = endMs - startMs;
    log('CmdBuilder').d('buildTrimOnly: start=$startTime, duration=${duration}ms, mode=copy');

    return [
      '-y', // 覆盖输出文件
      '-i', inputPath,
      '-ss', startTime,
      '-t', duration.toString(),
      '-c', 'copy', // 快速复制，不重新编码
      '-avoid_negative_ts', 'make_zero',
      outputPath,
    ];
  }

  /// 构建裁剪+裁切命令 (需要重新编码)
  static List<String> buildTrimAndCrop({
    required String inputPath,
    required String outputPath,
    required int startMs,
    required int endMs,
    required CropParams cropParams,
  }) {
    final startTime = formatForFfmpeg(startMs);
    final duration = endMs - startMs;
    log('CmdBuilder').d('buildTrimAndCrop: start=$startTime, duration=${duration}ms, crop=${cropParams.toFfmpegString()}, mode=libx264');

    return [
      '-y',
      '-i', inputPath,
      '-ss', startTime,
      '-t', duration.toString(),
      '-vf', cropParams.toFfmpegString(), // 应用裁切滤镜
      '-c:v', 'libx264', // H.264编码
      '-preset', 'fast',
      '-crf', '23',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-movflags', '+faststart',
      outputPath,
    ];
  }

  /// 构建纯裁切命令 (不裁剪时间，仅裁切画面)
  static List<String> buildCropOnly({
    required String inputPath,
    required String outputPath,
    required CropParams cropParams,
  }) {
    log('CmdBuilder').d('buildCropOnly: crop=${cropParams.toFfmpegString()}, mode=libx264');
    return [
      '-y',
      '-i', inputPath,
      '-vf', cropParams.toFfmpegString(),
      '-c:v', 'libx264',
      '-preset', 'fast',
      '-crf', '23',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-movflags', '+faststart',
      outputPath,
    ];
  }
}
