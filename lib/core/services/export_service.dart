/// 批量导出服务
///
/// 管理转码队列的执行流程：
/// - 状态: idle / running / paused
/// - 顺序处理 PENDING 任务
/// - 通过 Stream 广播进度事件
library;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../../core/ffmpeg/command_builder.dart';
import '../../core/ffmpeg/ffmpeg_engine.dart';
import '../../core/model/export_task.dart';
import '../../core/repository/app_settings_repository.dart';
import '../../core/repository/crop_preset_repository.dart';
import '../../core/repository/export_repository.dart';
import '../../core/repository/video_repository.dart';
import '../../core/util/logger.dart';

enum WorkerState { idle, running, paused }

/// 进度事件
class ExportProgressEvent {
  final int taskId;
  final int progress; // 0-100
  final String? error;

  const ExportProgressEvent({
    required this.taskId,
    required this.progress,
    this.error,
  });
}

class ExportService {
  static final StreamController<void> _taskInsertedController =
      StreamController<void>.broadcast();
  static final StreamController<void> _taskCompletedController =
      StreamController<void>.broadcast();

  /// 当有新任务被插入队列时触发，供 QueueViewModel 等监听以刷新列表
  static Stream<void> get taskInsertedStream =>
      _taskInsertedController.stream;

  /// 当有任务完成时触发，供 CompletedViewModel 等监听以刷新列表
  static Stream<void> get taskCompletedStream =>
      _taskCompletedController.stream;

  /// 由 EditorViewModel.submit() 调用，通知队列页面刷新
  static void notifyTaskInserted() {
    _taskInsertedController.add(null);
  }

  /// 由 _processTask() 调用，通知已完成页面刷新
  static void notifyTaskCompleted() {
    _taskCompletedController.add(null);
  }

  final ExportRepository _exportRepo;
  final VideoRepository _videoRepo;
  final AppSettingsRepository _settingsRepo;
  final CropPresetRepository _presetRepo;

  WorkerState _state = WorkerState.idle;
  FfmpegEngine? _currentEngine;
  bool _pauseRequested = false;

  final StreamController<ExportProgressEvent> _progressController =
      StreamController<ExportProgressEvent>.broadcast();

  /// 进度事件流
  Stream<ExportProgressEvent> get progressStream =>
      _progressController.stream;

  WorkerState get state => _state;

  ExportService({
    required ExportRepository exportRepo,
    required VideoRepository videoRepo,
    required AppSettingsRepository settingsRepo,
    required CropPresetRepository presetRepo,
  })  : _exportRepo = exportRepo,
        _videoRepo = videoRepo,
        _settingsRepo = settingsRepo,
        _presetRepo = presetRepo;

  /// 启动处理循环
  Future<void> start() async {
    if (_state == WorkerState.running) return;
    log('ExportService').i('Starting process loop');
    _state = WorkerState.running;
    _pauseRequested = false;
    await _processLoop();
  }

  /// 请求暂停（当前任务完成后停止）
  void pause() {
    log('ExportService').i('Pause requested');
    _pauseRequested = true;
    _state = WorkerState.paused;
  }

  /// 取消当前 FFmpeg 进程
  Future<void> cancel() async {
    log('ExportService').i('Cancel requested');
    _pauseRequested = true;
    _state = WorkerState.idle;
    await _currentEngine?.cancel();
  }

  /// 重置失败的任务为 PENDING
  Future<void> resetFailed() async {
    final tasks = await _exportRepo.getQueuedTasks();
    int count = 0;
    for (final task in tasks) {
      if (task.status == TaskStatus.failed) {
        await _exportRepo.updateTaskFull(
          id: task.id,
          status: 'PENDING',
          progress: 0,
          errorMessage: null,
        );
        count++;
      }
    }
    log('ExportService').i('Reset $count failed tasks');
  }

  /// 处理循环
  Future<void> _processLoop() async {
    log('ExportService').i('Process loop started');
    while (_state == WorkerState.running && !_pauseRequested) {
      final pendingTasks = await _exportRepo.getPendingTasks();
      log('ExportService').d('Found ${pendingTasks.length} pending tasks');
      if (pendingTasks.isEmpty) {
        log('ExportService').i('No pending tasks, process loop exiting');
        _state = WorkerState.idle;
        break;
      }

      for (final task in pendingTasks) {
        if (_pauseRequested) {
          log('ExportService').i('Pause detected, stopping task iteration');
          break;
        }
        await _processTask(task);
      }

      if (_pauseRequested) break;
    }

    if (_pauseRequested) {
      log('ExportService').i('Process loop paused');
      _state = WorkerState.paused;
    }
  }

  /// 处理单个任务
  Future<void> _processTask(ExportTask task) async {
    log('ExportService').i('Processing task id=${task.id}, output="${task.outputName}"');
    try {
      // 1. 状态 → PREPARING
      await _exportRepo.updateTaskStatus(task.id, TaskStatus.preparing);

      // 2. 获取源视频信息
      final video = await _videoRepo.getVideoById(task.sourceVideoId);
      if (video == null) {
        log('ExportService').e('Source video not found: videoId=${task.sourceVideoId}');
        await _exportRepo.updateTaskFull(
          id: task.id,
          status: 'FAILED',
          errorMessage: '源视频不存在',
        );
        _progressController.add(ExportProgressEvent(
          taskId: task.id,
          progress: 0,
          error: '源视频不存在',
        ));
        return;
      }

      // 3. 获取导出目录
      final exportDir = await _settingsRepo.getExportDirectory();
      if (exportDir == null) {
        log('ExportService').e('Export directory not set');
        await _exportRepo.updateTaskFull(
          id: task.id,
          status: 'FAILED',
          errorMessage: '未设置导出目录',
        );
        return;
      }

      // 4. 确保导出目录存在
      final dir = Directory(exportDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        log('ExportService').d('Created export directory: $exportDir');
      }

      // 5. 构建输出路径 (处理重名)
      String outputPath = p.join(exportDir, '${task.outputName}.mp4');
      int counter = 1;
      while (await File(outputPath).exists()) {
        outputPath = p.join(exportDir, '${task.outputName}_$counter.mp4');
        counter++;
      }
      log('ExportService').d('Output path: $outputPath');

      // 6. 构建 FFmpeg 命令
      final List<String> command;
      final CropParams? cropParams =
          await _resolveCropParams(task, video.width, video.height);

      if (cropParams != null) {
        log('ExportService').d('Building trim+crop command, crop=${cropParams.toFfmpegString()}');
        command = FfmpegCommandBuilder.buildTrimAndCrop(
          inputPath: video.path,
          outputPath: outputPath,
          startMs: task.trimStartMs,
          endMs: task.trimEndMs,
          cropParams: cropParams,
        );
      } else {
        log('ExportService').d('Building trim-only command (stream copy)');
        command = FfmpegCommandBuilder.buildTrimOnly(
          inputPath: video.path,
          outputPath: outputPath,
          startMs: task.trimStartMs,
          endMs: task.trimEndMs,
        );
      }

      // 7. 状态 → EXPORTING
      await _exportRepo.updateTaskStatus(task.id, TaskStatus.exporting);
      log('ExportService').i('Task ${task.id} exporting: trim=${task.trimStartMs}-${task.trimEndMs}ms');

      // 8. 执行 FFmpeg
      final engine = FfmpegEngine();
      _currentEngine = engine;

      final trimDuration = task.trimEndMs - task.trimStartMs;

      await for (final progress in engine.executeWithProgress(
        command: command,
        totalDurationMs: trimDuration,
      )) {
        if (progress.hasError) {
          log('ExportService').e('Task ${task.id} failed: ${progress.error}');
          await _exportRepo.updateTaskFull(
            id: task.id,
            status: 'FAILED',
            errorMessage: progress.error,
          );
          _progressController.add(ExportProgressEvent(
            taskId: task.id,
            progress: 0,
            error: progress.error,
          ));
          _currentEngine = null;
          return;
        }

        // 更新进度
        await _exportRepo.updateTaskProgress(task.id, progress.progress);
        _progressController.add(ExportProgressEvent(
          taskId: task.id,
          progress: progress.progress,
        ));
      }

      _currentEngine = null;

      // 9. 成功完成
      await _exportRepo.updateTaskFull(
        id: task.id,
        status: 'DONE',
        progress: 100,
        outputPath: outputPath,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _progressController.add(ExportProgressEvent(
        taskId: task.id,
        progress: 100,
      ));
      ExportService.notifyTaskCompleted();
      log('ExportService').i('Task ${task.id} completed: $outputPath');
    } catch (e) {
      log('ExportService').e('Error processing task ${task.id}', error: e);
      await _exportRepo.updateTaskFull(
        id: task.id,
        status: 'FAILED',
        errorMessage: e.toString(),
      );
      _progressController.add(ExportProgressEvent(
        taskId: task.id,
        progress: 0,
        error: e.toString(),
      ));
      _currentEngine = null;
    }
  }

  /// 解析裁切参数：自定义裁切 > 预设裁切 > 无裁切
  Future<CropParams?> _resolveCropParams(
      ExportTask task, int sourceW, int sourceH) async {
    // 1. 自定义裁切: cropSnapshot 格式 "WxH+X+Y"
    if (task.cropSnapshot != null) {
      final match = RegExp(r'^(\d+)x(\d+)\+(\d+)\+(\d+)$')
          .firstMatch(task.cropSnapshot!);
      if (match != null) {
        final w = int.parse(match.group(1)!);
        final h = int.parse(match.group(2)!);
        final x = int.parse(match.group(3)!);
        final y = int.parse(match.group(4)!);
        final evenW = w & ~1;
        final evenH = h & ~1;
        log('ExportService').d('Custom crop: $evenW x$evenH +$x +$y');
        return CropParams(
            cropW: evenW, cropH: evenH, offsetX: x, offsetY: y);
      }
    }

    // 2. 预设裁切: 直接使用预设存储的 W/H/X/Y 绝对像素值
    if (task.cropPresetId != null) {
      final preset = await _presetRepo.getPresetById(task.cropPresetId!);
      if (preset != null && preset.outputW > 0 && preset.outputH > 0) {
        final evenW = preset.outputW & ~1;
        final evenH = preset.outputH & ~1;
        log('ExportService').d(
            'Preset crop: "${preset.name}" ${evenW}x$evenH+${preset.offsetX}+${preset.offsetY}');
        return CropParams(
            cropW: evenW, cropH: evenH,
            offsetX: preset.offsetX, offsetY: preset.offsetY);
      }
    }

    // 3. 无裁切
    return null;
  }

  void dispose() {
    cancel();
    _progressController.close();
  }
}
