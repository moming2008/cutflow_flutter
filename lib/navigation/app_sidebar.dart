/// 应用侧栏导航组件
///
/// 深色 Slate 900 侧栏，包含 4 个导航目标：
/// 准备列表、转码队列、已转码列表、设置
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../main.dart';
import '../ui/theme/colors.dart';

/// 侧栏导航项数据
class _NavItem {
  final String label;
  final IconData icon;
  final IconData iconFilled;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconFilled,
  });
}

const _navItems = [
  _NavItem(
    label: '准备列表',
    icon: Icons.video_library_outlined,
    iconFilled: Icons.video_library,
  ),
  _NavItem(
    label: '转码队列',
    icon: Icons.queue_outlined,
    iconFilled: Icons.queue,
  ),
  _NavItem(
    label: '已转码',
    icon: Icons.check_circle_outline,
    iconFilled: Icons.check_circle,
  ),
  _NavItem(
    label: '设置',
    icon: Icons.settings_outlined,
    iconFilled: Icons.settings,
  ),
];

/// 侧栏 + 内容的整体布局容器
///
/// 接收 [StatefulNavigationShell]，根据当前 branch 索引高亮对应导航项，
/// 点击导航项调用 [shell.goBranch] 切换标签页。
class AppSidebar extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppSidebar({super.key, required this.shell});

  void _onItemTap(int index) {
    shell.goBranch(
      index,
      initialLocation: index == shell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 侧栏宽度: 窗口 25%，最小 200px，最大 280px
        final sidebarWidth = (constraints.maxWidth * 0.25)
            .clamp(200.0, 280.0);

        return Row(
          children: [
            SizedBox(
              width: sidebarWidth,
              child: _SidebarContent(
                selectedIndex: shell.currentIndex,
                onItemTap: _onItemTap,
              ),
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.outline,
            ),
            Expanded(child: shell),
          ],
        );
      },
    );
  }
}

/// 侧栏内容区域
class _SidebarContent extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemTap;

  const _SidebarContent({
    required this.selectedIndex,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // 顶部标题
          _SidebarHeader(),
          const SizedBox(height: 8),
          // 导航项列表
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = index == selectedIndex;
            return _SidebarNavItem(
              label: item.label,
              icon: isSelected ? item.iconFilled : item.icon,
              isSelected: isSelected,
              onTap: () => onItemTap(index),
            );
          }),
          const Spacer(),
          // 底部版本信息
          _SidebarFooter(),
        ],
      ),
    );
  }
}

/// 侧栏顶部标题
class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: const Text(
        'CutFlow',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// 单个导航项
class _SidebarNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          hoverColor: AppColors.sidebarSelectedBg.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.ease,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.sidebarSelectedBg
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                // 左侧选中指示条
                if (isSelected)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                // 内容
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? AppColors.sidebarSelectedIcon
                            : AppColors.sidebarIcon,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.sidebarSelectedText
                              : AppColors.sidebarText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 侧栏底部版本信息
class _SidebarFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        'v$kAppVersion',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: AppColors.sidebarIcon.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
