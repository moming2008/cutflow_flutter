/// 已转码任务详情抽屉
library;

import 'package:flutter/material.dart';
import '../../../core/model/export_task.dart';
import '../../../core/util/time_formatter.dart';
import '../../../ui/theme/colors.dart';

class CompletedDetailDrawer extends StatelessWidget {
  final ExportTask task;
  final VoidCallback? onClose;
  final VoidCallback? onOpenLocation;
  final VoidCallback? onPlay;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;
  final bool isArchived;

  const CompletedDetailDrawer({
    super.key,
    required this.task,
    this.onClose,
    this.onOpenLocation,
    this.onPlay,
    this.onArchive,
    this.onUnarchive,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.outline, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              children: [
                const Text(
                  '转码详情',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
          // 内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('输出文件', '${task.outputName}.mp4'),
                  if (task.sourceVideoName != null)
                    _buildSection('源视频', task.sourceVideoName!),
                  if (task.outputPath != null)
                    _buildSection('输出路径', task.outputPath!),
                  _buildSection(
                    '裁剪范围',
                    '${TimeFormatter.formatDurationPrecise(task.trimStartMs)} → ${TimeFormatter.formatDurationPrecise(task.trimEndMs)}',
                  ),
                  _buildSection(
                    '剪辑时长',
                    TimeFormatter.formatDurationPrecise(
                        task.trimEndMs - task.trimStartMs),
                  ),
                  _buildSection('裁切', _cropDescription()),
                  _buildSection('状态', isArchived ? '已归档' : '已完成'),
                  if (task.completedAt != null)
                    _buildSection(
                        '完成时间', _formatTimestamp(task.completedAt!)),
                  _buildSection('创建时间', _formatTimestamp(task.createdAt)),
                ],
              ),
            ),
          ),
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onOpenLocation != null)
                  IconButton(
                    icon: const Icon(Icons.folder_outlined, size: 20),
                    onPressed: onOpenLocation,
                    tooltip: '打开所在位置',
                    color: AppColors.textSecondary,
                  ),
                if (onPlay != null)
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    onPressed: onPlay,
                    tooltip: '播放',
                    color: AppColors.textSecondary,
                  ),
                const Spacer(),
                if (onArchive != null)
                  OutlinedButton.icon(
                    onPressed: onArchive,
                    icon: const Icon(Icons.archive_outlined, size: 16),
                    label: const Text('归档'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.outline),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                if (onUnarchive != null)
                  OutlinedButton.icon(
                    onPressed: onUnarchive,
                    icon: const Icon(Icons.unarchive_outlined, size: 16),
                    label: const Text('取消归档'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _cropDescription() {
    if (task.cropSnapshot != null) return '自定义 ${task.cropSnapshot}';
    if (task.cropPresetName != null) return task.cropPresetName!;
    return '原始（无裁切）';
  }

  String _formatTimestamp(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
