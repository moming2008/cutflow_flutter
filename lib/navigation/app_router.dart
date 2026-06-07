/// 应用路由配置
///
/// 使用 StatefulShellRoute.indexedStack 管理 4 个标签页：
/// - /preparation: 准备列表
/// - /queue: 待转码队列
/// - /completed: 已转码列表
/// - /settings: 设置
///
/// 编辑器以 showDialog() 弹窗形式打开，不作为路由存在。
library;

import 'package:go_router/go_router.dart';
import 'app_sidebar.dart';
import '../features/preparation/preparation_screen.dart';
import '../features/queue/queue_screen.dart';
import '../features/completed/completed_screen.dart';
import '../features/settings/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/preparation',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppSidebar(shell: shell),
      branches: [
        // 准备列表
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/preparation',
              builder: (context, state) => const PreparationScreen(),
            ),
          ],
        ),
        // 待转码队列
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/queue',
              builder: (context, state) => const QueueScreen(),
            ),
          ],
        ),
        // 已转码列表
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/completed',
              builder: (context, state) => const CompletedScreen(),
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
