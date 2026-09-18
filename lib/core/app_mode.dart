/// 应用运行模式开关
///
/// [kAudioOnlyMode] = true 时为「音频版」：侧栏只显示「音频」一个页签，
/// 视频相关页签（裁剪 / H264 转码 / 视频分割 / 设置）全部隐藏。
///
/// 视频侧代码一律保留，不删除、不废弃；改回 false 即完整恢复原版。
library;

const bool kAudioOnlyMode = true;
