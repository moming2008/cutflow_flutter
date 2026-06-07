/// 待转码队列页面
///
/// 显示队列中的任务列表，提供开始/暂停/重置操作，
/// 底部显示总进度和统计信息。
/// 支持任务选中查看详情抽屉、右键菜单操作。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'queue_viewmodel.dart';
import 'widgets/queue_toolbar.dart';
import 'widgets/task_card.dart';
import 'widgets/queue_status_bar.dart';
import 'widgets/task_detail_drawer.dart';
import '../editor/editor_dialog.dart';
import '../../core/model/export_task.dart';
import '../../core/services/export_service.dart';
import '../../ui/theme/colors.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  int? _selectedTaskId;

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
          : Row(
              children: [
                // 左侧主内容
                Expanded(
                  child: Column(
                    children: [
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
                                    isSelected: _selectedTaskId == task.id,
                                    onTap: () =>
                                        setState(() => _selectedTaskId = task.id),
                                    onDelete: () => ref
                                        .read(queueProvider.notifier)
                                        .deleteTask(task.id),
                                    onRemove: () =>
                                        _confirmRemove(context, task.id),
                                    onReset: () =>
                                        _resetTask(context, task.id),
                                    onStartSingle: state.workerState == WorkerState.idle &&
                                        task.status == TaskStatus.pending
                                    ? () => ref
                                        .read(queueProvider.notifier)
                                        .startSingleTask(task.id)
                                    : null,
                                    canStartSingle:
                                        state.workerState == WorkerState.idle &&
                                        task.status == TaskStatus.pending,
                                  );
                                },
                              ),
                      ),

                      if (state.tasks.isNotEmpty)
                        QueueStatusBar(
                          totalProgress: state.totalProgress,
                          totalCount: state.tasks.length,
                          completedCount: state.completedCount,
                          failedCount: state.failedCount,
                        ),
                    ],
                  ),
                ),

                // 右侧详情抽屉
                if (_selectedTaskId != null)
                  Builder(builder: (context) {
                    final task = state.tasks
                        .where((t) => t.id == _selectedTaskId)
                        .firstOrNull;
                    if (task == null) {
                      // 任务已不存在，关闭抽屉
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _selectedTaskId = null);
                      });
                      return const SizedBox.shrink();
                    }
                    return TaskDetailDrawer(
                      task: task,
                      currentProgress:
                          state.taskProgress[task.id] ?? task.progress,
                      currentError:
                          state.taskErrors[task.id] ?? task.errorMessage,
                      onClose: () =>
                          setState(() => _selectedTaskId = null),
                    );
                  }),
              ],
            ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, int taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认移除'),
        content: const Text('确定要从队列中移除该任务吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(queueProvider.notifier).removeTask(taskId);
      if (_selectedTaskId == taskId) {
        setState(() => _selectedTaskId = null);
      }
    }
  }

  Future<void> _resetTask(BuildContext context, int taskId) async {
    final videoId =
        await ref.read(queueProvider.notifier).resetTask(taskId);
    if (videoId == null || !mounted) return;
    if (_selectedTaskId == taskId) {
      setState(() => _selectedTaskId = null);
    }
    if (!context.mounted) return;
    final result = await EditorDialog.show(context, videoId);
    if (result == true) {
      ref.read(queueProvider.notifier).loadTasks();
    }
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
