/// 队列任务卡片
///
/// 显示单个任务的输出名、状态、进度、错误信息和操作按钮。
/// 支持悬停提示、右键菜单、选中高亮。
library;

import 'package:flutter/material.dart';
import '../../../core/model/export_task.dart';
import '../../../core/util/time_formatter.dart';
import '../../../ui/theme/colors.dart';

class TaskCard extends StatelessWidget {
  final ExportTask task;
  final int currentProgress;
  final String? currentError;
  final VoidCallback onDelete;
  final VoidCallback? onReset;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onStartSingle;
  final bool canStartSingle;

  const TaskCard({
    super.key,
    required this.task,
    required this.currentProgress,
    this.currentError,
    required this.onDelete,
    this.onReset,
    this.isSelected = false,
    this.onTap,
    this.onRemove,
    this.onStartSingle,
    this.canStartSingle = false,
  });

  String get _tooltipMessage {
    final trim = '裁剪: ${TimeFormatter.formatDurationPrecise(task.trimStartMs)} → ${TimeFormatter.formatDurationPrecise(task.trimEndMs)}';
    final crop = task.cropSnapshot != null
        ? '自定义 ${task.cropSnapshot}'
        : task.cropPresetName != null
            ? '裁切: ${task.cropPresetName}'
            : '裁切: 原始';
    return '$trim\n$crop\n${task.statusText}';
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1,
      ),
      items: [
        PopupMenuItem(value: 'remove', child: Text('移除')),
        if (task.status == TaskStatus.pending || task.isFailed)
          PopupMenuItem(value: 'reset', child: Text('重置')),
        if (canStartSingle)
          PopupMenuItem(value: 'start', child: Text('开始')),
      ],
    ).then((value) {
      if (value == 'remove') onRemove?.call();
      if (value == 'reset') onReset?.call();
      if (value == 'start') onStartSingle?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltipMessage,
      waitDuration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: onTap,
        onSecondaryTapDown: (details) {
          _showContextMenu(context, details.globalPosition);
        },
        child: Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? AppColors.primary
                  : task.isFailed
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.outline,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${task.outputName}.mp4',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(task: task, currentProgress: currentProgress),
                  ],
                ),
                const SizedBox(height: 4),

                if (task.sourceVideoName != null)
                  Text(
                    '来源: ${task.sourceVideoName}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),

                // 进度条
                if (task.isProcessing || task.status == TaskStatus.pending)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: task.isProcessing && currentProgress == 0
                          ? null
                          : currentProgress / 100,
                      backgroundColor: AppColors.outline,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 4,
                    ),
                  ),

                // 错误信息
                if (task.isFailed && currentError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Error: $currentError',
                    style: const TextStyle(fontSize: 12, color: AppColors.error),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // 失败任务操作按钮
                if (task.isFailed) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('删除', style: TextStyle(fontSize: 12)),
                      ),
                      if (onReset != null) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: onReset,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('重新设置', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ExportTask task;
  final int currentProgress;

  const _StatusBadge({
    required this.task,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (task.status) {
      TaskStatus.pending => ('待处理', AppColors.statusPending),
      TaskStatus.preparing => ('准备中...', AppColors.statusExporting),
      TaskStatus.exporting => (
          currentProgress > 0 ? '导出中 $currentProgress%' : '处理中...',
          AppColors.statusExporting,
        ),
      TaskStatus.done => ('已完成', AppColors.statusDone),
      TaskStatus.failed => ('失败', AppColors.statusFailed),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withValues(alpha: 0.1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
