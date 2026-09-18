/// 源音轨探测结果
library;

class AudioSourceInfo {
  /// 是否存在音频轨。false 时其余字段无意义。
  final bool hasAudio;

  /// 音轨码率（kbps）。null = 探测不到。
  final int? bitrateKbps;

  /// [bitrateKbps] 是否来自容器总码率（而非音轨自身）。
  ///
  /// 为 true 时该值含视频轨、明显高于音频实际码率，界面必须标注
  /// 「容器总码率，仅供参考」，不可当作音轨码率展示。
  final bool bitrateIsApproximate;

  final String? codec;
  final int? channels;
  final int? sampleRate;

  /// 总时长（毫秒）
  final int durationMs;

  const AudioSourceInfo({
    required this.hasAudio,
    this.bitrateKbps,
    this.bitrateIsApproximate = false,
    this.codec,
    this.channels,
    this.sampleRate,
    this.durationMs = 0,
  });

  /// 无音轨 / 解析失败时的兜底值
  static const AudioSourceInfo noAudio = AudioSourceInfo(hasAudio: false);
}
