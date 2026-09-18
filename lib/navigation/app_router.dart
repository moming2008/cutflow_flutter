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
