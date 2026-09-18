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
      '-ss', startTime,
      '-i', inputPath,
      '-t', formatForFfmpeg(duration),
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
      '-ss', startTime,
      '-i', inputPath,
      '-t', formatForFfmpeg(duration),
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

  /// 构建 HVC1 到 H264 的转码命令
  /// 
  /// 纯转码，不裁剪时间，不裁切画面
  /// 使用 H.264 编码，保持原始分辨率和帧率
  static List<String> buildTranscodeH264({
    required String inputPath,
    required String outputPath,
  }) {
    log('CmdBuilder').d('buildTranscodeH264: input=$inputPath, output=$outputPath');
    return [
      '-y',
      '-i', inputPath,
      '-c:v', 'libx264', // H.264 编码
      '-preset', 'fast', // 快速编码
      '-crf', '23', // 质量因子
      '-c:a', 'aac', // 音频编码
      '-b:a', '128k', // 音频比特率
      '-movflags', '+faststart', // 快速启动
      outputPath,
    ];
  }

  /// 规整 ID3 标签值
  ///
  /// 去首尾空格、换行折为空格。返回 null 表示该标签不写入。
  /// 注意：参数经 Process.start 以 argv 传递、不经 shell，
  /// 因此引号/&/| 等字符无需转义，这里只处理 ffmpeg 元数据解析会截断的换行。
  static String? normalizeTagValue(String? raw) {
    if (raw == null) return null;
    final normalized = raw.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
    return normalized.isEmpty ? null : normalized;
  }

  /// 构建「视频 → MP3 + ID3 标签」命令
  ///
  /// [startMs]/[endMs] 为提取区间；[coverPath] 为空则不嵌入封面；
  /// 三个标签为 null/空白时不写入对应 ID3 字段。
  static List<String> buildExtractMp3({
    required String inputPath,
    required String outputPath,
    required int startMs,
    required int endMs,
    required int targetBitrateKbps,
    String? coverPath,
    String? title,
    String? artist,
    String? album,
  }) {
    final startTime = formatForFfmpeg(startMs);
    final duration = endMs - startMs;
    final hasCover = coverPath != null && coverPath.isNotEmpty;

    log('CmdBuilder').d('buildExtractMp3: start=$startTime, '
        'duration=${duration}ms, bitrate=${targetBitrateKbps}k, cover=$hasCover');

    final args = <String>[
      '-y',
      '-ss', startTime, // 输入 seek：放在 -i 之前
      '-i', inputPath,
    ];

    if (hasCover) {
      args.addAll(['-i', coverPath]);
    }

    args.addAll(['-t', formatForFfmpeg(duration)]); // 输出时长限制

    if (hasCover) {
      args.addAll(['-map', '0:a:0', '-map', '1:v:0']);
    }

    args.addAll([
      '-c:a', 'libmp3lame',
      '-b:a', '${targetBitrateKbps}k',
    ]);

    if (hasCover) {
      args.addAll([
        '-c:v', 'mjpeg', // 统一重编码为 JPEG（MP3 APIC 只认 JPEG/PNG）
        '-vf', r'scale=w=min(600\,iw):h=min(600\,ih):force_original_aspect_ratio=decrease', // 最长边 600，不放大
        '-q:v', '3',
        '-disposition:v', 'attached_pic',
      ]);
    }

    args.addAll(['-id3v2_version', '3']); // v2.3：兼容性最优

    final titleValue = normalizeTagValue(title);
    if (titleValue != null) args.addAll(['-metadata', 'title=$titleValue']);

    final artistValue = normalizeTagValue(artist);
    if (artistValue != null) args.addAll(['-metadata', 'artist=$artistValue']);

    final albumValue = normalizeTagValue(album);
    if (albumValue != null) args.addAll(['-metadata', 'album=$albumValue']);

    if (hasCover) {
      args.addAll([
        '-metadata:s:v', 'title=Album cover',
        '-metadata:s:v', 'comment=Cover (front)',
      ]);
    }

    args.add(outputPath);
    return args;
  }
}
