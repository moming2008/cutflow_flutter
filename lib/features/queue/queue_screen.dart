/// 待转码队列页面
///
/// 显示队列中的任务列表，提供开始/暂停/重置操作，
/// 底部显示总进度和统计信息。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'queue_viewmodel.dart';
import 'widgets/queue_toolbar.dart';
import 'widgets/task_card.dart';
import 'widgets/queue_status_bar.dart';
import '../../ui/theme/colors.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(queueProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(queueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '待转码队列',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 工具栏
                QueueToolbar(
                  workerState: state.workerState,
                  hasFailed: state.failedCount > 0,
                  onStart: () =>
                      ref.read(queueProvider.notifier).startProcessing(),
                  onPause: () =>
                      ref.read(queueProvider.notifier).pauseProcessing(),
                  onResetFailed: () =>
                      ref.read(queueProvider.notifier).resetFailed(),
                ),

                // 任务列表
                Expanded(
                  child: state.tasks.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.tasks.length,
                          itemBuilder: (context, index) {
                            final task = state.tasks[index];
                            return TaskCard(
                              task: task,
                              currentProgress:
                                  state.taskProgress[task.id] ?? task.progress,
                              currentError: state.taskErrors[task.id] ??
                                  task.errorMessage,
                              onDelete: () => ref
                                  .read(queueProvider.notifier)
                                  .deleteTask(task.id),
                            );
                          },
                        ),
                ),

                // 底部状态栏
                if (state.tasks.isNotEmpty)
                  QueueStatusBar(
                    totalProgress: state.totalProgress,
                    totalCount: state.tasks.length,
                    completedCount: state.completedCount,
                    failedCount: state.failedCount,
                  ),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.queue_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            '队列为空',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '在准备列表中编辑视频后，任务会出现在这里',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
