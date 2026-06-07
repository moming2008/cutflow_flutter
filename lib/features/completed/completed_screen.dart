/// 已转码列表页面
///
/// 显示已完成且未归档的转码任务。
/// 支持切换到已归档视图。
/// 支持打开文件位置、播放视频、归档和取消归档操作。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'completed_viewmodel.dart';
import 'widgets/completed_video_card.dart';
import '../../ui/theme/colors.dart';

class CompletedScreen extends ConsumerWidget {
  const CompletedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(completedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.showArchived ? '已归档列表' : '已转码列表',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('已完成')),
                ButtonSegment(value: true, label: Text('已归档')),
              ],
              selected: {state.showArchived},
              onSelectionChanged: (selection) {
                ref
                    .read(completedProvider.notifier)
                    .setShowArchived(selection.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.tasks.isEmpty
              ? _buildEmpty(state.showArchived)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: state.tasks.length,
                  itemBuilder: (context, index) {
                    final task = state.tasks[index];
                    return CompletedVideoCard(
                      task: task,
                      isArchived: state.showArchived,
                      onOpenLocation: () => ref
                          .read(completedProvider.notifier)
                          .openFileLocation(task),
                      onPlay: () => ref
                          .read(completedProvider.notifier)
                          .playVideo(task),
                      onArchive: state.showArchived
                          ? null
                          : () => ref
                              .read(completedProvider.notifier)
                              .archiveTask(task.id),
                      onUnarchive: state.showArchived
                          ? () => ref
                              .read(completedProvider.notifier)
                              .unarchiveTask(task.id)
                          : null,
                    );
                  },
                ),
    );
  }

  Widget _buildEmpty(bool showArchived) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showArchived ? Icons.archive_outlined : Icons.check_circle_outline,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            showArchived ? '暂无已归档的转码' : '暂无已完成的转码',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showArchived ? '归档后的转码任务会显示在这里' : '转码完成后会显示在这里',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
