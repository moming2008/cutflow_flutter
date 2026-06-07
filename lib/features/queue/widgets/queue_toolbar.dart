/// 队列工具栏
///
/// 包含开始、暂停、重置失败按钮。
library;

import 'package:flutter/material.dart';
import '../../../core/services/export_service.dart';
import '../../../ui/theme/colors.dart';

class QueueToolbar extends StatelessWidget {
  final WorkerState workerState;
  final bool hasFailed;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResetFailed;

  const QueueToolbar({
    super.key,
    required this.workerState,
    required this.hasFailed,
    required this.onStart,
    required this.onPause,
    required this.onResetFailed,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = workerState == WorkerState.running;
    final isPaused = workerState == WorkerState.paused;
    final isIdle = workerState == WorkerState.idle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // 开始按钮
          ElevatedButton.icon(
            onPressed: isIdle || isPaused ? onStart : null,
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('开始'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.success.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 暂停按钮
          OutlinedButton.icon(
            onPressed: isRunning ? onPause : null,
            icon: const Icon(Icons.pause, size: 18),
            label: const Text('暂停'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              disabledForegroundColor: AppColors.warning.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 重置失败按钮
          if (hasFailed)
            OutlinedButton.icon(
              onPressed: onResetFailed,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重置失败'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const Spacer(),

          // 状态指示
          _WorkerStateIndicator(state: workerState),
        ],
      ),
    );
  }
}

class _WorkerStateIndicator extends StatelessWidget {
  final WorkerState state;

  const _WorkerStateIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, IconData icon) = switch (state) {
      WorkerState.idle => ('空闲', AppColors.textTertiary, Icons.circle_outlined),
      WorkerState.running => ('运行中', AppColors.success, Icons.play_circle_outline),
      WorkerState.paused => ('已暂停', AppColors.warning, Icons.pause_circle_outline),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
