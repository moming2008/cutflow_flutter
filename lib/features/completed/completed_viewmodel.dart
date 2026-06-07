/// 已转码列表 ViewModel
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/model/export_task.dart';
import '../../core/repository/export_repository.dart';
import '../../core/services/explorer_service.dart';
import '../../core/services/export_service.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

final completedProvider =
    StateNotifierProvider<CompletedViewModel, CompletedState>(
  (ref) {
    final vm = CompletedViewModel(ExportRepository(database));
    Future.microtask(() => vm.loadTasks());
    return vm;
  },
);

class CompletedState {
  final List<ExportTask> tasks;
  final bool isLoading;
  final bool showArchived;

  const CompletedState({
    this.tasks = const [],
    this.isLoading = false,
    this.showArchived = false,
  });

  CompletedState copyWith({
    List<ExportTask>? tasks,
    bool? isLoading,
    bool? showArchived,
  }) {
    return CompletedState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      showArchived: showArchived ?? this.showArchived,
    );
  }
}

class CompletedViewModel extends StateNotifier<CompletedState> {
  final ExportRepository _exportRepo;
  StreamSubscription<void>? _taskCompletedSub;

  CompletedViewModel(this._exportRepo) : super(const CompletedState()) {
    _taskCompletedSub = ExportService.taskCompletedStream.listen((_) {
      if (!state.showArchived) {
        log('Completed').i('Task completed, refreshing');
        loadTasks();
      }
    });
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true);
    try {
      final tasks = state.showArchived
          ? await _exportRepo.getArchivedTasks()
          : await _exportRepo.getCompletedTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
      log('Completed').i(
          'Loaded ${tasks.length} ${state.showArchived ? "archived" : "completed"} tasks');
    } catch (e) {
      log('Completed').e('Failed to load tasks', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  void setShowArchived(bool show) {
    if (state.showArchived == show) return;
    state = state.copyWith(showArchived: show);
    loadTasks();
  }

  Future<void> archiveTask(int id) async {
    log('Completed').i('Archiving task id=$id');
    await _exportRepo.archiveTask(id);
    await loadTasks();
  }

  Future<void> unarchiveTask(int id) async {
    log('Completed').i('Unarchiving task id=$id');
    await _exportRepo.unarchiveTask(id);
    await loadTasks();
  }

  Future<void> openFileLocation(ExportTask task) async {
    if (task.outputPath != null) {
      log('Completed').i('Opening file location: ${task.outputPath}');
      await ExplorerService.openFileLocation(task.outputPath!);
    }
  }

  Future<void> playVideo(ExportTask task) async {
    if (task.outputPath != null) {
      log('Completed').i('Playing video: ${task.outputPath}');
      await ExplorerService.playWithSystemPlayer(task.outputPath!);
    }
  }

  @override
  void dispose() {
    _taskCompletedSub?.cancel();
    super.dispose();
  }
}
