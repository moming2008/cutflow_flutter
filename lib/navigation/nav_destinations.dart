/// 导航目标集中定义
///
/// 路由（StatefulShellRoute 的 branches）与侧栏（AppSidebar 的导航项）
/// 共用同一份列表，从结构上消除「两边各自定义、靠数组下标对齐」的耦合。
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/app_mode.dart';
import '../features/audio/audio_screen.dart';
import '../features/clip/clip_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/split/split_screen.dart';
import '../features/transcode/transcode_screen.dart';

/// 单个导航目标
class NavDestination {
  final String label;
  final IconData icon;
  final IconData iconFilled;
  final String path;
  final Widget Function(BuildContext, GoRouterState) builder;

  /// true = 音频版也保留该页签
  final bool audioOnly;

  const NavDestination({
    required this.label,
    required this.icon,
    required this.iconFilled,
    required this.path,
    required this.builder,
    required this.audioOnly,
  });
}

Widget _buildAudio(BuildContext context, GoRouterState state) =>
    const AudioScreen();

Widget _buildClip(BuildContext context, GoRouterState state) =>
    const ClipScreen();

Widget _buildTranscode(BuildContext context, GoRouterState state) =>
    const TranscodeScreen();

Widget _buildSplit(BuildContext context, GoRouterState state) =>
    const SplitScreen();

Widget _buildSettings(BuildContext context, GoRouterState state) =>
    const SettingsScreen();

/// 全量导航目标
///
/// 音频页排在首位，使 `activeDestinations.first.path` 在音频版下为
/// `/audio`、在完整版下为 `/clip`，两种模式共用一个初始路由表达式。
const List<NavDestination> kNavDestinations = <NavDestination>[
  NavDestination(
    label: '音频',
    icon: Icons.music_note_outlined,
    iconFilled: Icons.music_note,
    path: '/audio',
    builder: _buildAudio,
    audioOnly: true,
  ),
  NavDestination(
    label: '裁剪',
    icon: Icons.content_cut_outlined,
    iconFilled: Icons.content_cut,
    path: '/clip',
    builder: _buildClip,
    audioOnly: false,
  ),
  NavDestination(
    label: 'H264 转码',
    icon: Icons.swap_horiz_outlined,
    iconFilled: Icons.swap_horiz,
    path: '/transcode',
    builder: _buildTranscode,
    audioOnly: false,
  ),
  NavDestination(
    label: '视频分割',
    icon: Icons.call_split_outlined,
    iconFilled: Icons.call_split,
    path: '/split',
    builder: _buildSplit,
    audioOnly: false,
  ),
  NavDestination(
    label: '设置',
    icon: Icons.settings_outlined,
    iconFilled: Icons.settings,
    path: '/settings',
    builder: _buildSettings,
    audioOnly: false,
  ),
];

/// 按模式过滤导航目标（显式传参，便于对两种模式都做单测）
///
/// 音频版：只保留 [NavDestination.audioOnly] 的目标，首项即 `/audio`。
///
/// 完整版：返回全量目标，但把音频页挪到末尾，使首项仍为 `/clip` —— 即
/// `destinationsFor(audioOnly: false).first.path` 与改造前的 `initialLocation`
/// 一致。这样切回完整版时视频侧页签的下标与启动页均无回归，
/// `activeDestinations.first.path` 也仍是两种模式通用的初始路由表达式。
List<NavDestination> destinationsFor({required bool audioOnly}) {
  if (audioOnly) {
    return kNavDestinations.where((d) => d.audioOnly).toList();
  }
  return <NavDestination>[
    ...kNavDestinations.where((d) => !d.audioOnly),
    ...kNavDestinations.where((d) => d.audioOnly),
  ];
}

/// 当前模式下的导航目标
List<NavDestination> get activeDestinations =>
    destinationsFor(audioOnly: kAudioOnlyMode);
