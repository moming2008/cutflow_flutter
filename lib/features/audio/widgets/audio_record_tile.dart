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
