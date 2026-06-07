/// 待转码队列 ViewModel
///
/// 管理队列中的任务列表、导出服务状态和进度跟踪。
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/export_task.dart';
import '../../core/repository/crop_preset_repository.dart';
import '../../core/repository/export_repository.dart';
import '../../core/repository/video_repository.dart';
import '../../core/repository/app_settings_repository.dart';
import '../../core/services/export_service.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final service = ExportService(
    exportRepo: ExportRepository(database),
    videoRepo: VideoRepository(database),
    settingsRepo: AppSettingsRepository(database),
    presetRepo: CropPresetRepository(database),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final queueProvider =
    StateNotifierProvider<QueueViewModel, QueueState>(
  (ref) {
    final vm = QueueViewModel(
      exportRepo: ExportRepository(database),
      exportService: ref.watch(exportServiceProvider),
    );
    // 初始加载
    Future.microtask(() => vm.loadTasks());
    return vm;
  },
);

class QueueState {
  final List<ExportTask> tasks;
  final WorkerState workerState;
  final Map<int, int> taskProgress; // taskId -> progress
  final Map<int, String> taskErrors; // taskId -> errorMessage
  final bool isLoading;

  const QueueState({
    this.tasks = const [],
    this.workerState = WorkerState.idle,
    this.taskProgress = const {},
    this.taskErrors = const {},
    this.isLoading = false,
  });

  int get completedCount =>
      tasks.where((t) => t.status == TaskStatus.done).length;
  int get failedCount =>
      tasks.where((t) => t.status == TaskStatus.failed).length;
  int get pendingCount =>
      tasks.where((t) => t.status == TaskStatus.pending).length;

  /// 总进度 (所有任务的平均进度)
  int get totalProgress {
    if (tasks.isEmpty) return 0;
    final total = tasks.fold<int>(0, (sum, t) {
      if (t.status == TaskStatus.done) return sum + 100;
      if (t.status == TaskStatus.failed) return sum;
      return sum + (taskProgress[t.id] ?? t.progress);
    });
    return total ~/ tasks.length;
  }

  QueueState copyWith({
    List<ExportTask>? tasks,
    WorkerState? workerState,
    Map<int, int>? taskProgress,
    Map<int, String>? taskErrors,
    bool? isLoading,
  }) {
    return QueueState(
      tasks: tasks ?? this.tasks,
      workerState: workerState ?? this.workerState,
      taskProgress: taskProgress ?? this.taskProgress,
      taskErrors: taskErrors ?? this.taskErrors,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class QueueViewModel extends StateNotifier<QueueState> {
  final ExportRepository _exportRepo;
  final ExportService _exportService;
  StreamSubscription<ExportProgressEvent>? _progressSub;
  StreamSubscription<void>? _taskInsertedSub;
  Timer? _refreshTimer;

  QueueViewModel({
    required ExportRepository exportRepo,
    required ExportService exportService,
  })  : _exportRepo = exportRepo,
        _exportService = exportService,
        super(const QueueState()) {
    _listenToProgress();
    _listenToTaskInserted();
  }

  void _listenToTaskInserted() {
    _taskInsertedSub = ExportService.taskInsertedStream.listen((_) {
      log('Queue').i('New task inserted, refreshing');
      loadTasks();
    });
  }

  void _listenToProgress() {
    _progressSub = _exportService.progressStream.listen((event) async {
      // 更新进度映射
      final progress = Map<int, int>.from(state.taskProgress);
      progress[event.taskId] = event.progress;

      final errors = Map<int, String>.from(state.taskErrors);
      if (event.error != null) {
        errors[event.taskId] = event.error!;
        log('Queue').w('Task ${event.taskId} error: ${event.error}');
      } else {
        errors.remove(event.taskId);
      }

      state = state.copyWith(
        taskProgress: progress,
        taskErrors: errors,
        workerState: _exportService.state,
      );

      // 任务完成时刷新列表
      if (event.progress >= 100 || event.error != null) {
        log('Queue').i('Task ${event.taskId} finished (progress=${event.progress}), refreshing');
        await loadTasks();
      }
    });
  }

  /// 加载任务列表
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final tasks = await _exportRepo.getQueuedTasks();
      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        workerState: _exportService.state,
      );
      log('Queue').i('Loaded ${tasks.length} tasks');
    } catch (e) {
      log('Queue').e('Failed to load tasks', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  /// 开始处理
  Future<void> startProcessing() async {
    log('Queue').i('Start processing requested, ${state.pendingCount} pending tasks');
    state = state.copyWith(workerState: WorkerState.running);
    await _exportService.start();
    await loadTasks();
  }

  /// 暂停处理
  void pauseProcessing() {
    log('Queue').i('Pause processing requested');
    _exportService.pause();
    state = state.copyWith(workerState: WorkerState.paused);
  }

  /// 重置失败任务
  Future<void> resetFailed() async {
    log('Queue').i('Reset failed tasks requested, ${state.failedCount} failed');
    await _exportService.resetFailed();
    await loadTasks();
  }

  /// 删除任务
  Future<void> deleteTask(int id) async {
    log('Queue').i('Deleting task id=$id');
    await _exportRepo.deleteTask(id);
    await loadTasks();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _taskInsertedSub?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
