/// 应用路由配置
///
/// 使用 StatefulShellRoute.indexedStack 管理 4 个标签页：
/// - /clip: 裁剪工作流（准备 / 队列 / 已转码 合并）
/// - /transcode: H264 转码
/// - /split: 视频分割（占位）
/// - /settings: 设置
///
/// 编辑器以 showDialog() 弹窗形式打开，不作为路由存在。
library;

import 'package:go_router/go_router.dart';
import 'app_sidebar.dart';
import '../features/clip/clip_screen.dart';
import '../features/transcode/transcode_screen.dart';
import '../features/split/split_screen.dart';
import '../features/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/clip',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppSidebar(shell: shell),
      branches: [
        // 裁剪工作流
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/clip',
              builder: (context, state) => const ClipScreen(),
            ),
          ],
        ),
        // H264 转码
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/transcode',
              builder: (context, state) => const TranscodeScreen(),
            ),
          ],
        ),
        // 视频分割
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/split',
              builder: (context, state) => const SplitScreen(),
            ),
          ],
        ),
        // 设置
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
