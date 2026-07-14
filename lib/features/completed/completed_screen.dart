/// 已转码列表面板
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'completed_viewmodel.dart';
import 'widgets/completed_video_card.dart';
import 'widgets/completed_detail_drawer.dart';
import '../../ui/theme/colors.dart';

class CompletedPanel extends ConsumerStatefulWidget {
  const CompletedPanel({super.key});

  @override
  ConsumerState<CompletedPanel> createState() => _CompletedPanelState();
}

class _CompletedPanelState extends ConsumerState<CompletedPanel> {
  int? _selectedTaskId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(completedProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 已完成 / 已归档切换
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Align(
            alignment: Alignment.centerRight,
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
                setState(() => _selectedTaskId = null);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: state.tasks.isEmpty
                    ? _buildEmpty(state.showArchived)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: state.tasks.length,
                        itemBuilder: (context, index) {
                          final task = state.tasks[index];
                          return CompletedVideoCard(
                            task: task,
                            isArchived: state.showArchived,
                            isSelected: _selectedTaskId == task.id,
                            onTap: () =>
                                setState(() => _selectedTaskId = task.id),
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
              ),
              // 右侧详情抽屉
              if (_selectedTaskId != null)
                Builder(builder: (context) {
                  final task = state.tasks
                      .where((t) => t.id == _selectedTaskId)
                      .firstOrNull;
                  if (task == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedTaskId = null);
                    });
                    return const SizedBox.shrink();
                  }
                  return CompletedDetailDrawer(
                    task: task,
                    onClose: () =>
                        setState(() => _selectedTaskId = null),
                    onOpenLocation: task.outputPath != null
                        ? () => ref
                            .read(completedProvider.notifier)
                            .openFileLocation(task)
                        : null,
                    onPlay: task.outputPath != null
                        ? () => ref
                            .read(completedProvider.notifier)
                            .playVideo(task)
                        : null,
                    onArchive: !state.showArchived
                        ? () => ref
                            .read(completedProvider.notifier)
                            .archiveTask(task.id)
                        : null,
                    onUnarchive: state.showArchived
                        ? () => ref
                            .read(completedProvider.notifier)
                            .unarchiveTask(task.id)
                        : null,
                    isArchived: state.showArchived,
                  );
                }),
            ],
          ),
        ),
      ],
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
