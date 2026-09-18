import 'package:cutflow_flutter/features/audio/audio_viewmodel.dart';

/// 可注入初始状态的 AudioViewModel，仅供测试使用
///
/// 生产路径下状态只能由用户操作驱动，而「选文件」必定触发 ffprobe 探测；
/// 测试需要的是「已选好文件、已探测出音轨」这类前置状态，却又不允许真的
/// 启动外部进程。这里只额外打开 `state` 这一条受保护通道，用于铺前置状态，
/// 之后调用的 `startConversion` / `cancelConversion` / `restoreFromTask`
/// 全都是生产实现本身。
class SeedableAudioViewModel extends AudioViewModel {
  SeedableAudioViewModel(super.repository, super.settings);

  void seed(AudioState value) => state = value;
}
