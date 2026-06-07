/// 队列状态栏
///
/// 底部状态栏，显示总进度条和统计信息。
library;

import 'package:flutter/material.dart';
import '../../../ui/theme/colors.dart';

class QueueStatusBar extends StatelessWidget {
  final int totalProgress;
  final int totalCount;
  final int completedCount;
  final int failedCount;

  const QueueStatusBar({
    super.key,
    required this.totalProgress,
    required this.totalCount,
    required this.completedCount,
    required this.failedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 总进度条
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? totalProgress / 100 : 0,
                backgroundColor: AppColors.outline,
                valueColor: AlwaysStoppedAnimation(
                  failedCount > 0 && completedCount == 0
                      ? AppColors.error
                      : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // 统计信息
          Expanded(
            flex: 2,
            child: Text(
              '总计:$totalCount  完成:$completedCount  失败:$failedCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
