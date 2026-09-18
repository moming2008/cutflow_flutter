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

/// 全量导航目标（顺序即完整版侧栏顺序，音频页排在末尾）
///
/// 音频版下 [destinationsFor] 过滤后只剩音频一项，首项路径为 `/audio`；
/// 完整版下首项为 `/clip`，与改造前的 initialLocation 一致。
/// 两种模式共用 `activeDestinations.first.path` 作为初始路由表达式。
const List<NavDestination> kNavDestinations = <NavDestination>[
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
  NavDestination(
    label: '音频',
    icon: Icons.music_note_outlined,
    iconFilled: Icons.music_note,
    path: '/audio',
    builder: _buildAudio,
    audioOnly: true,
  ),
];

/// 按模式过滤导航目标（显式传参，便于对两种模式都做单测）
///
/// 音频版只保留 [NavDestination.audioOnly] 的目标（首项 `/audio`）；
/// 完整版原样返回 [kNavDestinations]（首项 `/clip`）。
/// 本函数是纯过滤，不改变 [kNavDestinations] 的既有顺序。
List<NavDestination> destinationsFor({required bool audioOnly}) {
  if (!audioOnly) return kNavDestinations;
  return kNavDestinations.where((d) => d.audioOnly).toList();
}

/// 当前模式下的导航目标
List<NavDestination> get activeDestinations =>
    destinationsFor(audioOnly: kAudioOnlyMode);
