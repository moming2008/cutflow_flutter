/// 源音轨元数据探测
///
/// 使用 ffprobe 读取音轨码率/编码/声道/采样率。
/// 解析逻辑 [parseFfprobeJson] 是纯函数，与进程调用分离以便单测。
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../model/audio_source_info.dart';
import '../util/logger.dart';

class AudioMetadataProbe {
  /// 探测指定文件的音轨信息
  ///
  /// 找不到 ffprobe、进程失败或 JSON 非法时返回 [AudioSourceInfo.noAudio]，
  /// 由调用方决定如何提示。
  static Future<AudioSourceInfo> probe(String filePath) async {
    try {
      final ffprobePath = await _findFfprobePath();
      if (ffprobePath == null) {
        log('AudioProbe').e('ffprobe not found, cannot probe audio info');
        return AudioSourceInfo.noAudio;
      }

      final result = await Process.run(ffprobePath, [
        '-v', 'error',
        '-select_streams', 'a:0',
        '-show_entries', 'stream=bit_rate,codec_name,channels,sample_rate',
        '-show_entries', 'format=duration,bit_rate',
        '-of', 'json',
        filePath,
      ]);

      if (result.exitCode != 0) {
        log('AudioProbe')
            .e('ffprobe exited with ${result.exitCode}: ${result.stderr}');
        return AudioSourceInfo.noAudio;
      }

      final info = parseFfprobeJson(result.stdout.toString());
      log('AudioProbe').i('Probe result: hasAudio=${info.hasAudio}, '
          'bitrate=${info.bitrateKbps}kbps(approx=${info.bitrateIsApproximate}), '
          'codec=${info.codec}, duration=${info.durationMs}ms');
      return info;
    } catch (e) {
      log('AudioProbe').e('Probe failed', error: e);
      return AudioSourceInfo.noAudio;
    }
  }

  /// 解析 ffprobe JSON 输出（纯函数）
  static AudioSourceInfo parseFfprobeJson(String jsonText) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(jsonText) as Map<String, dynamic>;
    } catch (_) {
      return AudioSourceInfo.noAudio;
    }

    final streams = json['streams'] as List<dynamic>? ?? const [];
    Map<String, dynamic>? audioStream;
    for (final stream in streams) {
      final map = stream as Map<String, dynamic>;
      if (map['codec_type'] == 'audio') {
        audioStream = map;
        break;
      }
    }

    final format = json['format'] as Map<String, dynamic>?;
    final durationMs = _parseSecondsToMs(format?['duration']);

    if (audioStream == null) {
      return AudioSourceInfo(hasAudio: false, durationMs: durationMs);
    }

    // 码率回退链：音轨精确码率 → 容器总码率（标记为近似）→ null
    final streamBitrate =
        int.tryParse(audioStream['bit_rate']?.toString() ?? '');
    final formatBitrate = int.tryParse(format?['bit_rate']?.toString() ?? '');

    int? bitrateKbps;
    var approximate = false;
    if (streamBitrate != null && streamBitrate > 0) {
      bitrateKbps = (streamBitrate / 1000).round();
    } else if (formatBitrate != null && formatBitrate > 0) {
      bitrateKbps = (formatBitrate / 1000).round();
      approximate = true;
    }

    return AudioSourceInfo(
      hasAudio: true,
      bitrateKbps: bitrateKbps,
      bitrateIsApproximate: approximate,
      codec: audioStream['codec_name']?.toString(),
      channels: int.tryParse(audioStream['channels']?.toString() ?? ''),
      sampleRate: int.tryParse(audioStream['sample_rate']?.toString() ?? ''),
      durationMs: durationMs,
    );
  }

  static int _parseSecondsToMs(dynamic seconds) {
    if (seconds == null) return 0;
    final value = double.tryParse(seconds.toString());
    if (value == null || value <= 0) return 0;
    return (value * 1000).round();
  }

  /// 查找 ffprobe 可执行文件（与 MetadataExtractor 相同的查找顺序）
  static Future<String?> _findFfprobePath() async {
    if (!Platform.isWindows) return 'ffprobe';

    try {
      final result = await Process.run('where', ['ffprobe']);
      if (result.exitCode == 0) {
        final paths = (result.stdout as String).trim().split('\n');
        if (paths.isNotEmpty && paths.first.trim().isNotEmpty) {
          return paths.first.trim();
        }
      }
    } catch (_) {}

    final exeDir = path.dirname(Platform.resolvedExecutable);
    final sibling = path.join(exeDir, 'ffprobe.exe');
    if (await File(sibling).exists()) return sibling;

    try {
      final ffmpegResult = await Process.run('where', ['ffmpeg']);
      if (ffmpegResult.exitCode == 0) {
        final paths = (ffmpegResult.stdout as String).trim().split('\n');
        if (paths.isNotEmpty && paths.first.trim().isNotEmpty) {
          final near = path.join(
              path.dirname(paths.first.trim()), 'ffprobe.exe');
          if (await File(near).exists()) return near;
        }
      }
    } catch (_) {}

    return null;
  }
}
