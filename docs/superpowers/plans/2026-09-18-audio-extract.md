# 音频提取功能实施计划（视频 → MP3 + ID3 标签）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **⚠️ 本文件是历史产物，不是执行权威。** 执行过程中已发现本计划若干处代码/命令有误
> （内联测试在 fake-async 下不可运行、`await file.exists()` 后的竞态、`Text(widget.x)`
> 编译错误、失效的索引声明、已移除的 build_runner 参数等），每一处均由控制器裁定后
> 修正，全部记录在 `.superpowers/sdd/2026-09-18-audio-extract/progress.md` 的
> `Ruling D*` 条目中。**以该台账与实际代码为准；本文件仅用于理解设计意图。**
> 正文中凡已标注「裁定 D* 取代本节原文」的区块，一律不要照抄。

**Goal:** 在 CutFlow 的 `feature/video-to-mp3` 分支上实现「选定视频区间 → 提取为 MP3 → 封装封面图与歌名/歌手/专辑 ID3 标签」，并以音频版形态（侧栏仅一个页签）交付。

**Architecture:** 沿用项目既有的 MVVM + Riverpod + Drift 分层。新增独立 `features/audio/` 模块与独立 `AudioTasks` 表（与视频侧表完全隔离）；FFmpeg 侧新增 `buildExtractMp3` 命令构建方法，复用现有 `FfmpegEngine` 执行与进度机制；区间选择直接复用编辑器既有的 `TrimRangeControl` 与 `VideoPreviewPanel` 两个纯 UI 组件。视频相关页签通过集中式导航定义 + `kAudioOnlyMode` 开关隐藏，代码一律保留。

**Tech Stack:** Flutter / Dart 3.9 / flutter_riverpod 2.5 / drift 2.16 / go_router 13.2 / media_kit 1.2 / file_picker 9.0 / 系统 ffmpeg + ffprobe

**Spec:** `docs/superpowers/specs/2026-09-18-audio-extract-design.md`

## Global Constraints

- **目标平台**：Windows 桌面为主（`ExplorerService`、`FfmpegEngine._findFfmpegPath` 均为 Windows 优先；Android 分支保留但不作为验收目标）。
- **不新增任何依赖**：仅使用现有 `flutter_riverpod` / `drift` / `go_router` / `media_kit` / `file_picker` / `desktop_drop` / `path` / `equatable` / `uuid` / `logger`。
- **ID3 版本固定为 `-id3v2_version 3`**（v2.3），不可改为 2.4 —— Windows 资源管理器与车机对 v2.4 支持差。
- **封面固定重编码为 JPEG**（`-c:v mjpeg`），最长边限 **600px 且不放大**（`scale=w=min(600\,iw):h=-2`）。
- **数据库 `schemaVersion` 由 2 升至 3**；视频侧五张表（`VideoItems` / `ExportTasks` / `CropPresets` / `EditorDrafts` / `AppSettings`）的**列定义逐字不改**。
- **视频侧代码一律保留**，不删除、不标注 `@Deprecated`；`kAudioOnlyMode` 默认 `true`，改回 `false` 必须完整恢复原版。
- **音频表与视频表物理同库、逻辑隔离**：同一个 `cutflow.db` 文件，独立表 + 独立 Repository。
- **Windows 文件名非法字符为 `\ / : * ? " < > |`**；只清洗文件名，**不清洗 ID3 标签内容**。
- **提交信息使用中文**，与仓库既有风格一致。
- 代码注释与文档使用中文，与仓库既有风格一致。

## 文件结构

| 文件 | 责任 | 动作 |
|---|---|---|
| `lib/core/app_mode.dart` | 音频版/完整版开关常量 | 新建 |
| `lib/navigation/nav_destinations.dart` | 导航目标集中定义（router 与 sidebar 共用） | 新建 |
| `lib/navigation/app_router.dart` | 路由：按模式从集中定义构建 branches | 重写 |
| `lib/navigation/app_sidebar.dart` | 侧栏：按模式从集中定义构建导航项 | 修改 |
| `lib/features/audio/audio_screen.dart` | 音频页（表单区 + 记录列表） | 新建 |
| `lib/features/audio/audio_viewmodel.dart` | 音频页状态与转换编排 | 新建 |
| `lib/features/audio/widgets/audio_tag_panel.dart` | 歌名/歌手/专辑输入 + 封面选择 | 新建 |
| `lib/features/audio/widgets/audio_bitrate_selector.dart` | 源码率展示 + 目标码率选择 | 新建 |
| `lib/features/audio/widgets/audio_record_tile.dart` | 历史记录单行 | 新建 |
| `lib/core/model/audio_task.dart` | 音频任务领域模型 + 状态枚举 | 新建 |
| `lib/core/model/audio_source_info.dart` | 源音轨探测结果 | 新建 |
| `lib/core/database/app_database.dart` | `AudioTasks` 表 + 迁移 v2→v3 + DAO | 修改 |
| `lib/core/repository/audio_repository.dart` | 音频任务仓储（领域模型 ↔ Drift 行映射） | 新建 |
| `lib/core/ffmpeg/audio_metadata_probe.dart` | ffprobe 探测源音轨信息 | 新建 |
| `lib/core/ffmpeg/command_builder.dart` | 新增 `buildExtractMp3` | 修改 |
| `lib/core/util/filename_sanitizer.dart` | 输出文件名清洗 | 新建 |
| `lib/features/editor/widgets/trim_range_control.dart` | 新增两个可选按钮文案参数 | 修改 |

---

### Task 1: 模式开关 + 集中式导航目标 + 音频空壳页

> **注意（2026-09-18 裁定 D7 取代本节原文）**：本节原文的 `kNavDestinations`
> 把「音频」置于首位，与本节自身 test 3 及 spec §6.2 正文（完整版首项须为
> `/clip`）矛盾。实际落地为**单一权威顺序 + 纯过滤**：`kNavDestinations`
> 顺序即完整版侧栏顺序（裁剪/H264 转码/视频分割/设置 占 0–3，音频在末尾），
> `destinationsFor` 完整版直接返回该表、音频版做 `where` 过滤。
> 文中 test 1 的 `kNavDestinations.first.path == '/audio'` 断言亦已改为
> `.last`，同义反复的 `bool.fromEnvironment` 断言已替换为
> `expect(activeDestinations.length, equals(kAudioOnlyMode ? 1 : 5));`。
> 详见 `.superpowers/sdd/2026-09-18-audio-extract/progress.md` 的裁定 D7。

先跑通「启动落在 `/audio`、侧栏只有音频一项、不白屏」，后续任务再往里填功能。

**Files:**
- Create: `lib/core/app_mode.dart`
- Create: `lib/navigation/nav_destinations.dart`
- Create: `lib/features/audio/audio_screen.dart`
- Modify: `lib/navigation/app_router.dart`（整体重写）
- Modify: `lib/navigation/app_sidebar.dart`
- Test: `test/navigation/nav_destinations_test.dart`

**Interfaces:**
- Consumes: 现有 `ClipScreen` / `TranscodeScreen` / `SplitScreen` / `SettingsScreen` 的无参构造函数
- Produces:
  - `const bool kAudioOnlyMode`
  - `class NavDestination { String label; IconData icon; IconData iconFilled; String path; Widget Function(BuildContext, GoRouterState) builder; bool audioOnly; }`
  - `const List<NavDestination> kNavDestinations`
  - `List<NavDestination> destinationsFor({required bool audioOnly})`
  - `List<NavDestination> get activeDestinations`
  - `class AudioScreen extends StatelessWidget`（无参构造）

- [ ] **Step 1: 写失败测试**

创建 `test/navigation/nav_destinations_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/app_mode.dart';
import 'package:cutflow_flutter/navigation/nav_destinations.dart';

void main() {
  group('导航目标过滤', () {
    test('全量列表含 5 个目标，音频排在首位', () {
      expect(kNavDestinations.length, equals(5));
      expect(kNavDestinations.first.path, equals('/audio'));
      expect(kNavDestinations.first.audioOnly, isTrue);
    });

    test('音频版只保留 audioOnly 目标，且首个路径为 /audio', () {
      final result = destinationsFor(audioOnly: true);
      expect(result.length, equals(1));
      expect(result.first.path, equals('/audio'));
      expect(result.first.label, equals('音频'));
    });

    test('完整版保留全部 5 个目标，且首个路径为 /clip', () {
      final result = destinationsFor(audioOnly: false);
      expect(result.length, equals(5));
      expect(result.first.path, equals('/clip'));
    });

    test('所有 path 唯一（避免路由冲突）', () {
      final paths = kNavDestinations.map((d) => d.path).toList();
      expect(paths.toSet().length, equals(paths.length));
    });

    test('activeDestinations 与 kAudioOnlyMode 一致', () {
      expect(activeDestinations.length,
          equals(destinationsFor(audioOnly: const bool.fromEnvironment('x', defaultValue: kAudioOnlyMode)).length));
      expect(activeDestinations.first.path,
          equals(kAudioOnlyMode ? '/audio' : '/clip'));
    });
  });
}
```

> ⚠️ 上列测试 1 的「音频排在首位」与 `first.path == '/audio'` 已被裁定 D7 取代：
> 实际断言改为 `kNavDestinations.last.path == '/audio'`（音频置末）；末行的
> `bool.fromEnvironment` 同义反复断言也一并替换。见本节开头注意事项。

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/navigation/nav_destinations_test.dart`
Expected: 编译失败 —— `Target of URI doesn't exist: 'package:cutflow_flutter/core/app_mode.dart'`

- [ ] **Step 3: 创建模式开关**

创建 `lib/core/app_mode.dart`：

```dart
/// 应用运行模式开关
///
/// [kAudioOnlyMode] = true 时为「音频版」：侧栏只显示「音频」一个页签，
/// 视频相关页签（裁剪 / H264 转码 / 视频分割 / 设置）全部隐藏。
///
/// 视频侧代码一律保留，不删除、不废弃；改回 false 即完整恢复原版。
library;

const bool kAudioOnlyMode = true;
```

- [ ] **Step 4: 创建集中式导航目标定义**

创建 `lib/navigation/nav_destinations.dart`：

```dart
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
List<NavDestination> destinationsFor({required bool audioOnly}) {
  if (!audioOnly) return kNavDestinations;
  return kNavDestinations.where((d) => d.audioOnly).toList();
}

/// 当前模式下的导航目标
List<NavDestination> get activeDestinations =>
    destinationsFor(audioOnly: kAudioOnlyMode);
```

> ⚠️ 本代码块中「音频」置于 `kNavDestinations` **首位**的写法已被裁定 D7 取代：
> 实际实现把「音频」项移到**末位**（视频四项占下标 0–3，与改造前一致），
> `destinationsFor` 恢复为纯过滤、不再重排列表。见本节开头注意事项。

- [ ] **Step 5: 创建音频页空壳**

创建 `lib/features/audio/audio_screen.dart`：

```dart
/// 音频提取页面
///
/// 视频 → MP3，封装封面图与歌名/歌手/专辑 ID3 标签。
library;

import 'package:flutter/material.dart';

import '../../ui/theme/colors.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音频提取',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          '音频提取页面',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 重写路由**

把 `lib/navigation/app_router.dart` 全文替换为：

```dart
/// 应用路由配置
///
/// 路由表由 `nav_destinations.dart` 的 [activeDestinations] 驱动，
/// 与侧栏共用同一份定义，下标天然对齐。
///
/// 初始路由取首个目标的 path：音频版为 `/audio`，完整版为 `/clip`。
library;

import 'package:go_router/go_router.dart';

import 'app_sidebar.dart';
import 'nav_destinations.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: activeDestinations.first.path,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppSidebar(shell: shell),
      branches: [
        for (final destination in activeDestinations)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: destination.path,
                builder: destination.builder,
              ),
            ],
          ),
      ],
    ),
  ],
);
```

- [ ] **Step 7: 改造侧栏读取集中定义**

在 `lib/navigation/app_sidebar.dart` 中：

1. 删除文件顶部的 `_NavItem` 类与 `_navItems` 常量（第 12–46 行），改为 import `nav_destinations.dart`。
2. 文件头注释「包含 4 个导航目标」改为「导航目标由 nav_destinations.dart 集中定义，按当前模式过滤」。
3. `_SidebarContent.build` 中的 `List.generate` 改为读 `activeDestinations`：

```dart
          ...List.generate(activeDestinations.length, (index) {
            final item = activeDestinations[index];
            final isSelected = index == selectedIndex;
            return _SidebarNavItem(
              label: item.label,
              icon: isSelected ? item.iconFilled : item.icon,
              isSelected: isSelected,
              onTap: () => onItemTap(index),
            );
          }),
```

import 段最终为：

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../ui/theme/colors.dart';
import 'nav_destinations.dart';
```

- [ ] **Step 8: 运行测试确认通过**

Run: `flutter test test/navigation/nav_destinations_test.dart`
Expected: PASS，5 个测试全绿

- [ ] **Step 9: 静态分析**

Run: `flutter analyze`
Expected: `No issues found!`（若报未使用的 `_NavItem` 残留则说明 Step 7 未删干净）

- [ ] **Step 10: 手动确认不白屏**

Run: `flutter run -d windows`
Expected: 应用启动进入「音频提取」页面；左侧栏只有「音频」一项；底部版本号正常显示

- [ ] **Step 11: 提交**

```bash
git add lib/core/app_mode.dart lib/navigation/ lib/features/audio/audio_screen.dart test/navigation/
git commit -m "音频版导航骨架：集中式导航目标定义 + 音频页空壳"
```

---

### Task 2: 两个共享组件适配

复用编辑器组件需要两处适配，都不改变现有行为：

1. **`TrimRangeControl`**：音频场景下「逐帧」无意义，需显示为「快退 1s / 快进 1s」。改动为**新增两个带默认值的可选参数**，现有调用方零感知。
2. **`VideoPreviewPanel`**：当前是 `StatefulWidget` 但**未实现 `didUpdateWidget`**，且 `_player` 声明为 `late final` —— 换视频文件时预览不会刷新、`initState` 不会重跑。音频页要反复换文件，必须修。

**Files:**
- Modify: `lib/features/editor/widgets/trim_range_control.dart`
- Modify: `lib/features/editor/widgets/video_preview_panel.dart`
- Test: `test/features/editor/trim_range_control_test.dart`
- Test: `test/features/editor/video_preview_panel_test.dart`

**Interfaces:**
- Produces:
  - `TrimRangeControl` 新增可选具名参数 `String stepBackwardLabel`（默认 `'逐帧向前'`）、`String stepForwardLabel`（默认 `'逐帧向后'`）
  - `VideoPreviewPanel` 保持现有构造签名不变，新增「`video.path` 变化时自动重建播放器」行为；`VideoPreviewPanelState` 的公开成员（`currentPositionMs`、`seekTo`）签名不变

- [ ] **Step 1: 写失败测试**

创建 `test/features/editor/trim_range_control_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/features/editor/widgets/trim_range_control.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

TrimRangeControl _control({
  String stepBackwardLabel = '逐帧向前',
  String stepForwardLabel = '逐帧向后',
}) {
  return TrimRangeControl(
    durationMs: 60000,
    trimStartMs: 0,
    trimEndMs: 60000,
    currentPositionMs: 0,
    onSetStart: () {},
    onSetEnd: () {},
    onTrimStartManualChanged: (_) {},
    onTrimEndManualChanged: (_) {},
    frameRate: 0,
    onStepForward: () {},
    onStepBackward: () {},
    stepBackwardLabel: stepBackwardLabel,
    stepForwardLabel: stepForwardLabel,
  );
}

void main() {
  testWidgets('默认显示逐帧文案（现有调用方行为不变）', (tester) async {
    await tester.pumpWidget(_wrap(_control()));
    expect(find.text('逐帧向前'), findsOneWidget);
    expect(find.text('逐帧向后'), findsOneWidget);
  });

  testWidgets('可自定义步进按钮文案', (tester) async {
    await tester.pumpWidget(_wrap(_control(
      stepBackwardLabel: '快退 1s',
      stepForwardLabel: '快进 1s',
    )));
    expect(find.text('快退 1s'), findsOneWidget);
    expect(find.text('快进 1s'), findsOneWidget);
    expect(find.text('逐帧向前'), findsNothing);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/editor/trim_range_control_test.dart`
Expected: 编译失败 —— `No named parameter with the name 'stepBackwardLabel'`

- [ ] **Step 3: 加参数并替换硬编码文案**

在 `lib/features/editor/widgets/trim_range_control.dart` 中：

1. 字段声明区（`final VoidCallback onStepBackward;` 之后）新增：

```dart
  /// 步退按钮文案（默认「逐帧向前」，音频场景传「快退 1s」）
  final String stepBackwardLabel;

  /// 步进按钮文案（默认「逐帧向后」，音频场景传「快进 1s」）
  final String stepForwardLabel;
```

2. 构造函数中紧跟 `required this.onStepBackward,` 之后新增：

```dart
    this.stepBackwardLabel = '逐帧向前',
    this.stepForwardLabel = '逐帧向后',
```

3. `build` 中两处 `const Text('逐帧向前')` / `const Text('逐帧向后')` 分别替换为：

```dart
                label: Text(widget.stepBackwardLabel),
```

```dart
                label: Text(widget.stepForwardLabel),
```

注意：这两处原本是 `const Text(...)`，改为非 const `Text(...)`（值来自实例字段）。

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/features/editor/trim_range_control_test.dart`
Expected: PASS，2 个测试全绿

- [ ] **Step 5: 写 VideoPreviewPanel 的失败测试**

创建 `test/features/editor/video_preview_panel_test.dart`。

用**不存在的路径**做断言：`_initPlayer` 在文件不存在时会进入 `_error` 分支，这条路径无需真实视频文件即可验证「换文件时确实重新初始化了」。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/model/video_item.dart';
import 'package:cutflow_flutter/features/editor/widgets/video_preview_panel.dart';

VideoItem _video(String path, String name) => VideoItem(
      id: 0,
      path: path,
      name: name,
      duration: 60000,
      width: 1920,
      height: 1080,
      fileSize: 1024,
      frameRate: 30,
      codec: 'h264',
      importedAt: 0,
    );

void main() {
  testWidgets('文件不存在时显示错误', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoPreviewPanel(video: _video('/nope/a.mp4', 'a.mp4'))),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);
  });

  testWidgets('切换 video.path 时重新初始化（错误信息随之更新）', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoPreviewPanel(video: _video('/nope/a.mp4', 'a.mp4'))),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);

    // 换一个文件
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoPreviewPanel(video: _video('/nope/b.mp4', 'b.mp4'))),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('/nope/b.mp4'), findsOneWidget);
    expect(find.textContaining('/nope/a.mp4'), findsNothing);
  });

  testWidgets('同一路径重建不触发重复初始化', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoPreviewPanel(video: _video('/nope/a.mp4', 'a.mp4'))),
    ));
    await tester.pumpAndSettle();

    // 相同 path 但不同 VideoItem 实例 —— 不应重新初始化
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: VideoPreviewPanel(video: _video('/nope/a.mp4', 'a.mp4'))),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);
  });
}
```

- [ ] **Step 6: 运行测试确认失败**

Run: `flutter test test/features/editor/video_preview_panel_test.dart`
Expected: 前两个测试 PASS、第三个（切换路径）**FAIL** —— 当前切路径后仍显示 `/nope/a.mp4`，因为 `didUpdateWidget` 未实现

- [ ] **Step 7: 改造 VideoPreviewPanel**

在 `lib/features/editor/widgets/video_preview_panel.dart` 的 `VideoPreviewPanelState` 中：

1. 字段区由：

```dart
  late final Player _player;
  late final VideoController _videoController;
  bool _isInitialized = false;
  String? _error;
  int _currentPositionMs = 0;
```

改为：

```dart
  late Player _player;
  late VideoController _videoController;

  /// 是否已创建过 Player（决定 dispose 时是否需要释放）
  bool _playerInitialized = false;

  /// 防止快速切换文件时旧的异步初始化覆盖新的
  int _loadToken = 0;

  bool _isInitialized = false;
  String? _error;
  int _currentPositionMs = 0;
```

2. 在 `initState` 之后新增：

```dart
  @override
  void didUpdateWidget(covariant VideoPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换到另一个文件时重建播放器；同路径的不同 VideoItem 实例不触发
    if (oldWidget.video.path != widget.video.path) {
      log('VideoPreview').i(
          'Source changed: ${oldWidget.video.path} -> ${widget.video.path}');
      _initPlayer();
    }
  }
```

3. `_initPlayer` 整体替换为：

```dart
  Future<void> _initPlayer() async {
    final token = ++_loadToken;

    // 释放上一个播放器（切文件时）
    if (_playerInitialized) {
      await _player.dispose();
      _playerInitialized = false;
    }
    if (token != _loadToken) return; // 期间又切了文件，本次作废

    _isInitialized = false;
    _error = null;
    _currentPositionMs = 0;

    final file = File(widget.video.path);
    if (!await file.exists()) {
      log('VideoPreview').e('File not found: ${widget.video.path}');
      if (mounted && token == _loadToken) {
        setState(() => _error = '视频文件不存在: ${widget.video.path}');
      }
      return;
    }

    try {
      _player = Player();
      _playerInitialized = true;
      _videoController = VideoController(_player);

      // 监听播放位置变化
      _player.stream.position.listen((position) {
        final ms = position.inMilliseconds;
        if (ms != _currentPositionMs) {
          _currentPositionMs = ms;
          widget.onPositionChanged?.call(ms);
        }
      });

      // 监听错误
      _player.stream.error.listen((error) {
        log('VideoPreview').e('Player error: $error');
        if (mounted) {
          setState(() => _error = error);
        }
      });

      await _player.open(Media(widget.video.path));
      if (token != _loadToken) return; // 打开期间又切了文件，本次作废
      await _player.pause();
      log('VideoPreview').i('Video opened: ${widget.video.name}');

      if (mounted && token == _loadToken) {
        setState(() => _isInitialized = true);
      }
    } catch (e, stack) {
      log('VideoPreview')
          .e('Failed to initialize player', error: e, stackTrace: stack);
      if (mounted && token == _loadToken) {
        setState(() => _error = '播放器初始化失败: $e');
      }
    }
  }
```

4. `dispose` 由：

```dart
  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
```

改为：

```dart
  @override
  void dispose() {
    _loadToken++; // 让在途的初始化作废，避免 dispose 后再 setState
    if (_playerInitialized) {
      _player.dispose();
    }
    super.dispose();
  }
```

注意：原代码的 `_player.dispose()` 在从未初始化时（文件不存在的分支）会因 `late final` 未赋值而抛 `LateInitializationError` —— 这个改动同时修掉了这个既有隐患。

- [ ] **Step 8: 运行测试确认通过**

Run: `flutter test test/features/editor/`
Expected: PASS，`trim_range_control_test.dart` 与 `video_preview_panel_test.dart` 全绿

- [ ] **Step 9: 回归确认现有调用方未受影响**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`；全量测试 PASS（`editor_form_panel` 等既有调用方未改，默认参数保持原行为）

- [ ] **Step 10: 提交**

```bash
git add lib/features/editor/widgets/trim_range_control.dart lib/features/editor/widgets/video_preview_panel.dart test/features/editor/
git commit -m "共享组件适配：步进按钮文案参数化 + 预览面板支持换文件重载"
```

---

### Task 3: AudioTasks 表 + 数据库迁移 v2→v3

**Files:**
- Modify: `lib/core/database/app_database.dart`
- Regenerate: `lib/core/database/app_database.g.dart`（由 build_runner 生成，不手改）
- Test: `test/core/database/audio_tasks_test.dart`

**Interfaces:**
- Produces（Drift 生成的类型）：
  - 数据类 `AudioTask`（字段与 `AudioTasks` 表一一对应）
  - `AudioTasksCompanion` / `AudioTasksCompanion.insert(...)`
  - `AppDatabase.audioTasks` 表访问器
  - DAO 方法：`getAllAudioTasks()`、`getAudioTaskById(int)`、`insertAudioTask(AudioTasksCompanion)`、`updateAudioTaskFull({...})`、`deleteAudioTask(int)`、`watchAllAudioTasks()`

- [ ] **Step 1: 写失败测试**

创建 `test/core/database/audio_tasks_test.dart`：

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:cutflow_flutter/core/database/app_database.dart';

AudioTasksCompanion _companion({
  String outputName = 'song.mp3',
  String status = 'PENDING',
}) {
  return AudioTasksCompanion.insert(
    sourcePath: '/test/video.mp4',
    sourceName: 'video.mp4',
    sourceDurationMs: 180000,
    trimStartMs: 0,
    trimEndMs: 165000,
    targetBitrateKbps: 320,
    outputName: outputName,
    status: status,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

void main() {
  group('AudioTasks CRUD', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.forTest(NativeDatabase.memory());
    });

    tearDown(() {
      database.close();
    });

    test('插入并读回音频任务', () async {
      final id = await database.insertAudioTask(_companion());
      expect(id, greaterThan(0));

      final task = await database.getAudioTaskById(id);
      expect(task, isNotNull);
      expect(task!.sourcePath, equals('/test/video.mp4'));
      expect(task.trimEndMs, equals(165000));
      expect(task.targetBitrateKbps, equals(320));
      expect(task.status, equals('PENDING'));
      // 可空字段默认空
      expect(task.title, isNull);
      expect(task.coverPath, isNull);
      expect(task.outputPath, isNull);
      expect(task.progress, equals(0));
    });

    test('更新状态、进度与完成信息', () async {
      final id = await database.insertAudioTask(_companion());

      await database.updateAudioTaskFull(
        id: id,
        status: 'EXPORTING',
        progress: 42,
      );
      var task = await database.getAudioTaskById(id);
      expect(task!.status, equals('EXPORTING'));
      expect(task.progress, equals(42));

      await database.updateAudioTaskFull(
        id: id,
        status: 'DONE',
        progress: 100,
        outputPath: '/out/song.mp3',
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      task = await database.getAudioTaskById(id);
      expect(task!.status, equals('DONE'));
      expect(task.outputPath, equals('/out/song.mp3'));
      expect(task.completedAt, isNotNull);
    });

    test('删除音频任务', () async {
      final id = await database.insertAudioTask(_companion());
      await database.deleteAudioTask(id);
      expect(await database.getAudioTaskById(id), isNull);
    });

    test('按创建时间倒序列出全部任务', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      await database.insertAudioTask(
          _companion(outputName: 'old.mp3').copyWith(createdAt: Value(now - 10000)));
      await database.insertAudioTask(
          _companion(outputName: 'new.mp3').copyWith(createdAt: Value(now)));

      final tasks = await database.getAllAudioTasks();
      expect(tasks.length, equals(2));
      expect(tasks.first.outputName, equals('new.mp3'));
    });

    test('watchAllAudioTasks 在插入后推送新值', () async {
      final stream = database.watchAllAudioTasks();
      final first = await stream.first;
      expect(first, isEmpty);

      await database.insertAudioTask(_companion());
      final second = await stream.first;
      expect(second.length, equals(1));
    });
  });

  group('数据库迁移 v2 → v3', () {
    test('新增 audio_tasks 表且视频数据完好', () async {
      final dir = await Directory.systemTemp.createTemp('cutflow_migration');
      final file = File(p.join(dir.path, 'migration.db'));

      try {
        // 1. 建库并写入一条视频数据
        var db = AppDatabase.forTest(NativeDatabase(file));
        final videoId = await db.into(db.videoItems).insert(
              VideoItemsCompanion.insert(
                path: '/test/migration.mp4',
                name: 'migration.mp4',
                duration: 120000,
                width: 1920,
                height: 1080,
                fileSize: 1024 * 1024,
                frameRate: 30.0,
                codec: 'h264',
                importedAt: DateTime.now().millisecondsSinceEpoch,
              ),
            );

        // 2. 把库「降级」成 v2 形态：v2 与 v3 的唯一差别就是没有 audio_tasks 表
        await db.customStatement('DROP TABLE IF EXISTS audio_tasks');
        await db.customStatement('PRAGMA user_version = 2');
        await db.close();

        // 3. 重新打开 —— 触发 onUpgrade(2 → 3)
        db = AppDatabase.forTest(NativeDatabase(file));
        await db.customSelect('SELECT 1').get();

        // 4. audio_tasks 已被迁移重建，可正常写入
        final audioId = await db.insertAudioTask(_companion());
        expect(audioId, greaterThan(0));

        // 5. 旧视频数据完好无损
        final video = await db.getVideoById(videoId);
        expect(video, isNotNull);
        expect(video!.path, equals('/test/migration.mp4'));
        expect(video.width, equals(1920));

        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/core/database/audio_tasks_test.dart`
Expected: 编译失败 —— `The method 'insertAudioTask' isn't defined`

- [ ] **Step 3: 定义 AudioTasks 表**

在 `lib/core/database/app_database.dart` 中，`EditorDrafts` 类之后、`// ==================== Database ====================` 之前插入：

```dart
/// 音频提取任务
///
/// 单表方案：一条记录 = 一次音频转换，输入参数与输出结果同存。
/// 与视频侧表（VideoItems / ExportTasks）结构上完全隔离。
class AudioTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourcePath => text()();
  TextColumn get sourceName => text()();
  IntColumn get sourceDurationMs => integer()();
  IntColumn get sourceBitrateKbps => integer().nullable()(); // null = 探测不到
  IntColumn get trimStartMs => integer()();
  IntColumn get trimEndMs => integer()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get coverPath => text().nullable()();
  IntColumn get targetBitrateKbps => integer()();
  TextColumn get outputName => text()();
  TextColumn get outputPath => text().nullable()();
  TextColumn get status => text()(); // PENDING/EXPORTING/DONE/FAILED
  IntColumn get progress => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get completedAt => integer().nullable()();

  Set<Index> get indexes => {
    Index('idx_audio_tasks_status', 'CREATE INDEX idx_audio_tasks_status ON audio_tasks (status)'),
    Index('idx_audio_tasks_created', 'CREATE INDEX idx_audio_tasks_created ON audio_tasks (createdAt)'),
  };
}
```

> **注意（2026-09-18 裁定 D19 取代上方代码块中的 `indexes` getter）**：上面这段
> `Set<Index> get indexes` 是**死代码**，实际落地时已删除，不要照抄。
> 根因：`get indexes` **不是 drift 的表 API** —— `drift-2.35.0/lib/src/` 中
> grep 不到该成员；`drift_dev-2.35.0` 的表解析器只识别 `primaryKey` /
> `uniqueKeys` / `tableName` 三个 getter，没有 `indexes` 分支。正确机制是
> 类级 `@TableIndex(name:, columns: {#col})` 注解。
> 因此本项目 `app_database.dart` 里**全部** `Set<Index> get indexes` 声明
> （视频侧 3 处 + 本表 1 处）从未创建过任何索引。实证：删除该 getter 后
> 重新生成的 `app_database.g.dart` md5 前后完全一致，且 `allSchemaEntities`
> 中不含任何 `Index` 实体。
> 本功能无任何按 `status` 过滤的查询，故裁定**直接删除**而非改用
> `@TableIndex`（YAGNI；且让索引真正生效需在迁移中显式 `createIndex`，
> drift 的索引是独立 schema 实体、`createTable` 不携带）。
> 详见 `.superpowers/sdd/2026-09-18-audio-extract/progress.md` 的裁定 D19。

- [ ] **Step 4: 注册表并升级 schemaVersion**

在 `@DriftDatabase(tables: [...])` 列表末尾追加 `AudioTasks,`：

```dart
@DriftDatabase(tables: [
  VideoItems,
  ExportTasks,
  CropPresets,
  EditorDrafts,
  AppSettings,
  AudioTasks,
])
```

`int get schemaVersion` 由 `2` 改为 `3`。

- [ ] **Step 5: 加迁移分支**

在 `onUpgrade` 中，`if (from < 2) { ... }` 块**之后**追加：

```dart
        if (from < 3) {
          // v2 -> v3: 新增 AudioTasks 表（音频提取功能）
          // 视频侧表结构不变，旧数据零影响
          await m.createTable(audioTasks);
        }
```

- [ ] **Step 6: 加 DAO 方法**

在 `AppDatabase` 类中，`// ==================== v2: AppSettings DAO ====================` 区块**之前**插入：

```dart
  // ==================== v3: AudioTasks DAO ====================

  Future<List<AudioTask>> getAllAudioTasks() async {
    return await (select(audioTasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).get();
  }

  Future<AudioTask?> getAudioTaskById(int id) async {
    return await (select(audioTasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> insertAudioTask(AudioTasksCompanion companion) async {
    return await into(audioTasks).insert(companion);
  }

  Future<void> deleteAudioTask(int id) async {
    await (delete(audioTasks)..where((t) => t.id.equals(id))).go();
  }

  /// 批量更新音频任务字段（状态/进度/输出路径/完成时间/错误信息）
  Future<void> updateAudioTaskFull({
    required int id,
    String? status,
    int? progress,
    String? outputPath,
    int? completedAt,
    String? errorMessage,
  }) async {
    await (update(audioTasks)..where((t) => t.id.equals(id))).write(
      AudioTasksCompanion(
        status: status != null ? Value(status) : const Value.absent(),
        progress: progress != null ? Value(progress) : const Value.absent(),
        outputPath: outputPath != null ? Value(outputPath) : const Value.absent(),
        completedAt: completedAt != null ? Value(completedAt) : const Value.absent(),
        errorMessage: errorMessage != null ? Value(errorMessage) : const Value.absent(),
      ),
    );
  }

  /// 响应式监听全部音频任务（最近创建的在前）
  Stream<List<AudioTask>> watchAllAudioTasks() {
    return (select(audioTasks)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
    ).watch();
  }
```

- [ ] **Step 7: 重新生成 Drift 代码**

Run: `dart run build_runner build`

> **注意（2026-09-18 修正）**：原命令带的 `--delete-conflicting-outputs` 在
> build_runner 2.16.1 中**已被移除**，传入只会打印
> `These options have been removed and were ignored` 告警后照常执行。
> 使用不带该参数的 `dart run build_runner build`。

Expected: 输出 `Built with build_runner`，`lib/core/database/app_database.g.dart` 中新增 `AudioTask` / `AudioTasksCompanion` / `audioTasks` 访问器

- [ ] **Step 8: 运行测试确认通过**

Run: `flutter test test/core/database/audio_tasks_test.dart`
Expected: PASS，6 个测试全绿（含迁移测试）

若迁移测试报 `SqliteException: table audio_tasks already exists` 或 schema 校验错误：说明 drift 在 `onUpgrade` 之外还做了 schema 比对，需在 `MigrationStrategy` 上加 `beforeOpen` 空实现确认；**不要**改成 `createTableIfNotExists` 绕过，那会让真实升级路径失去覆盖。

- [ ] **Step 9: 回归视频侧数据库测试**

Run: `flutter test test/core/database/database_simple_test.dart`
Expected: PASS，全部原有测试不受影响

- [ ] **Step 10: 提交**

```bash
git add lib/core/database/ test/core/database/audio_tasks_test.dart
git commit -m "新增 AudioTasks 表与 v2→v3 迁移（音频侧独立于视频表）"
```

---

### Task 4: AudioTask 领域模型 + AudioRepository

沿用 `export_task.dart` / `export_repository.dart` 的既有模式：领域模型与 Drift 行分离，Repository 负责映射。

**Files:**
- Create: `lib/core/model/audio_task.dart`
- Create: `lib/core/repository/audio_repository.dart`
- Test: `test/core/repository/audio_repository_test.dart`

**Interfaces:**
- Consumes: Task 3 产出的 `db.AudioTask` / `db.AudioTasksCompanion`
- Produces:
  - `enum AudioTaskStatus { pending, exporting, done, failed }`
  - `class AudioTask extends Equatable`，字段 `int id`、`String sourcePath`、`String sourceName`、`int sourceDurationMs`、`int? sourceBitrateKbps`、`int trimStartMs`、`int trimEndMs`、`String? title`、`String? artist`、`String? album`、`String? coverPath`、`int targetBitrateKbps`、`String outputName`、`String? outputPath`、`AudioTaskStatus status`、`int progress`、`String? errorMessage`、`int createdAt`、`int? completedAt`；getter `String get statusText`、`bool get isProcessing`、`bool get isCompleted`、`bool get isFailed`；方法 `AudioTask copyWith({...})`
  - `class AudioRepository`：`getAllTasks()`、`getTaskById(int)`、`insertTask(AudioTask)`、`deleteTask(int)`、`updateTaskFull({...})`、`watchAllTasks()`

- [ ] **Step 1: 写失败测试**

创建 `test/core/repository/audio_repository_test.dart`：

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutflow_flutter/core/database/app_database.dart';
import 'package:cutflow_flutter/core/model/audio_task.dart';
import 'package:cutflow_flutter/core/repository/audio_repository.dart';

AudioTask _task({String outputName = 'song.mp3'}) {
  return AudioTask(
    id: 0,
    sourcePath: '/test/video.mp4',
    sourceName: 'video.mp4',
    sourceDurationMs: 180000,
    sourceBitrateKbps: 192,
    trimStartMs: 30000,
    trimEndMs: 195000,
    title: '歌名',
    artist: '歌手',
    album: '专辑',
    coverPath: '/test/cover.jpg',
    targetBitrateKbps: 320,
    outputName: outputName,
    status: AudioTaskStatus.pending,
    progress: 0,
    createdAt: DateTime.now().millisecondsSinceEpoch,
  );
}

void main() {
  late AppDatabase db;
  late AudioRepository repo;

  setUp(() {
    db = AppDatabase.forTest(NativeDatabase.memory());
    repo = AudioRepository(db);
  });

  tearDown(() => db.close());

  test('插入并读回，状态枚举往返正确', () async {
    final id = await repo.insertTask(_task());
    final loaded = await repo.getTaskById(id);

    expect(loaded, isNotNull);
    expect(loaded!.status, equals(AudioTaskStatus.pending));
    expect(loaded.title, equals('歌名'));
    expect(loaded.artist, equals('歌手'));
    expect(loaded.album, equals('专辑'));
    expect(loaded.coverPath, equals('/test/cover.jpg'));
    expect(loaded.sourceBitrateKbps, equals(192));
    expect(loaded.targetBitrateKbps, equals(320));
    expect(loaded.trimStartMs, equals(30000));
  });

  test('updateTaskFull 可改状态、进度与输出路径', () async {
    final id = await repo.insertTask(_task());

    await repo.updateTaskFull(id: id, status: 'EXPORTING', progress: 55);
    var loaded = await repo.getTaskById(id);
    expect(loaded!.status, equals(AudioTaskStatus.exporting));
    expect(loaded.progress, equals(55));

    await repo.updateTaskFull(
      id: id,
      status: 'DONE',
      progress: 100,
      outputPath: '/out/song.mp3',
      completedAt: 1700000000000,
    );
    loaded = await repo.getTaskById(id);
    expect(loaded!.status, equals(AudioTaskStatus.done));
    expect(loaded.isCompleted, isTrue);
    expect(loaded.outputPath, equals('/out/song.mp3'));
    expect(loaded.completedAt, equals(1700000000000));
  });

  test('未知状态字符串回退为 pending（不抛异常）', () async {
    final id = await repo.insertTask(_task());
    await db.customStatement(
        "UPDATE audio_tasks SET status = 'WHATEVER' WHERE id = $id");
    final loaded = await repo.getTaskById(id);
    expect(loaded!.status, equals(AudioTaskStatus.pending));
  });

  test('删除任务', () async {
    final id = await repo.insertTask(_task());
    await repo.deleteTask(id);
    expect(await repo.getTaskById(id), isNull);
  });

  test('watchAllTasks 响应式推送', () async {
    final stream = repo.watchAllTasks();
    expect(await stream.first, isEmpty);

    await repo.insertTask(_task());
    final after = await stream.first;
    expect(after.length, equals(1));
    expect(after.first.outputName, equals('song.mp3'));
  });

  test('statusText 文案覆盖四种状态', () {
    expect(_task().copyWith(status: AudioTaskStatus.pending).statusText,
        equals('等待中'));
    expect(_task().copyWith(status: AudioTaskStatus.exporting).statusText,
        equals('转换中'));
    expect(_task().copyWith(status: AudioTaskStatus.done).statusText,
        equals('已完成'));
    expect(_task().copyWith(status: AudioTaskStatus.failed).statusText,
        equals('转换失败'));
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/core/repository/audio_repository_test.dart`
Expected: 编译失败 —— `Target of URI doesn't exist: 'package:cutflow_flutter/core/model/audio_task.dart'`

- [ ] **Step 3: 创建领域模型**

创建 `lib/core/model/audio_task.dart`：

```dart
/// 音频提取任务领域模型
///
/// 与视频侧的 ExportTask 结构上隔离；状态枚举刻意不含 PREPARING，
/// 因为音频转换无需导出前准备阶段。
library;

import 'package:equatable/equatable.dart';

enum AudioTaskStatus {
  pending,   // 等待中
  exporting, // 转换中
  done,      // 已完成
  failed,    // 转换失败
}

class AudioTask extends Equatable {
  final int id;
  final String sourcePath;
  final String sourceName;
  final int sourceDurationMs;
  final int? sourceBitrateKbps; // null = 探测不到
  final int trimStartMs;
  final int trimEndMs;
  final String? title;
  final String? artist;
  final String? album;
  final String? coverPath;
  final int targetBitrateKbps;
  final String outputName;
  final String? outputPath;
  final AudioTaskStatus status;
  final int progress; // 0-100
  final String? errorMessage;
  final int createdAt;
  final int? completedAt;

  const AudioTask({
    required this.id,
    required this.sourcePath,
    required this.sourceName,
    required this.sourceDurationMs,
    this.sourceBitrateKbps,
    required this.trimStartMs,
    required this.trimEndMs,
    this.title,
    this.artist,
    this.album,
    this.coverPath,
    required this.targetBitrateKbps,
    required this.outputName,
    this.outputPath,
    required this.status,
    required this.progress,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sourcePath,
        sourceName,
        sourceDurationMs,
        sourceBitrateKbps,
        trimStartMs,
        trimEndMs,
        title,
        artist,
        album,
        coverPath,
        targetBitrateKbps,
        outputName,
        outputPath,
        status,
        progress,
        errorMessage,
        createdAt,
        completedAt,
      ];

  String get statusText {
    switch (status) {
      case AudioTaskStatus.pending:
        return '等待中';
      case AudioTaskStatus.exporting:
        return '转换中';
      case AudioTaskStatus.done:
        return '已完成';
      case AudioTaskStatus.failed:
        return '转换失败';
    }
  }

  bool get isProcessing => status == AudioTaskStatus.exporting;
  bool get isCompleted => status == AudioTaskStatus.done;
  bool get isFailed => status == AudioTaskStatus.failed;

  AudioTask copyWith({
    int? id,
    String? sourcePath,
    String? sourceName,
    int? sourceDurationMs,
    int? sourceBitrateKbps,
    int? trimStartMs,
    int? trimEndMs,
    String? title,
    String? artist,
    String? album,
    String? coverPath,
    int? targetBitrateKbps,
    String? outputName,
    String? outputPath,
    AudioTaskStatus? status,
    int? progress,
    String? errorMessage,
    int? createdAt,
    int? completedAt,
  }) {
    return AudioTask(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      sourceName: sourceName ?? this.sourceName,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      sourceBitrateKbps: sourceBitrateKbps ?? this.sourceBitrateKbps,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverPath: coverPath ?? this.coverPath,
      targetBitrateKbps: targetBitrateKbps ?? this.targetBitrateKbps,
      outputName: outputName ?? this.outputName,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
```

- [ ] **Step 4: 创建仓储**

创建 `lib/core/repository/audio_repository.dart`：

```dart
/// 音频任务仓储
///
/// 负责领域模型 [AudioTask] 与 Drift 行 [db.AudioTask] 之间的映射，
/// 与视频侧的 ExportRepository 完全隔离。
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart' as db;
import '../model/audio_task.dart';

class AudioRepository {
  final db.AppDatabase _db;

  AudioRepository(this._db);

  /// 全部任务（最近创建的在前）
  Future<List<AudioTask>> getAllTasks() async {
    final rows = await _db.getAllAudioTasks();
    return rows.map(_fromDb).toList();
  }

  Future<AudioTask?> getTaskById(int id) async {
    final row = await _db.getAudioTaskById(id);
    return row != null ? _fromDb(row) : null;
  }

  Future<int> insertTask(AudioTask task) async {
    final companion = db.AudioTasksCompanion.insert(
      sourcePath: task.sourcePath,
      sourceName: task.sourceName,
      sourceDurationMs: task.sourceDurationMs,
      sourceBitrateKbps: Value(task.sourceBitrateKbps),
      trimStartMs: task.trimStartMs,
      trimEndMs: task.trimEndMs,
      title: Value(task.title),
      artist: Value(task.artist),
      album: Value(task.album),
      coverPath: Value(task.coverPath),
      targetBitrateKbps: task.targetBitrateKbps,
      outputName: task.outputName,
      status: _statusToString(task.status),
      progress: Value(task.progress),
      createdAt: task.createdAt,
    );
    return await _db.insertAudioTask(companion);
  }

  Future<void> deleteTask(int id) async {
    await _db.deleteAudioTask(id);
  }

  /// 批量更新任务字段（状态、进度、输出路径、完成时间、错误信息）
  Future<void> updateTaskFull({
    required int id,
    String? status,
    int? progress,
    String? outputPath,
    int? completedAt,
    String? errorMessage,
  }) async {
    await _db.updateAudioTaskFull(
      id: id,
      status: status,
      progress: progress,
      outputPath: outputPath,
      completedAt: completedAt,
      errorMessage: errorMessage,
    );
  }

  /// 响应式监听全部任务
  Stream<List<AudioTask>> watchAllTasks() {
    return _db.watchAllAudioTasks().map((rows) => rows.map(_fromDb).toList());
  }

  // ==================== Private Helpers ====================

  AudioTask _fromDb(db.AudioTask row) {
    return AudioTask(
      id: row.id,
      sourcePath: row.sourcePath,
      sourceName: row.sourceName,
      sourceDurationMs: row.sourceDurationMs,
      sourceBitrateKbps: row.sourceBitrateKbps,
      trimStartMs: row.trimStartMs,
      trimEndMs: row.trimEndMs,
      title: row.title,
      artist: row.artist,
      album: row.album,
      coverPath: row.coverPath,
      targetBitrateKbps: row.targetBitrateKbps,
      outputName: row.outputName,
      outputPath: row.outputPath,
      status: _statusFromString(row.status),
      progress: row.progress,
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      completedAt: row.completedAt,
    );
  }

  String _statusToString(AudioTaskStatus status) {
    switch (status) {
      case AudioTaskStatus.pending:
        return 'PENDING';
      case AudioTaskStatus.exporting:
        return 'EXPORTING';
      case AudioTaskStatus.done:
        return 'DONE';
      case AudioTaskStatus.failed:
        return 'FAILED';
    }
  }

  AudioTaskStatus _statusFromString(String status) {
    switch (status) {
      case 'PENDING':
        return AudioTaskStatus.pending;
      case 'EXPORTING':
        return AudioTaskStatus.exporting;
      case 'DONE':
        return AudioTaskStatus.done;
      case 'FAILED':
        return AudioTaskStatus.failed;
      default:
        return AudioTaskStatus.pending;
    }
  }
}
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/core/repository/audio_repository_test.dart`
Expected: PASS，6 个测试全绿

- [ ] **Step 6: 提交**

```bash
git add lib/core/model/audio_task.dart lib/core/repository/audio_repository.dart test/core/repository/
git commit -m "新增音频任务领域模型与仓储"
```

---

### Task 5: 源音轨探测 AudioMetadataProbe

探测逻辑拆成**纯解析函数**（可单测）+ **进程调用**（薄封装）。

**Files:**
- Create: `lib/core/model/audio_source_info.dart`
- Create: `lib/core/ffmpeg/audio_metadata_probe.dart`
- Test: `test/core/ffmpeg/audio_metadata_probe_test.dart`

**Interfaces:**
- Produces:
  - `class AudioSourceInfo { bool hasAudio; int? bitrateKbps; bool bitrateIsApproximate; String? codec; int? channels; int? sampleRate; int durationMs; const AudioSourceInfo({...}); static const AudioSourceInfo noAudio; }`
  - `AudioMetadataProbe.parseFfprobeJson(String jsonText) -> AudioSourceInfo`（静态纯函数）
  - `AudioMetadataProbe.probe(String path) -> Future<AudioSourceInfo>`（静态异步，调用 ffprobe）

- [ ] **Step 1: 写失败测试**

创建 `test/core/ffmpeg/audio_metadata_probe_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/ffmpeg/audio_metadata_probe.dart';

void main() {
  group('AudioMetadataProbe.parseFfprobeJson', () {
    test('音轨自带 bit_rate 时取精确值，不标记为近似', () {
      const json = '''
      {
        "streams": [
          {"codec_type": "audio", "codec_name": "aac", "bit_rate": "192000",
           "channels": 2, "sample_rate": "48000"}
        ],
        "format": {"duration": "180.500", "bit_rate": "3000000"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.bitrateKbps, equals(192));
      expect(info.bitrateIsApproximate, isFalse);
      expect(info.codec, equals('aac'));
      expect(info.channels, equals(2));
      expect(info.sampleRate, equals(48000));
      expect(info.durationMs, equals(180500));
    });

    test('音轨缺 bit_rate 时回退容器码率，并标记为近似', () {
      const json = '''
      {
        "streams": [
          {"codec_type": "audio", "codec_name": "aac",
           "channels": 6, "sample_rate": "48000"}
        ],
        "format": {"duration": "240.0", "bit_rate": "3200000"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.bitrateKbps, equals(3200)); // 容器总码率，不是音轨码率
      expect(info.bitrateIsApproximate, isTrue);
      expect(info.channels, equals(6));
    });

    test('音轨与容器都没有码率时返回 null', () {
      const json = '''
      {
        "streams": [{"codec_type": "audio", "codec_name": "pcm_s16le"}],
        "format": {"duration": "12.0"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.bitrateKbps, isNull);
      expect(info.bitrateIsApproximate, isFalse);
    });

    test('没有音频流时 hasAudio 为 false', () {
      const json = '''
      {
        "streams": [{"codec_type": "video", "codec_name": "h264"}],
        "format": {"duration": "60.0", "bit_rate": "1500000"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isFalse);
      expect(info.bitrateKbps, isNull);
      expect(info.durationMs, equals(60000));
    });

    test('空 streams 数组同样判为无音轨', () {
      final info = AudioMetadataProbe.parseFfprobeJson(
          '{"streams": [], "format": {"duration": "5.0"}}');
      expect(info.hasAudio, isFalse);
    });

    test('非法 JSON 不抛异常，返回 noAudio', () {
      final info = AudioMetadataProbe.parseFfprobeJson('not json at all');
      expect(info.hasAudio, isFalse);
      expect(info.bitrateKbps, isNull);
    });

    test('缺 format 时 durationMs 为 0', () {
      const json = '{"streams": [{"codec_type": "audio", "codec_name": "mp3"}]}';
      final info = AudioMetadataProbe.parseFfprobeJson(json);
      expect(info.hasAudio, isTrue);
      expect(info.durationMs, equals(0));
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/core/ffmpeg/audio_metadata_probe_test.dart`
Expected: 编译失败 —— `Target of URI doesn't exist: '.../audio_metadata_probe.dart'`

- [ ] **Step 3: 创建探测结果模型**

创建 `lib/core/model/audio_source_info.dart`：

```dart
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
```

- [ ] **Step 4: 创建探测器**

创建 `lib/core/ffmpeg/audio_metadata_probe.dart`：

```dart
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
```

- [ ] **Step 5: 运行测试确认通过**

Run: `flutter test test/core/ffmpeg/audio_metadata_probe_test.dart`
Expected: PASS，7 个测试全绿

- [ ] **Step 6: 提交**

```bash
git add lib/core/model/audio_source_info.dart lib/core/ffmpeg/audio_metadata_probe.dart test/core/ffmpeg/
git commit -m "新增源音轨探测（ffprobe，含码率回退链）"
```

---

### Task 6: 输出文件名清洗 + buildExtractMp3 命令构建

**Files:**
- Create: `lib/core/util/filename_sanitizer.dart`
- Modify: `lib/core/ffmpeg/command_builder.dart`
- Test: `test/core/util/filename_sanitizer_test.dart`
- Test: `test/core/ffmpeg/extract_mp3_command_test.dart`

**Interfaces:**
- Produces:
  - `FilenameSanitizer.sanitize(String raw) -> String`
  - `FfmpegCommandBuilder.buildExtractMp3({required String inputPath, required String outputPath, required int startMs, required int endMs, required int targetBitrateKbps, String? coverPath, String? title, String? artist, String? album}) -> List<String>`
  - `FfmpegCommandBuilder.normalizeTagValue(String? raw) -> String?`

- [ ] **Step 1: 写文件名清洗的失败测试**

创建 `test/core/util/filename_sanitizer_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/util/filename_sanitizer.dart';

void main() {
  group('FilenameSanitizer.sanitize', () {
    test('斜杠替换为下划线（AC/DC 场景）', () {
      expect(FilenameSanitizer.sanitize('AC/DC - Back in Black'),
          equals('AC_DC - Back in Black'));
    });

    test('冒号替换为下划线', () {
      expect(FilenameSanitizer.sanitize('Song: Live'), equals('Song_ Live'));
    });

    test('覆盖全部 Windows 非法字符', () {
      expect(FilenameSanitizer.sanitize(r'a\b/c:d*e?f"g<h>i|j'),
          equals('a_b_c_d_e_f_g_h_i_j'));
    });

    test('去除首尾空格与点号', () {
      expect(FilenameSanitizer.sanitize('  ..歌名..  '), equals('歌名'));
    });

    test('中文与常见符号原样保留', () {
      expect(FilenameSanitizer.sanitize('晴天 - 周杰伦 (Live)'),
          equals('晴天 - 周杰伦 (Live)'));
    });

    test('清洗后为空时回退为 audio', () {
      expect(FilenameSanitizer.sanitize(''), equals('audio'));
      expect(FilenameSanitizer.sanitize('   '), equals('audio'));
      expect(FilenameSanitizer.sanitize('...'), equals('audio'));
      expect(FilenameSanitizer.sanitize('///'), equals('___'));
    });

    test('剔除控制字符', () {
      expect(FilenameSanitizer.sanitize('song\u0000name'), equals('songname'));
    });
  });
}
```

- [ ] **Step 2: 写命令构建的失败测试**

创建 `test/core/ffmpeg/extract_mp3_command_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/ffmpeg/command_builder.dart';

/// 取 `-flag` 后紧跟的值
String? _valueOf(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

/// 第 n 个 `-metadata`（含 `-metadata:s:v`）之后的值
List<String> _allValuesOf(List<String> args, String flag) {
  final result = <String>[];
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == flag) result.add(args[i + 1]);
  }
  return result;
}

void main() {
  group('buildExtractMp3（带封面）', () {
    late List<String> args;

    setUp(() {
      args = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/video.mp4',
        outputPath: '/out/song.mp3',
        startMs: 30000,
        endMs: 195000,
        targetBitrateKbps: 320,
        coverPath: '/in/cover.jpg',
        title: '晴天',
        artist: '周杰伦',
        album: '叶惠美',
      );
    });

    test('输出路径在末尾', () {
      expect(args.last, equals('/out/song.mp3'));
    });

    test('-ss 在 -i 输入之前（输入 seek）', () {
      expect(args.indexOf('-ss'), lessThan(args.indexOf('-i')));
    });

    test('-t 在所有输入之后（输出时长限制）', () {
      final lastInput = args.lastIndexOf('-i');
      expect(args.indexOf('-t'), greaterThan(lastInput));
    });

    test('时长为 出点-入点（165 秒）', () {
      expect(_valueOf(args, '-t'), equals('00:02:45.000'));
    });

    test('码率参数正确', () {
      expect(_valueOf(args, '-b:a'), equals('320k'));
      expect(_valueOf(args, '-c:a'), equals('libmp3lame'));
    });

    test('ID3 版本固定为 3', () {
      expect(_valueOf(args, '-id3v2_version'), equals('3'));
    });

    test('三个标签正确写入', () {
      expect(_allValuesOf(args, '-metadata'),
          containsAll(['title=晴天', 'artist=周杰伦', 'album=叶惠美']));
    });

    test('封面映射与 attached_pic 齐备', () {
      expect(_allValuesOf(args, '-map'), equals(['0:a:0', '1:v:0']));
      expect(_valueOf(args, '-c:v'), equals('mjpeg'));
      expect(_valueOf(args, '-disposition:v'), equals('attached_pic'));
    });

    test('封面缩放滤镜限制最长边 600 且不放大', () {
      expect(_valueOf(args, '-vf'), equals(r'scale=w=min(600\,iw):h=-2'));
    });

    test('封面流带 Album cover 元数据', () {
      expect(_allValuesOf(args, '-metadata:s:v'),
          equals(['title=Album cover', 'comment=Cover (front)']));
    });
  });

  group('buildExtractMp3（不带封面）', () {
    late List<String> args;

    setUp(() {
      args = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/video.mp4',
        outputPath: '/out/song.mp3',
        startMs: 0,
        endMs: 60000,
        targetBitrateKbps: 192,
      );
    });

    test('不出现任何封面相关参数', () {
      expect(args.contains('-c:v'), isFalse);
      expect(args.contains('-vf'), isFalse);
      expect(args.contains('-disposition:v'), isFalse);
      expect(args.contains('-metadata:s:v'), isFalse);
      expect(_allValuesOf(args, '-map'), isEmpty);
      expect(args.where((a) => a == '-i').length, equals(1));
    });

    test('标签留空时不写入对应 -metadata', () {
      expect(_allValuesOf(args, '-metadata'), isEmpty);
    });

    test('音频参数与 ID3 版本仍在', () {
      expect(_valueOf(args, '-c:a'), equals('libmp3lame'));
      expect(_valueOf(args, '-b:a'), equals('192k'));
      expect(_valueOf(args, '-id3v2_version'), equals('3'));
      expect(args.last, equals('/out/song.mp3'));
    });
  });

  group('标签值规整', () {
    test('换行折为空格、去首尾空格', () {
      expect(FfmpegCommandBuilder.normalizeTagValue('  晴天\nLive  '),
          equals('晴天 Live'));
      expect(FfmpegCommandBuilder.normalizeTagValue('a\r\nb'),
          equals('a b'));
    });

    test('null 与纯空白返回 null', () {
      expect(FfmpegCommandBuilder.normalizeTagValue(null), isNull);
      expect(FfmpegCommandBuilder.normalizeTagValue('   '), isNull);
      expect(FfmpegCommandBuilder.normalizeTagValue('\n\n'), isNull);
    });

    test('含引号与 & | 的标签原样保留（不经 shell，无需转义）', () {
      expect(FfmpegCommandBuilder.normalizeTagValue('Rock "n" Roll & More'),
          equals('Rock "n" Roll & More'));
    });

    test('空标签不生成 -metadata 参数', () {
      final args = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/v.mp4',
        outputPath: '/out/o.mp3',
        startMs: 0,
        endMs: 1000,
        targetBitrateKbps: 128,
        title: '   ',
        artist: '周杰伦',
        album: null,
      );
      expect(_allValuesOf(args, '-metadata'), equals(['artist=周杰伦']));
    });
  });
}
```

- [ ] **Step 3: 运行测试确认失败**

Run: `flutter test test/core/util/filename_sanitizer_test.dart test/core/ffmpeg/extract_mp3_command_test.dart`
Expected: 编译失败 —— `Target of URI doesn't exist: '.../filename_sanitizer.dart'`；`The method 'buildExtractMp3' isn't defined`

- [ ] **Step 4: 创建文件名清洗器**

创建 `lib/core/util/filename_sanitizer.dart`：

```dart
/// 输出文件名清洗
///
/// Windows 文件名禁止 `\ / : * ? " < > |`，而歌名极易含 `/`（如 AC/DC）
/// 或 `:`。生成输出文件名前必须清洗。
///
/// **只清洗文件名，不清洗 ID3 标签内容** —— 标签里保留用户原样输入。
library;

class FilenameSanitizer {
  static final RegExp _illegalChars = RegExp(r'[\\/:*?"<>|]');
  static final RegExp _controlChars = RegExp(r'[\x00-\x1f]');
  static final RegExp _leadingOrTrailing = RegExp(r'^[\s.]+|[\s.]+$');

  /// 清洗为安全的文件名主干（不含扩展名）
  ///
  /// 规则：非法字符 → `_` → 剔除控制字符 → 去除首尾空格与点号
  /// （Windows 下文件名不能以点或空格结尾）→ 空结果回退为 `audio`。
  static String sanitize(String raw) {
    var name = raw.replaceAll(_illegalChars, '_');
    name = name.replaceAll(_controlChars, '');
    name = name.replaceAll(_leadingOrTrailing, '');
    return name.isEmpty ? 'audio' : name;
  }
}
```

- [ ] **Step 5: 加 buildExtractMp3 到命令构建器**

在 `lib/core/ffmpeg/command_builder.dart` 的 `FfmpegCommandBuilder` 类中，`buildTranscodeH264` 方法之后追加：

```dart
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
        '-vf', r'scale=w=min(600\,iw):h=-2', // 最长边 600，不放大
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
```

- [ ] **Step 6: 运行测试确认通过**

Run: `flutter test test/core/util/filename_sanitizer_test.dart test/core/ffmpeg/extract_mp3_command_test.dart`
Expected: PASS，全部测试绿

- [ ] **Step 7: 提交**

```bash
git add lib/core/util/filename_sanitizer.dart lib/core/ffmpeg/command_builder.dart test/core/util/ test/core/ffmpeg/extract_mp3_command_test.dart
git commit -m "新增 MP3 提取命令构建与输出文件名清洗"
```

---

### Task 7: AudioViewModel

**Files:**
- Create: `lib/features/audio/audio_viewmodel.dart`
- Test: `test/features/audio/audio_viewmodel_test.dart`

**Interfaces:**
- Consumes: `AudioRepository`（Task 4）、`AudioSourceInfo`（Task 5）、`AudioMetadataProbe`（Task 5）、`FilenameSanitizer`（Task 6）、`FfmpegCommandBuilder.buildExtractMp3`（Task 6）、`FfmpegEngine`、`AppSettingsRepository`、`ExplorerService`
- Produces:
  - `const List<int> kAudioBitrateOptions` = `[128, 160, 192, 256, 320]`
  - `class AudioState { String? sourcePath; String? sourceName; int sourceDurationMs; int trimStartMs; int trimEndMs; String title; String artist; String album; String? coverPath; int targetBitrateKbps; String? outputDirectory; AudioSourceInfo? sourceInfo; bool isProbing; bool isConverting; int progress; String? error; String? success; String? blockingError; bool canConvert; String outputFileName; }`（后三者为 getter）
  - `class AudioViewModel extends StateNotifier<AudioState>`
  - `final audioProvider = StateNotifierProvider<AudioViewModel, AudioState>(...)`
  - `final audioRecordsProvider = StreamProvider<List<AudioTask>>(...)`

- [ ] **Step 1: 写失败测试**

创建 `test/features/audio/audio_viewmodel_test.dart`。测试只覆盖**纯状态与校验逻辑**（不碰 ffmpeg 进程）：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/model/audio_source_info.dart';
import 'package:cutflow_flutter/features/audio/audio_viewmodel.dart';

AudioState _base({
  String? sourcePath = '/in/video.mp4',
  String? sourceName = 'video.mp4',
  int trimStartMs = 0,
  int trimEndMs = 60000,
  String title = '',
  String? coverPath,
  AudioSourceInfo? sourceInfo,
  bool isConverting = false,
}) {
  return AudioState(
    sourcePath: sourcePath,
    sourceName: sourceName,
    sourceDurationMs: 180000,
    trimStartMs: trimStartMs,
    trimEndMs: trimEndMs,
    title: title,
    artist: '',
    album: '',
    coverPath: coverPath,
    targetBitrateKbps: 320,
    sourceInfo: sourceInfo,
    isConverting: isConverting,
  );
}

void main() {
  group('输出文件名', () {
    test('歌名非空时用歌名', () {
      final state = _base(title: '晴天');
      expect(state.outputFileName, equals('晴天.mp3'));
    });

    test('歌名为空时回退源文件名', () {
      final state = _base(title: '   ');
      expect(state.outputFileName, equals('video.mp3'));
    });

    test('歌名含非法字符时被清洗', () {
      final state = _base(title: 'AC/DC: Live');
      expect(state.outputFileName, equals('AC_DC_ Live.mp3'));
    });

    test('清洗后为空则回退 audio', () {
      final state = _base(title: '...');
      expect(state.outputFileName, equals('audio.mp3'));
    });
  });

  group('校验 blockingError', () {
    test('未选文件时提示选择视频', () {
      final state = _base(sourcePath: null, sourceName: null);
      expect(state.blockingError, equals('请先选择视频文件'));
    });

    test('无音轨时拦截', () {
      final state = _base(sourceInfo: AudioSourceInfo.noAudio);
      expect(state.blockingError, equals('该视频没有音频轨道，无法提取音频'));
    });

    test('探测中不拦截（尚未知结果）', () {
      final state = _base(sourceInfo: null);
      expect(state.blockingError, isNull);
    });

    test('出点不大于入点时提示', () {
      expect(_base(trimStartMs: 5000, trimEndMs: 5000).blockingError,
          equals('出点必须大于入点'));
      expect(_base(trimStartMs: 5000, trimEndMs: 1000).blockingError,
          equals('出点必须大于入点'));
    });

    test('正常状态无拦截', () {
      expect(_base().blockingError, isNull);
    });
  });

  group('canConvert', () {
    test('无拦截项且不在转换中时可转换', () {
      expect(_base(title: '晴天').canConvert, isTrue);
    });

    test('转换中不可再转换', () {
      expect(_base(isConverting: true).canConvert, isFalse);
    });

    test('有拦截项时不可转换', () {
      expect(_base(sourcePath: null).canConvert, isFalse);
      expect(_base(trimStartMs: 0, trimEndMs: 0).canConvert, isFalse);
    });
  });

  group('码率档位', () {
    test('档位为 128/160/192/256/320', () {
      expect(kAudioBitrateOptions, equals([128, 160, 192, 256, 320]));
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/audio/audio_viewmodel_test.dart`
Expected: 编译失败 —— `Target of URI doesn't exist: '.../audio_viewmodel.dart'`

- [ ] **Step 3: 实现 ViewModel**

创建 `lib/features/audio/audio_viewmodel.dart`：

```dart
/// 音频提取页面 ViewModel
///
/// 编排「选文件 → 探测音轨 → 选区间 → 填标签 → 转换 → 入库」全流程。
/// 单文件串行执行，同一时刻至多一个转换在跑。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/ffmpeg/audio_metadata_probe.dart';
import '../../core/ffmpeg/command_builder.dart';
import '../../core/ffmpeg/ffmpeg_engine.dart';
import '../../core/model/audio_source_info.dart';
import '../../core/model/audio_task.dart';
import '../../core/repository/app_settings_repository.dart';
import '../../core/repository/audio_repository.dart';
import '../../core/util/filename_sanitizer.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

/// 目标码率档位（kbps）
const List<int> kAudioBitrateOptions = [128, 160, 192, 256, 320];

/// 上次选择的码率在 AppSettings 中的键
const String kAudioTargetBitrateKey = 'audio_target_bitrate';

/// 音频页状态
class AudioState {
  final String? sourcePath;
  final String? sourceName;
  final int sourceDurationMs;
  final int trimStartMs;
  final int trimEndMs;
  final String title;
  final String artist;
  final String album;
  final String? coverPath;
  final int targetBitrateKbps;
  final String? outputDirectory;
  final AudioSourceInfo? sourceInfo; // null = 尚未探测/探测中
  final bool isProbing;
  final bool isConverting;
  final int progress;
  final String? error;
  final String? success;

  const AudioState({
    this.sourcePath,
    this.sourceName,
    this.sourceDurationMs = 0,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.title = '',
    this.artist = '',
    this.album = '',
    this.coverPath,
    this.targetBitrateKbps = 320,
    this.outputDirectory,
    this.sourceInfo,
    this.isProbing = false,
    this.isConverting = false,
    this.progress = 0,
    this.error,
    this.success,
  });

  /// 阻断转换的原因；null = 可以转换
  String? get blockingError {
    if (sourcePath == null) return '请先选择视频文件';
    if (sourceInfo != null && !sourceInfo!.hasAudio) {
      return '该视频没有音频轨道，无法提取音频';
    }
    if (trimEndMs <= trimStartMs) return '出点必须大于入点';
    return null;
  }

  bool get canConvert =>
      blockingError == null && !isConverting && !isProbing;

  /// 输出文件名：歌名优先，回退源文件名；均经非法字符清洗
  String get outputFileName {
    final trimmed = title.trim();
    final raw = trimmed.isNotEmpty
        ? trimmed
        : p.basenameWithoutExtension(sourceName ?? '');
    return '${FilenameSanitizer.sanitize(raw)}.mp3';
  }

  AudioState copyWith({
    Object? sourcePath = _sentinel,
    Object? sourceName = _sentinel,
    int? sourceDurationMs,
    int? trimStartMs,
    int? trimEndMs,
    String? title,
    String? artist,
    String? album,
    Object? coverPath = _sentinel,
    int? targetBitrateKbps,
    Object? outputDirectory = _sentinel,
    Object? sourceInfo = _sentinel,
    bool? isProbing,
    bool? isConverting,
    int? progress,
    Object? error = _sentinel,
    Object? success = _sentinel,
  }) {
    return AudioState(
      sourcePath:
          sourcePath == _sentinel ? this.sourcePath : sourcePath as String?,
      sourceName:
          sourceName == _sentinel ? this.sourceName : sourceName as String?,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverPath: coverPath == _sentinel ? this.coverPath : coverPath as String?,
      targetBitrateKbps: targetBitrateKbps ?? this.targetBitrateKbps,
      outputDirectory: outputDirectory == _sentinel
          ? this.outputDirectory
          : outputDirectory as String?,
      sourceInfo: sourceInfo == _sentinel
          ? this.sourceInfo
          : sourceInfo as AudioSourceInfo?,
      isProbing: isProbing ?? this.isProbing,
      isConverting: isConverting ?? this.isConverting,
      progress: progress ?? this.progress,
      error: error == _sentinel ? this.error : error as String?,
      success: success == _sentinel ? this.success : success as String?,
    );
  }
}

/// copyWith 中用于区分「不传」与「显式传 null」的哨兵
const Object _sentinel = Object();

class AudioViewModel extends StateNotifier<AudioState> {
  final AudioRepository _repository;
  final AppSettingsRepository _settings;

  FfmpegEngine? _currentEngine;
  int? _currentTaskId;

  /// 本次转换**去重后**的实际输出路径（取消/失败时据此清理半成品文件）
  String? _currentOutputPath;

  AudioViewModel(this._repository, this._settings)
      : super(const AudioState()) {
    _restorePreferences();
  }

  /// 读取记忆的目标码率与默认输出目录
  Future<void> _restorePreferences() async {
    try {
      final savedBitrate = await _settings.getSetting(kAudioTargetBitrateKey);
      final bitrate = int.tryParse(savedBitrate ?? '');
      final outputDir = await _settings.getExportDirectory();
      state = state.copyWith(
        targetBitrateKbps:
            bitrate != null && kAudioBitrateOptions.contains(bitrate)
                ? bitrate
                : null,
        outputDirectory: outputDir,
      );
    } catch (e) {
      log('AudioVM').e('Failed to restore preferences', error: e);
    }
  }

  /// 选择源视频 → 重置区间 → 异步探测音轨
  Future<void> setSourceFile(String path) async {
    final name = p.basename(path);
    state = state.copyWith(
      sourcePath: path,
      sourceName: name,
      sourceDurationMs: 0,
      trimStartMs: 0,
      trimEndMs: 0,
      sourceInfo: null,
      isProbing: true,
      isConverting: false,
      progress: 0,
      error: null,
      success: null,
    );
    log('AudioVM').i('Source selected: $path');

    final info = await AudioMetadataProbe.probe(path);
    // 探测期间用户可能又换了文件，此处校验路径未被替换
    if (!mounted || state.sourcePath != path) return;

    state = state.copyWith(
      sourceInfo: info,
      isProbing: false,
      sourceDurationMs: info.durationMs,
      trimEndMs: info.durationMs > 0 ? info.durationMs : 0,
    );
  }

  void setTrimStart(int ms) {
    final clamped = ms.clamp(0, state.sourceDurationMs);
    if (clamped == state.trimStartMs) return;
    state = state.copyWith(trimStartMs: clamped, error: null);
  }

  void setTrimEnd(int ms) {
    final clamped = ms.clamp(0, state.sourceDurationMs);
    if (clamped == state.trimEndMs) return;
    state = state.copyWith(trimEndMs: clamped, error: null);
  }

  /// 「快退」/「快进」按固定步长移动入点
  void stepStart(int deltaMs) => setTrimStart(state.trimStartMs + deltaMs);

  /// 「快退」/「快进」按固定步长移动出点
  void stepEnd(int deltaMs) => setTrimEnd(state.trimEndMs + deltaMs);

  void setTitle(String value) => state = state.copyWith(title: value);
  void setArtist(String value) => state = state.copyWith(artist: value);
  void setAlbum(String value) => state = state.copyWith(album: value);

  void setCoverPath(String? path) =>
      state = state.copyWith(coverPath: path, error: null);

  Future<void> setTargetBitrate(int kbps) async {
    state = state.copyWith(targetBitrateKbps: kbps);
    try {
      await _settings.setSetting(kAudioTargetBitrateKey, kbps.toString());
    } catch (e) {
      log('AudioVM').e('Failed to persist bitrate', error: e);
    }
  }

  void setOutputDirectory(String dir) =>
      state = state.copyWith(outputDirectory: dir);

  void clearMessages() =>
      state = state.copyWith(error: null, success: null);

  /// 开始转换
  Future<void> startConversion() async {
    final blocked = state.blockingError;
    if (blocked != null) {
      state = state.copyWith(error: blocked);
      return;
    }

    final sourcePath = state.sourcePath!;
    final outputDir = state.outputDirectory;
    if (outputDir == null || outputDir.isEmpty) {
      state = state.copyWith(error: '未设置输出目录');
      return;
    }

    state = state.copyWith(
      isConverting: true,
      progress: 0,
      error: null,
      success: null,
    );

    final trimStart = state.trimStartMs;
    final trimEnd = state.trimEndMs;
    final duration = trimEnd - trimStart;

    try {
      // 1. 源文件二次校验
      if (!await File(sourcePath).exists()) {
        state = state.copyWith(isConverting: false, error: '源文件不存在');
        return;
      }

      // 2. 封面文件校验（选了才校验）
      final coverPath = state.coverPath;
      if (coverPath != null &&
          coverPath.isNotEmpty &&
          !await File(coverPath).exists()) {
        state = state.copyWith(isConverting: false, error: '封面图片不存在，请重新选择');
        return;
      }

      // 3. 确保输出目录存在
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 4. 输出路径去重
      final outputPath = await _resolveOutputPath(outputDir, state.outputFileName);

      // 5. 入库（状态 PENDING）
      final taskId = await _repository.insertTask(AudioTask(
        id: 0,
        sourcePath: sourcePath,
        sourceName: state.sourceName ?? p.basename(sourcePath),
        sourceDurationMs: state.sourceDurationMs,
        sourceBitrateKbps: state.sourceInfo?.bitrateKbps,
        trimStartMs: trimStart,
        trimEndMs: trimEnd,
        title: _nullIfBlank(state.title),
        artist: _nullIfBlank(state.artist),
        album: _nullIfBlank(state.album),
        coverPath: coverPath,
        targetBitrateKbps: state.targetBitrateKbps,
        outputName: state.outputFileName,
        status: AudioTaskStatus.pending,
        progress: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _currentTaskId = taskId;
      _currentOutputPath = outputPath;

      // 6. 构建命令
      final command = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: sourcePath,
        outputPath: outputPath,
        startMs: trimStart,
        endMs: trimEnd,
        targetBitrateKbps: state.targetBitrateKbps,
        coverPath: coverPath,
        title: state.title,
        artist: state.artist,
        album: state.album,
      );

      await _repository.updateTaskFull(
          id: taskId, status: 'EXPORTING', progress: 0);

      // 7. 执行（进度基准 = 输出时长）
      final engine = FfmpegEngine();
      _currentEngine = engine;

      await for (final progress in engine.executeWithProgress(
        command: command,
        totalDurationMs: duration,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _currentEngine = null;
          final message = progress.error == 'Cancelled by user'
              ? '已取消'
              : '转换失败: ${progress.error}';
          await _handleFailure(
            taskId: taskId,
            outputPath: outputPath,
            message: message,
            cancelled: progress.error == 'Cancelled by user',
          );
          return;
        }

        state = state.copyWith(progress: progress.progress);
        await _repository.updateTaskFull(
            id: taskId, progress: progress.progress);
      }

      _currentEngine = null;
      _currentTaskId = null;
      _currentOutputPath = null;

      await _repository.updateTaskFull(
        id: taskId,
        status: 'DONE',
        progress: 100,
        outputPath: outputPath,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        isConverting: false,
        progress: 100,
        success: '转换完成: $outputPath',
      );
      log('AudioVM').i('Conversion done: $outputPath');
    } catch (e) {
      _currentEngine = null;
      log('AudioVM').e('Conversion failed', error: e);
      final taskId = _currentTaskId;
      _currentTaskId = null;
      _currentOutputPath = null;
      if (taskId != null) {
        await _repository.updateTaskFull(
            id: taskId, status: 'FAILED', errorMessage: e.toString());
      }
      state = state.copyWith(isConverting: false, error: '转换失败: $e');
    }
  }

  /// 取消转换：杀进程 + 删半成品文件 + 删任务记录
  Future<void> cancelConversion() async {
    final taskId = _currentTaskId;
    final outputPath = _currentOutputPath;
    final engine = _currentEngine;
    if (engine == null) return;

    await engine.cancel();
    _currentEngine = null;
    _currentTaskId = null;
    _currentOutputPath = null;

    // 删任务记录 + 清半成品文件（用去重后的真实路径）
    if (taskId != null) {
      await _repository.deleteTask(taskId);
    }
    await _deleteFileQuietly(outputPath);

    if (!mounted) return;
    state = state.copyWith(isConverting: false, progress: 0, error: '已取消');
  }

  /// 把一条失败记录的参数回填到表单，供用户修正后重试
  void restoreFromTask(AudioTask task) {
    state = state.copyWith(
      sourcePath: task.sourcePath,
      sourceName: task.sourceName,
      sourceDurationMs: task.sourceDurationMs,
      trimStartMs: task.trimStartMs,
      trimEndMs: task.trimEndMs,
      title: task.title ?? '',
      artist: task.artist ?? '',
      album: task.album ?? '',
      coverPath: task.coverPath,
      targetBitrateKbps: task.targetBitrateKbps,
      error: null,
      success: null,
    );
  }

  Future<void> _handleFailure({
    required int taskId,
    required String outputPath,
    required String message,
    required bool cancelled,
  }) async {
    _currentTaskId = null;
    _currentOutputPath = null;

    if (cancelled) {
      await _repository.deleteTask(taskId);
    } else {
      await _repository.updateTaskFull(
          id: taskId, status: 'FAILED', errorMessage: message);
    }

    // 清理半成品文件（用去重后的真实路径）
    await _deleteFileQuietly(outputPath);

    if (!mounted) return;
    state = state.copyWith(
      isConverting: false,
      progress: 0,
      error: message,
    );
  }

  /// 尽力删除文件：失败只记日志，不阻断调用方流程
  ///
  /// 文件可能已被用户手动移走或正被占用，此处卡住反而更糟。
  static Future<void> _deleteFileQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      log('AudioVM').w('Failed to delete file: $path', error: e);
    }
  }

  /// 输出路径去重：重名时追加 _1 / _2 …
  Future<String> _resolveOutputPath(String dir, String fileName) async {
    var candidate = p.join(dir, fileName);
    if (!await File(candidate).exists()) return candidate;

    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dir, '${base}_$counter$ext');
      counter++;
    }
    return candidate;
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// 音频页 ViewModel Provider
final audioProvider = StateNotifierProvider<AudioViewModel, AudioState>((ref) {
  return AudioViewModel(
    AudioRepository(database),
    AppSettingsRepository(database),
  );
});

/// 转换记录（响应式）
final audioRecordsProvider = StreamProvider<List<AudioTask>>((ref) {
  return AudioRepository(database).watchAllTasks();
});
```

- [ ] **Step 4: 运行测试确认通过**

Run: `flutter test test/features/audio/audio_viewmodel_test.dart`
Expected: PASS，全部测试绿

若报 `mounted` 未定义或 `p.extension` 拼写错误，按 Dart 分析器提示修正；`StateNotifier.mounted` 由 `flutter_riverpod` 提供。

- [ ] **Step 5: 静态分析**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 6: 提交**

```bash
git add lib/features/audio/audio_viewmodel.dart test/features/audio/
git commit -m "新增音频提取 ViewModel（探测/校验/转换/入库编排）"
```

---

### Task 8: 音频页 UI

**Files:**
- Create: `lib/features/audio/widgets/audio_tag_panel.dart`
- Create: `lib/features/audio/widgets/audio_bitrate_selector.dart`
- Create: `lib/features/audio/widgets/audio_record_tile.dart`
- Modify: `lib/features/audio/audio_screen.dart`（整体重写）
- Test: `test/features/audio/audio_screen_test.dart`

**Interfaces:**
- Consumes: `audioProvider` / `audioRecordsProvider` / `kAudioBitrateOptions`（Task 7）、`TrimRangeControl`（Task 2 的新参数）、`VideoPreviewPanel`
- Produces: `AudioScreen`（保持无参构造，Task 1 的路由无需改动）

- [ ] **Step 1: 写失败测试**

创建 `test/features/audio/audio_screen_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutflow_flutter/features/audio/audio_screen.dart';

void main() {
  testWidgets('空态显示引导文案', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: AudioScreen()),
    ));
    await tester.pump();

    expect(find.text('音频提取'), findsOneWidget);
    expect(find.text('选择一个视频开始提取音频'), findsOneWidget);
  });

  testWidgets('未选文件时开始转换按钮禁用', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: AudioScreen()),
    ));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始转换'),
    );
    expect(button.onPressed, isNull);
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `flutter test test/features/audio/audio_screen_test.dart`
Expected: FAIL —— `Expected: exactly one matching candidate / Actual: _TextWidgetFinder:<zero widgets>`（当前是 Task 1 的空壳页）

- [ ] **Step 3: 创建标签面板**

创建 `lib/features/audio/widgets/audio_tag_panel.dart`：

```dart
/// 歌曲信息面板：歌名 / 歌手 / 专辑 + 封面选择
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../ui/theme/colors.dart';

class AudioTagPanel extends StatelessWidget {
  final String title;
  final String artist;
  final String album;
  final String? coverPath;
  final bool enabled;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistChanged;
  final ValueChanged<String> onAlbumChanged;
  final ValueChanged<String?> onCoverChanged;

  const AudioTagPanel({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverPath,
    required this.enabled,
    required this.onTitleChanged,
    required this.onArtistChanged,
    required this.onAlbumChanged,
    required this.onCoverChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '歌曲信息',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        _field(
          label: '歌名',
          hint: '留空则不写入标签，文件名用源文件名',
          value: title,
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 8),
        _field(label: '歌手', hint: '留空则不写入标签', value: artist, onChanged: onArtistChanged),
        const SizedBox(height: 8),
        _field(label: '专辑', hint: '留空则不写入标签', value: album, onChanged: onAlbumChanged),
        const SizedBox(height: 12),
        _coverRow(context),
      ],
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              enabled: enabled,
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 44,
          child: Text('封面',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ),
        _coverThumbnail(),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: enabled ? () => _pickCover(context) : null,
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(coverPath == null ? '选择图片' : '更换图片'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        if (coverPath != null) ...[
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed: enabled ? () => onCoverChanged(null) : null,
            icon: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
            label: const Text('清除',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ),
        ],
      ],
    );
  }

  Widget _coverThumbnail() {
    if (coverPath == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Icon(Icons.music_note, size: 18, color: AppColors.textHint),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(coverPath!),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        // 用户可能选了非图片文件，兜底避免崩溃
        errorBuilder: (context, error, stack) => Container(
          width: 40,
          height: 40,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined,
              size: 18, color: AppColors.textHint),
        ),
      ),
    );
  }

  Future<void> _pickCover(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        allowMultiple: false,
      );
      final path = result?.files.firstOrNull?.path;
      if (path != null) onCoverChanged(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择封面失败: $e')));
      }
    }
  }
}
```

- [ ] **Step 4: 创建码率选择器**

创建 `lib/features/audio/widgets/audio_bitrate_selector.dart`：

```dart
/// 音频码率选择：左侧展示源码率供参考，右侧选择目标码率
library;

import 'package:flutter/material.dart';

import '../../../core/model/audio_source_info.dart';
import '../../../ui/theme/colors.dart';
import '../audio_viewmodel.dart';

class AudioBitrateSelector extends StatelessWidget {
  final AudioSourceInfo? sourceInfo;
  final int targetBitrateKbps;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const AudioBitrateSelector({
    super.key,
    required this.sourceInfo,
    required this.targetBitrateKbps,
    required this.enabled,
    required this.onChanged,
  });

  /// 源码率展示文案
  String get _sourceLabel {
    final info = sourceInfo;
    if (info == null) return '源: 探测中…';
    if (!info.hasAudio) return '源: 无音频轨';
    final kbps = info.bitrateKbps;
    if (kbps == null) return '源: 未知';
    // 来自容器总码率时必须标注，避免用户误以为这是音轨码率
    if (info.bitrateIsApproximate) {
      return '源: 约 $kbps kbps（容器总码率，仅供参考）';
    }
    return '源: $kbps kbps';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 210,
          child: Text(
            _sourceLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        const Text('目标',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: targetBitrateKbps,
              isDense: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              items: [
                for (final kbps in kAudioBitrateOptions)
                  DropdownMenuItem<int>(
                    value: kbps,
                    child: Text('$kbps kbps'),
                  ),
              ],
              onChanged: enabled
                  ? (value) {
                      if (value != null) onChanged(value);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: 创建记录行**

创建 `lib/features/audio/widgets/audio_record_tile.dart`：

```dart
/// 转换记录单行
library;

import 'package:flutter/material.dart';

import '../../../core/model/audio_task.dart';
import '../../../core/util/time_formatter.dart';
import '../../../ui/theme/colors.dart';

class AudioRecordTile extends StatelessWidget {
  final AudioTask task;
  final bool fileExists;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onRetry;

  const AudioRecordTile({
    super.key,
    required this.task,
    required this.fileExists,
    required this.onOpen,
    required this.onDelete,
    required this.onRetry,
  });

  Color get _statusColor {
    switch (task.status) {
      case AudioTaskStatus.pending:
        return AppColors.statusPending;
      case AudioTaskStatus.exporting:
        return AppColors.statusExporting;
      case AudioTaskStatus.done:
        return AppColors.statusDone;
      case AudioTaskStatus.failed:
        return AppColors.statusFailed;
    }
  }

  String get _summary {
    final parts = <String>[
      task.title ?? '（无歌名）',
      task.artist ?? '—',
      task.album ?? '—',
    ];
    return parts.join(' · ');
  }

  /// 转换时长（输出区间长度）
  String get durationLabel =>
      TimeFormatter.formatDuration(task.trimEndMs - task.trimStartMs);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              task.status == AudioTaskStatus.exporting
                  ? '${task.statusText} ${task.progress}%'
                  : task.statusText,
              style: TextStyle(fontSize: 11, color: _statusColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _summary,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.isFailed && task.errorMessage != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.errorMessage!,
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$durationLabel · ${task.targetBitrateKbps} kbps',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          const SizedBox(width: 8),
          if (task.isCompleted && fileExists)
            IconButton(
              tooltip: '打开所在文件夹',
              icon: const Icon(Icons.folder_open, size: 18),
              onPressed: onOpen,
            ),
          if (task.isFailed)
            IconButton(
              tooltip: '回填参数重试',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: onRetry,
            ),
          IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: 重写音频页**

把 `lib/features/audio/audio_screen.dart` 全文替换为：

```dart
/// 音频提取页面
///
/// 视频 → MP3，封装封面图与歌名/歌手/专辑 ID3 标签。
/// 单页布局：上部表单区（预览 + 标签 + 区间 + 码率 + 输出），下部转换记录。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import '../../core/model/audio_task.dart';
import '../../core/model/video_item.dart';
import '../../core/services/explorer_service.dart';
import '../../ui/theme/colors.dart';
import '../editor/widgets/trim_range_control.dart';
import '../editor/widgets/video_preview_panel.dart';
import 'audio_viewmodel.dart';
import 'widgets/audio_bitrate_selector.dart';
import 'widgets/audio_record_tile.dart';
import 'widgets/audio_tag_panel.dart';

/// 步进按钮每次移动的毫秒数（音频场景用秒级，不是帧级）
const int kAudioStepMs = 1000;

class AudioScreen extends ConsumerStatefulWidget {
  const AudioScreen({super.key});

  @override
  ConsumerState<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends ConsumerState<AudioScreen> {
  final _previewKey = GlobalKey<VideoPreviewPanelState>();

  Future<void> _pickSourceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      final path = result?.files.firstOrNull?.path;
      if (path != null) {
        await ref.read(audioProvider.notifier).setSourceFile(path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择文件失败: $e')));
      }
    }
  }

  Future<void> _pickOutputDirectory() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择输出目录',
    );
    if (dir != null) {
      ref.read(audioProvider.notifier).setOutputDirectory(dir);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioProvider);
    final records = ref.watch(audioRecordsProvider);
    final notifier = ref.read(audioProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音频提取',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: state.isConverting ? null : _pickSourceFile,
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('选择视频'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: state.sourcePath == null
                    ? _buildEmptyState()
                    : _buildForm(state, notifier),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            _buildRecords(records, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            '选择一个视频开始提取音频',
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AudioState state, AudioViewModel notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 无音轨拦截条
        if (state.sourceInfo != null && !state.sourceInfo!.hasAudio) ...[
          _banner('该视频没有音频轨道，无法提取音频', AppColors.error),
          const SizedBox(height: 12),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 预览区
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 240,
                child: _buildPreview(state),
              ),
            ),
            const SizedBox(width: 16),
            // 标签区
            Expanded(
              flex: 2,
              child: AudioTagPanel(
                title: state.title,
                artist: state.artist,
                album: state.album,
                coverPath: state.coverPath,
                enabled: !state.isConverting,
                onTitleChanged: notifier.setTitle,
                onArtistChanged: notifier.setArtist,
                onAlbumChanged: notifier.setAlbum,
                onCoverChanged: notifier.setCoverPath,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 区间选择（复用编辑器组件）
        TrimRangeControl(
          durationMs: state.sourceDurationMs,
          trimStartMs: state.trimStartMs,
          trimEndMs: state.trimEndMs,
          currentPositionMs: 0,
          frameRate: 0,
          stepBackwardLabel: '快退 1s',
          stepForwardLabel: '快进 1s',
          onSetStart: () =>
              notifier.setTrimStart(_previewKey.currentState?.currentPositionMs ?? 0),
          onSetEnd: () =>
              notifier.setTrimEnd(_previewKey.currentState?.currentPositionMs ?? 0),
          onTrimStartManualChanged: notifier.setTrimStart,
          onTrimEndManualChanged: notifier.setTrimEnd,
          onSliderChanged: (ms) => _previewKey.currentState?.seekTo(ms.round()),
          onStepBackward: () => notifier.stepStart(-kAudioStepMs),
          onStepForward: () => notifier.stepStart(kAudioStepMs),
        ),

        const SizedBox(height: 16),

        AudioBitrateSelector(
          sourceInfo: state.sourceInfo,
          targetBitrateKbps: state.targetBitrateKbps,
          enabled: !state.isConverting,
          onChanged: notifier.setTargetBitrate,
        ),

        const SizedBox(height: 12),

        // 输出路径
        Row(
          children: [
            const SizedBox(
              width: 60,
              child: Text('输出到',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
            Expanded(
              child: Container(
                height: 36,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Text(
                  state.outputDirectory == null
                      ? '未设置输出目录'
                      : p.join(state.outputDirectory!, state.outputFileName),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: state.isConverting ? null : _pickOutputDirectory,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('更改'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (state.error != null) ...[
          _banner(state.error!, AppColors.error),
          const SizedBox(height: 12),
        ],
        if (state.success != null) ...[
          _banner(state.success!, AppColors.success),
          const SizedBox(height: 12),
        ],

        // 进度
        if (state.isConverting) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: state.progress / 100,
                    backgroundColor: AppColors.outline,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('${state.progress}%',
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // 开始 / 取消
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: state.isConverting
                ? () => notifier.cancelConversion()
                : (state.canConvert ? () => notifier.startConversion() : null),
            icon: state.isConverting
                ? const Icon(Icons.stop, size: 18)
                : state.isProbing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.music_note, size: 18),
            label: Text(state.isConverting
                ? '取消转换'
                : state.isProbing
                    ? '探测中…'
                    : '开始转换'),
            style: ElevatedButton.styleFrom(
              backgroundColor: state.isConverting
                  ? AppColors.error
                  : (state.canConvert ? AppColors.primary : AppColors.outline),
              foregroundColor: state.isConverting || state.canConvert
                  ? Colors.white
                  : AppColors.textTertiary,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(AudioState state) {
    // VideoPreviewPanel 需要 VideoItem；这里用最小字段构造，
    // 音频场景不关心分辨率/编码，只用到 path/name/duration。
    final video = VideoItem(
      id: 0,
      path: state.sourcePath!,
      name: state.sourceName ?? p.basename(state.sourcePath!),
      duration: state.sourceDurationMs,
      width: 0,
      height: 0,
      fileSize: 0,
      frameRate: 0,
      codec: '',
      importedAt: 0,
    );

    return VideoPreviewPanel(
      key: _previewKey,
      video: video,
      onPositionChanged: (_) {},
    );
  }

  Widget _banner(String message, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecords(
    AsyncValue<List<AudioTask>> records,
    AudioViewModel notifier,
  ) {
    return SizedBox(
      height: 180,
      child: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('读取记录失败: $e',
              style: const TextStyle(fontSize: 12, color: AppColors.error)),
        ),
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(
              child: Text('暂无转换记录',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            );
          }
          return ListView.separated(
            itemCount: tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              final outputPath = task.outputPath;
              return AudioRecordTile(
                task: task,
                fileExists: outputPath != null && File(outputPath).existsSync(),
                onOpen: () {
                  if (outputPath != null) {
                    ExplorerService.openFileLocation(outputPath);
                  }
                },
                onRetry: () => notifier.restoreFromTask(task),
                onDelete: () => _confirmDelete(task, notifier),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(AudioTask task, AudioViewModel notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除记录', style: TextStyle(fontSize: 16)),
        content: Text(
          '将删除这条记录${task.outputPath != null ? '，并删除已生成的 mp3 文件' : ''}。确定吗？',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await notifier.deleteRecord(task);
  }
}
```

- [ ] **Step 7: 给 ViewModel 加 deleteRecord**

Task 7 的 ViewModel 中补上记录删除方法（**页面不直接持有 Repository**，一律经 ViewModel）：

在 `lib/features/audio/audio_viewmodel.dart` 的 `AudioViewModel` 类中，`restoreFromTask` 方法之后新增：

```dart
  /// 删除一条记录，并尽力删除其产物文件
  Future<void> deleteRecord(AudioTask task) async {
    await _deleteFileQuietly(task.outputPath);
    await _repository.deleteTask(task.id);
  }
```

文件删除失败只记日志、不阻断记录删除——文件可能已被用户手动移走或占用，卡住记录删除反而更糟。

- [ ] **Step 8: 运行测试确认通过**

Run: `flutter test test/features/audio/audio_screen_test.dart`
Expected: PASS，2 个测试全绿

- [ ] **Step 9: 全量测试与静态分析**

Run: `flutter test && flutter analyze`
Expected: 全部 PASS；`No issues found!`

- [ ] **Step 10: 手动跑通**

Run: `flutter run -d windows`
Expected: 选一个有音轨的视频 → 源码率显示 → 填标签选封面 → 转出 mp3

- [ ] **Step 11: 提交**

```bash
git add lib/features/audio/
git commit -m "音频提取页面完整实现（表单 + 码率选择 + 转换记录）"
```

---

### Task 9: 手动验收与进度基准校准

自动化测试覆盖不到真实 ffmpeg 行为，这一任务专做端到端验收。

**Files:**
- Modify: 仅在验收发现问题时改动（可能涉及 `audio_viewmodel.dart` 的 `totalDurationMs`）
- 产出: 验收记录（写进 `docs/superpowers/plans/2026-09-18-audio-extract.md` 末尾或直接汇报）

- [ ] **Step 1: 准备素材**

准备一个 3 分钟以上、含音轨的 mp4（H.264 + AAC），以及一张 JPG 封面图。

- [ ] **Step 2: 核心功能验收**

Run: `flutter run -d windows`

逐条确认：

- [ ] 选视频 → 源码率显示为音轨码率（不出现「容器总码率」标注）→ 预览可播放
- [ ] **选视频 A → 播放几秒 → 再选视频 B → 预览正确切到 B（不残留 A、不崩溃、区间重置为 B 的全片）**
- [ ] **快速连续切换 3 个以上文件 → 最终预览停在第 3 个，无错乱**
- [ ] 拖动进度条调整位置 → 点「设定入点」「设定出点」正确写入
- [ ] 时间码输入框可手改，格式 `MM:SS.mmm` 生效
- [ ] 「快退 1s」「快进 1s」按 1 秒步进
- [ ] 填三个标签 + 选 JPG 封面 → 转换 → 记录列表出现该条

- [ ] **Step 3: 验证 ID3 标签与封面**

选一个已生成的 mp3，在项目目录下运行：

```bash
ffprobe -v error -show_format -show_streams "D:/path/to/output.mp3"
```

Expected:
- `format.tags.title` / `artist` / `album` 三项为所填内容
- `streams` 中存在 `codec_type=video`、`codec_name=mjpeg`、`disposition.attached_pic=1` 的流

- [ ] **Step 4: 验证 Windows 资源管理器可读封面**

在资源管理器里把该 mp3 切到「大图标」视图。
Expected: 显示封面缩略图（这是 ID3v2.3 决策的核心验证点）。若显示默认音乐图标，说明 ID3 版本或封面流有问题，需回查 Task 6 的命令参数。

- [ ] **Step 5: 校准进度基准**

观察整个转换过程中进度条数值变化。

Expected（设计预期）: 进度从 0 平滑增长到 100，结束时正好到 100，不早停也不超时。

若出现**进度长时间停在 0 然后突然跳到 100**，或**中途就显示 100 但进程仍在跑**：说明 `totalDurationMs` 的基准不对。修改 `lib/features/audio/audio_viewmodel.dart` 中的：

```dart
        totalDurationMs: duration,
```

改为传 `trimEnd`（源时间轴基准）：

```dart
        totalDurationMs: trimEnd,
```

重新跑一次确认进度恢复正常，然后提交：

```bash
git add lib/features/audio/audio_viewmodel.dart
git commit -m "校准音频转换进度基准"
```

- [ ] **Step 6: 边界场景验收**

- [ ] 不选封面转换 → ffprobe 验证无 video 流，标签正常
- [ ] 三个标签全留空转换 → 无 ID3 标签，文件名为源文件名
- [ ] 歌名填 `AC/DC: Live` → 文件名为 `AC_DC_ Live.mp3`，但 ffprobe 中 `title` 标签**仍是原样的 `AC/DC: Live`**
- [ ] 选一个无音轨的视频 → 错误条出现、按钮禁用
- [ ] 转换中途点「取消转换」→ 进程停止、历史列表不留该条记录、输出目录无半成品文件
- [ ] 出点改成与入点相同 → 按钮禁用，提示「出点必须大于入点」
- [ ] 重复转换同名歌名两次 → 第二次输出为 `歌名_1.mp3`，不覆盖
- [ ] 关闭 App 重开 → 转换记录仍在

- [ ] **Step 7: 验证完整版可恢复**

把 `lib/core/app_mode.dart` 的 `kAudioOnlyMode` 临时改为 `false`，运行：

Run: `flutter run -d windows`
Expected: 侧栏出现 5 个页签（音频/裁剪/H264 转码/视频分割/设置），启动落在「裁剪」，各视频页功能正常

确认后**改回 `true`** 再提交。

- [ ] **Step 8: 提交验收修正（如有）**

```bash
git add -A
git commit -m "音频提取功能验收修正"
```

若无任何改动则跳过此步。

- [ ] **Step 9: 递交枢纽执行报告**

在 `D:\Code\ai_project\reports\cutflow_flutter\` 下按 `templates/report-template.md` 格式新建任务完成报告，写明验收结果与遗留问题。

---

## 自检

### Spec 覆盖

| Spec 章节 | 覆盖任务 |
|---|---|
| 一、需求决策 1–10 | Task 1（决策 6/7）、Task 3（决策 8）、Task 5（决策 5）、Task 6（决策 9/10）、Task 8（决策 1/2/3/4） |
| 二、架构总览 / 复用点 | Task 1、Task 2、Task 8 |
| 三、数据模型 + 迁移 | Task 3、Task 4 |
| 四、FFmpeg 管线（探测/命令/进度基准/命名） | Task 5、Task 6、Task 9 Step 5 |
| 五、UI 布局（空态/无音轨拦截/标签/码率/记录） | Task 8 |
| 六、页签隐藏机制 | Task 1、Task 9 Step 7 |
| 七、错误处理与边界 | Task 7（校验/取消/清理）、Task 9 Step 6 |
| 八、测试（单测 + 手动验收清单） | Task 1/2/3/4/5/6/7/8 的单测 + Task 9 全部 |
| 九、影响范围与风险 | Task 1（导航）、Task 3（迁移测试）、Task 9 Step 5（进度基准） |

无遗漏章节。

### 类型一致性

- `AudioTaskStatus` 四值（`pending`/`exporting`/`done`/`failed`）在 Task 4 定义，Task 7、Task 8 使用，枚举名一致。
- `AudioSourceInfo` 的 `bitrateIsApproximate` 在 Task 5 定义，Task 7（`sourceInfo?.bitrateKbps`）与 Task 8（码率选择器文案）使用，字段名一致。
- `buildExtractMp3` 的具名参数在 Task 6 定义，Task 7 调用，参数名逐字一致。
- `FilenameSanitizer.sanitize` 在 Task 6 定义，Task 7 的 `outputFileName` 使用。
- `AudioRepository` 的方法名（`insertTask`/`getTaskById`/`deleteTask`/`updateTaskFull`/`watchAllTasks`）在 Task 4 定义，Task 7 使用，一致。
- `TrimRangeControl` 的两个新参数名 `stepBackwardLabel`/`stepForwardLabel` 在 Task 2 定义，Task 8 使用，一致。
- Task 7 的 `AudioState.copyWith` 使用哨兵常量 `_sentinel` 区分「未传」与「显式传 null」，是必要的——否则 `setCoverPath(null)` 无法清空封面。Task 1 的 `AudioScreen` 空壳与 Task 8 的完整页均保持无参构造，路由无需改动。

### 占位符扫描

计划中无 TBD / TODO / 「实现细节待定」/ 「类似 Task N」。每个代码步骤都给出了可直接落盘的完整实现。

### 与 Spec 的偏差（有意为之，实现时以本计划为准）

| 偏差 | 原因 |
|---|---|
| Spec 二章只列了 `TrimRangeControl` 一处共享组件适配；本计划**增加 `VideoPreviewPanel`** 的重载支持 | 勘察发现该组件未实现 `didUpdateWidget` 且 `_player` 为 `late final`，换文件时预览不刷新。音频页要反复换文件，不修则功能不可用 |
| Spec 七章原文「取消 → 任务回 PENDING」，本计划改为**取消即删除记录** | 单文件流程没有队列去承接 PENDING 任务，留一条永不执行的记录只会污染历史列表 |
| Spec 四章 4.3 称进度基准为「推演结论」，本计划标注为**已有先例** | `ExportService._processTask()` 已用 `trimEndMs - trimStartMs` 作基准，与裁剪工作流配合正常 |
| Spec 五章「重试」按钮，本计划实现为**回填表单** | 已在 spec 5.6 同步明确 |
