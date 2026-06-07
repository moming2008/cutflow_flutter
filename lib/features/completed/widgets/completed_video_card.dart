/// 已转码视频卡片
library;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/model/export_task.dart';
import '../../../ui/theme/colors.dart';

class CompletedVideoCard extends StatelessWidget {
  final ExportTask task;
  final bool isArchived;
  final VoidCallback onOpenLocation;
  final VoidCallback onPlay;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  const CompletedVideoCard({
    super.key,
    required this.task,
    this.isArchived = false,
    required this.onOpenLocation,
    required this.onPlay,
    this.onArchive,
    this.onUnarchive,
  });

  String get _formattedDate {
    if (task.completedAt == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm')
        .format(DateTime.fromMillisecondsSinceEpoch(task.completedAt!));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isArchived ? AppColors.textTertiary : AppColors.success)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isArchived ? Icons.archive : Icons.check_circle,
                color: isArchived ? AppColors.textTertiary : AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${task.outputName}.mp4',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (task.sourceVideoName != null) ...[
                        Expanded(
                          child: Text(
                            '来源: ${task.sourceVideoName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            IconButton(
              icon: const Icon(Icons.folder_outlined, size: 18),
              onPressed: task.outputPath != null ? onOpenLocation : null,
              tooltip: '打开所在位置',
              color: AppColors.textSecondary,
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline, size: 18),
              onPressed: task.outputPath != null ? onPlay : null,
              tooltip: '播放',
              color: AppColors.textSecondary,
            ),
            if (onArchive != null)
              IconButton(
                icon: const Icon(Icons.archive_outlined, size: 18),
                onPressed: onArchive,
                tooltip: '归档',
                color: AppColors.textTertiary,
              ),
            if (onUnarchive != null)
              IconButton(
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                onPressed: onUnarchive,
                tooltip: '取消归档',
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
