/// 转码任务详情抽屉
library;

import 'package:flutter/material.dart';
import '../../../core/model/export_task.dart';
import '../../../core/util/time_formatter.dart';
import '../../../ui/theme/colors.dart';

class TaskDetailDrawer extends StatelessWidget {
  final ExportTask task;
  final int currentProgress;
  final String? currentError;
  final VoidCallback? onClose;

  const TaskDetailDrawer({
    super.key,
    required this.task,
    required this.currentProgress,
    this.currentError,
    this.onClose,
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
                  '任务详情',
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
                  _buildSection(
                    '裁剪范围',
                    '${TimeFormatter.formatDurationPrecise(task.trimStartMs)} → ${TimeFormatter.formatDurationPrecise(task.trimEndMs)}',
                  ),
                  _buildSection(
                    '剪辑时长',
                    TimeFormatter.formatDurationPrecise(task.trimEndMs - task.trimStartMs),
                  ),
                  _buildSection('裁切', _cropDescription()),
                  _buildSection('状态', task.statusText),
                  if (task.isProcessing) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: currentProgress / 100,
                        backgroundColor: AppColors.outline,
                        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentProgress%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                  if (task.isFailed && currentError != null)
                    _buildSection('错误', currentError!),
                  _buildSection('创建时间', _formatTimestamp(task.createdAt)),
                ],
              ),
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
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
