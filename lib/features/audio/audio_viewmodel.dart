/// 音频提取页面 ViewModel
///
/// 编排「选文件 → 探测音轨 → 选区间 → 填标签 → 转换 → 入库」全流程。
/// 单文件串行执行，同一时刻至多一个转换在跑。
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/ffmpeg/audio_metadata_probe.dart';
import '../../core/ffmpeg/command_builder.dart';
import '../../core/ffmpeg/ffmpeg_engine.dart';
import '../../core/model/audio_source_info.dart';
import '../../core/model/audio_task.dart';
import '../../core/repository/app_settings_repository.dart';
import '../../core/repository/audio_repository.dart';
import '../../core/util/filename_sanitizer.dart';
import '../../core/util/logger.dart';
import '../../main.dart';

/// 目标码率档位（kbps）
const List<int> kAudioBitrateOptions = [128, 160, 192, 256, 320];

/// 上次选择的码率在 AppSettings 中的键
const String kAudioTargetBitrateKey = 'audio_target_bitrate';

/// 音频页状态
class AudioState {
  final String? sourcePath;
  final String? sourceName;
  final int sourceDurationMs;
  final int trimStartMs;
  final int trimEndMs;
  final String title;
  final String artist;
  final String album;
  final String? coverPath;
  final int targetBitrateKbps;
  final String? outputDirectory;
  final AudioSourceInfo? sourceInfo; // null = 尚未探测/探测中
  final bool isProbing;
  final bool isConverting;
  final int progress;
  final String? error;
  final String? success;

  const AudioState({
    this.sourcePath,
    this.sourceName,
    this.sourceDurationMs = 0,
    this.trimStartMs = 0,
    this.trimEndMs = 0,
    this.title = '',
    this.artist = '',
    this.album = '',
    this.coverPath,
    this.targetBitrateKbps = 320,
    this.outputDirectory,
    this.sourceInfo,
    this.isProbing = false,
    this.isConverting = false,
    this.progress = 0,
    this.error,
    this.success,
  });

  /// 阻断转换的原因；null = 可以转换
  String? get blockingError {
    if (sourcePath == null) return '请先选择视频文件';
    if (sourceInfo != null && !sourceInfo!.hasAudio) {
      return '该视频没有音频轨道，无法提取音频';
    }
    if (trimEndMs <= trimStartMs) return '出点必须大于入点';
    return null;
  }

  bool get canConvert =>
      blockingError == null && !isConverting && !isProbing;

  /// 输出文件名：歌名优先，回退源文件名；均经非法字符清洗
  String get outputFileName {
    final trimmed = title.trim();
    final raw = trimmed.isNotEmpty
        ? trimmed
        : p.basenameWithoutExtension(sourceName ?? '');
    return '${FilenameSanitizer.sanitize(raw)}.mp3';
  }

  AudioState copyWith({
    Object? sourcePath = _sentinel,
    Object? sourceName = _sentinel,
    int? sourceDurationMs,
    int? trimStartMs,
    int? trimEndMs,
    String? title,
    String? artist,
    String? album,
    Object? coverPath = _sentinel,
    int? targetBitrateKbps,
    Object? outputDirectory = _sentinel,
    Object? sourceInfo = _sentinel,
    bool? isProbing,
    bool? isConverting,
    int? progress,
    Object? error = _sentinel,
    Object? success = _sentinel,
  }) {
    return AudioState(
      sourcePath:
          sourcePath == _sentinel ? this.sourcePath : sourcePath as String?,
      sourceName:
          sourceName == _sentinel ? this.sourceName : sourceName as String?,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverPath: coverPath == _sentinel ? this.coverPath : coverPath as String?,
      targetBitrateKbps: targetBitrateKbps ?? this.targetBitrateKbps,
      outputDirectory: outputDirectory == _sentinel
          ? this.outputDirectory
          : outputDirectory as String?,
      sourceInfo: sourceInfo == _sentinel
          ? this.sourceInfo
          : sourceInfo as AudioSourceInfo?,
      isProbing: isProbing ?? this.isProbing,
      isConverting: isConverting ?? this.isConverting,
      progress: progress ?? this.progress,
      error: error == _sentinel ? this.error : error as String?,
      success: success == _sentinel ? this.success : success as String?,
    );
  }
}

/// copyWith 中用于区分「不传」与「显式传 null」的哨兵
const Object _sentinel = Object();

class AudioViewModel extends StateNotifier<AudioState> {
  final AudioRepository _repository;
  final AppSettingsRepository _settings;

  FfmpegEngine? _currentEngine;
  int? _currentTaskId;

  /// 本次转换是否已被用户取消
  ///
  /// 由本 VM 自己记账，**不**解析引擎的错误文案来判断「是不是取消」：
  /// 引擎在取消时的报错并不稳定（实测可能报成 null check 之类的执行错误），
  /// 若据此判定，取消就会被误当成转换失败。
  bool _cancelRequested = false;

  /// 本次转换**去重后**的实际输出路径（取消/失败时据此清理半成品文件）
  String? _currentOutputPath;

  AudioViewModel(this._repository, this._settings)
      : super(const AudioState()) {
    _restorePreferences();
  }

  /// 读取记忆的目标码率与默认输出目录
  Future<void> _restorePreferences() async {
    try {
      final savedBitrate = await _settings.getSetting(kAudioTargetBitrateKey);
      final bitrate = int.tryParse(savedBitrate ?? '');
      final outputDir = await _settings.getExportDirectory();
      state = state.copyWith(
        targetBitrateKbps:
            bitrate != null && kAudioBitrateOptions.contains(bitrate)
                ? bitrate
                : null,
        outputDirectory: outputDir,
      );
    } catch (e) {
      log('AudioVM').e('Failed to restore preferences', error: e);
    }
  }

  /// 选择源视频 → 重置区间 → 异步探测音轨
  ///
  /// 刻意**不**触碰 `isConverting`：转换途中换源不应改写正在进行的那次转换的
  /// 标志位，否则 [canConvert] 会重新变为 true 而允许再起一个 ffmpeg。
  /// 该标志只由 [startConversion] 自行收尾。
  Future<void> setSourceFile(String path) async {
    final name = p.basename(path);
    state = state.copyWith(
      sourcePath: path,
      sourceName: name,
      sourceDurationMs: 0,
      trimStartMs: 0,
      trimEndMs: 0,
      sourceInfo: null,
      isProbing: true,
      progress: 0,
      error: null,
      success: null,
    );
    log('AudioVM').i('Source selected: $path');
    await _probeSource(path);
  }

  /// 探测 [path] 的音轨信息并回填状态
  ///
  /// [setSourceFile] 与 [restoreFromTask] 共用。探测期间用户可能又换了文件、
  /// 或又恢复了另一条记录，故写入前校验路径仍是当初那一个。
  ///
  /// [keepTrimEndMs] 非空时保留该出点（用于从历史记录回填重试，
  /// 避免把用户原先选的区间悄悄改成全片），但仍会按探测到的
  /// 实际时长做钳制，以防源文件已被替换成更短的版本。
  Future<void> _probeSource(String path, {int? keepTrimEndMs}) async {
    final info = await AudioMetadataProbe.probe(path);
    if (!mounted || state.sourcePath != path) return;

    state = state.copyWith(
      sourceInfo: info,
      isProbing: false,
      sourceDurationMs: info.durationMs,
      trimEndMs: resolveTrimEndMs(
        durationMs: info.durationMs,
        keepTrimEndMs: keepTrimEndMs,
      ),
    );
  }

  /// 解析出点：默认取全片时长；[keepTrimEndMs] 非空时保留调用方给定值，
  /// 但一律钳制在实际时长内（防源文件被替换成更短的版本）。
  /// 探测不到时长（<= 0）时返回 0。
  ///
  /// 抽成纯函数是为了让「保留 / 钳制 / 兜底」三条规则可被单独断言：
  /// `clamp` 的上下界一旦写反（`.clamp(durationMs, 0)`）照样能编译通过，
  /// 只在运行时抛 `ArgumentError`，靠调用方无法察觉。
  static int resolveTrimEndMs({required int durationMs, int? keepTrimEndMs}) {
    if (durationMs <= 0) return 0;
    return (keepTrimEndMs ?? durationMs).clamp(0, durationMs);
  }

  void setTrimStart(int ms) {
    final clamped = ms.clamp(0, state.sourceDurationMs);
    if (clamped == state.trimStartMs) return;
    state = state.copyWith(trimStartMs: clamped, error: null);
  }

  void setTrimEnd(int ms) {
    final clamped = ms.clamp(0, state.sourceDurationMs);
    if (clamped == state.trimEndMs) return;
    state = state.copyWith(trimEndMs: clamped, error: null);
  }

  void setTitle(String value) => state = state.copyWith(title: value);
  void setArtist(String value) => state = state.copyWith(artist: value);
  void setAlbum(String value) => state = state.copyWith(album: value);

  void setCoverPath(String? path) =>
      state = state.copyWith(coverPath: path, error: null);

  Future<void> setTargetBitrate(int kbps) async {
    state = state.copyWith(targetBitrateKbps: kbps);
    try {
      await _settings.setSetting(kAudioTargetBitrateKey, kbps.toString());
    } catch (e) {
      log('AudioVM').e('Failed to persist bitrate', error: e);
    }
  }

  void setOutputDirectory(String dir) =>
      state = state.copyWith(outputDirectory: dir);

  void clearMessages() =>
      state = state.copyWith(error: null, success: null);

  /// 开始转换
  Future<void> startConversion() async {
    // 同一时刻至多一个转换在跑。这条不变式不能依赖界面禁用按钮，
    // 否则转换途中换源 → 探测完成 → canConvert 重新为 true → 起第二个 ffmpeg，
    // 而 _currentEngine/_currentTaskId 会被覆盖，前一个进程从此无法取消。
    if (state.isConverting) {
      log('AudioVM').w('Conversion already running, ignoring start request');
      return;
    }

    final blocked = state.blockingError;
    if (blocked != null) {
      state = state.copyWith(error: blocked);
      return;
    }

    final sourcePath = state.sourcePath!;
    final outputDir = state.outputDirectory;
    if (outputDir == null || outputDir.isEmpty) {
      state = state.copyWith(error: '未设置输出目录');
      return;
    }

    _cancelRequested = false; // 本次运行的取消标志复位
    state = state.copyWith(
      isConverting: true,
      progress: 0,
      error: null,
      success: null,
    );

    final trimStart = state.trimStartMs;
    final trimEnd = state.trimEndMs;
    final duration = trimEnd - trimStart;

    // 转换是否已产出文件：DONE 落库失败时据此区分
    // 「转换本身失败」与「转换成功但记录没写成」
    String? producedOutputPath;

    try {
      // 1. 源文件二次校验
      if (!await File(sourcePath).exists()) {
        state = state.copyWith(isConverting: false, error: '源文件不存在');
        return;
      }

      // 2. 封面文件校验（选了才校验）
      final coverPath = state.coverPath;
      if (coverPath != null &&
          coverPath.isNotEmpty &&
          !await File(coverPath).exists()) {
        state = state.copyWith(isConverting: false, error: '封面图片不存在，请重新选择');
        return;
      }

      // 3. 确保输出目录存在
      final dir = Directory(outputDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 4. 输出路径去重
      final outputPath = await resolveOutputPath(outputDir, state.outputFileName);

      // 5. 入库（状态 PENDING）
      final taskId = await _repository.insertTask(AudioTask(
        id: 0,
        sourcePath: sourcePath,
        sourceName: state.sourceName ?? p.basename(sourcePath),
        sourceDurationMs: state.sourceDurationMs,
        sourceBitrateKbps: state.sourceInfo?.bitrateKbps,
        trimStartMs: trimStart,
        trimEndMs: trimEnd,
        title: _nullIfBlank(state.title),
        artist: _nullIfBlank(state.artist),
        album: _nullIfBlank(state.album),
        coverPath: coverPath,
        targetBitrateKbps: state.targetBitrateKbps,
        outputName: state.outputFileName,
        status: AudioTaskStatus.pending,
        progress: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
      _currentTaskId = taskId;
      _currentOutputPath = outputPath;

      // 6. 构建命令
      final command = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: sourcePath,
        outputPath: outputPath,
        startMs: trimStart,
        endMs: trimEnd,
        targetBitrateKbps: state.targetBitrateKbps,
        coverPath: coverPath,
        title: state.title,
        artist: state.artist,
        album: state.album,
      );

      await _repository.updateTaskFull(
          id: taskId, status: 'EXPORTING', progress: 0);

      // 7. 执行（进度基准 = 输出时长）
      final engine = FfmpegEngine();
      _currentEngine = engine;

      await for (final progress in engine.executeWithProgress(
        command: command,
        totalDurationMs: duration,
      )) {
        if (!mounted) return;

        if (progress.hasError) {
          _currentEngine = null;
          // 以本 VM 的记账为准，不看 progress.error 的文案
          final cancelled = _cancelRequested;
          final message =
              cancelled ? '已取消' : '转换失败: ${progress.error}';
          await _handleFailure(
            taskId: taskId,
            outputPath: outputPath,
            message: message,
            cancelled: cancelled,
          );
          return;
        }

        state = state.copyWith(progress: progress.progress);
        await _repository.updateTaskFull(
            id: taskId, progress: progress.progress);
      }

      _currentEngine = null;
      _currentTaskId = null;
      _currentOutputPath = null;
      producedOutputPath = outputPath; // 流循环正常结束即文件已产出

      await _repository.updateTaskFull(
        id: taskId,
        status: 'DONE',
        progress: 100,
        outputPath: outputPath,
        completedAt: DateTime.now().millisecondsSinceEpoch,
      );

      state = state.copyWith(
        isConverting: false,
        progress: 100,
        success: '转换完成: $outputPath',
      );
      log('AudioVM').i('Conversion done: $outputPath');
    } catch (e) {
      _currentEngine = null;
      log('AudioVM').e('Conversion failed', error: e);
      final taskId = _currentTaskId;
      _currentTaskId = null;
      _currentOutputPath = null;
      if (taskId != null) {
        // 失败落库自身也可能抛（库被关闭、磁盘满等）。必须吞掉：
        // 一旦异常从这里逃出 startConversion，下面的 isConverting 复位就不会执行，
        // 界面将永远卡在「转换中」。
        try {
          await _repository.updateTaskFull(
              id: taskId, status: 'FAILED', errorMessage: e.toString());
        } catch (dbError) {
          log('AudioVM').e('Failed to mark task as FAILED', error: dbError);
        }
      }
      // 文件已产出、只有收尾那次落库失败时，说「记录写入失败」也是误导：
      // 记录并不存在丢失问题——它在列表里，只是仍停留在「导出中」，
      // 失败的是那一次状态更新。产物确实在磁盘上，必须明确告诉用户去哪找。
      // 结论仍按失败呈现（走 error 通道），因为记录状态已经不对了。
      state = state.copyWith(
        isConverting: false,
        error: producedOutputPath != null
            ? '转换已完成，但记录状态更新失败（记录仍停留在「导出中」），'
                '文件位于：$producedOutputPath'
            : '转换失败: $e',
      );
    }
  }

  /// 取消转换：杀进程 + 删半成品文件 + 删任务记录
  Future<void> cancelConversion() async {
    final taskId = _currentTaskId;
    final outputPath = _currentOutputPath;
    final engine = _currentEngine;
    if (engine == null) return;

    _cancelRequested = true; // 必须在 kill 之前置位，供错误分支判定
    await engine.cancel();
    _currentEngine = null;
    _currentTaskId = null;
    _currentOutputPath = null;

    // 删任务记录 + 清半成品文件（用去重后的真实路径）
    if (taskId != null) {
      await _repository.deleteTask(taskId);
    }
    await _deleteFileQuietly(outputPath);

    if (!mounted) return;
    state = state.copyWith(isConverting: false, progress: 0, error: '已取消');
  }

  /// 把一条失败记录的参数回填到表单，供用户修正后重试
  void restoreFromTask(AudioTask task) {
    state = state.copyWith(
      sourcePath: task.sourcePath,
      sourceName: task.sourceName,
      sourceDurationMs: task.sourceDurationMs,
      trimStartMs: task.trimStartMs,
      trimEndMs: task.trimEndMs,
      title: task.title ?? '',
      artist: task.artist ?? '',
      album: task.album ?? '',
      coverPath: task.coverPath,
      targetBitrateKbps: task.targetBitrateKbps,
      // 换源必须丢掉上一个文件的探测结果并重新探测：
      // 沿用 stale 的 noAudio 会把有音轨的文件误判成无音轨，
      // 反而堵死本方法要开启的「修正后重试」
      sourceInfo: null,
      isProbing: true,
      error: null,
      success: null,
    );
    // 保留记录里的出点：本方法的用途是「回填参数后重试」，
    // 把区间悄悄放宽到全片会让重试产出与失败那次不同的文件
    unawaited(_probeSource(task.sourcePath, keepTrimEndMs: task.trimEndMs));
  }

  /// 删除一条记录，并尽力删除其产物文件
  ///
  /// 文件删除失败只记日志、不阻断记录删除——文件可能已被用户手动移走或占用，
  /// 卡住记录删除反而更糟。
  Future<void> deleteRecord(AudioTask task) async {
    await _deleteFileQuietly(task.outputPath);
    await _repository.deleteTask(task.id);
  }

  Future<void> _handleFailure({
    required int taskId,
    required String outputPath,
    required String message,
    required bool cancelled,
  }) async {
    _currentTaskId = null;
    _currentOutputPath = null;

    // 把产物路径另存为局部量：下面两次落库都可能抛，异常若逃出本方法就会
    // 落到 startConversion 的 catch，而那时字段已被清空、半成品文件再也找不回来
    final producedPath = outputPath;

    try {
      if (cancelled) {
        await _repository.deleteTask(taskId);
      } else {
        await _repository.updateTaskFull(
            id: taskId, status: 'FAILED', errorMessage: message);
      }
    } catch (e) {
      // 与 startConversion 外层 catch 同理：这里吞掉异常，
      // 否则它既会顶掉下面要展示的失败原因，也会顶掉文件的清理
      log('AudioVM').e('Failed to update task on failure', error: e);
    }

    // 清理半成品文件（用去重后的真实路径）
    await _deleteFileQuietly(producedPath);

    if (!mounted) return;
    state = state.copyWith(
      isConverting: false,
      progress: 0,
      error: message,
    );
  }

  /// 尽力删除文件：失败只记日志，不阻断调用方流程
  ///
  /// 文件可能已被用户手动移走或正被占用，此处卡住反而更糟。
  static Future<void> _deleteFileQuietly(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      log('AudioVM').w('Failed to delete file: $path', error: e);
    }
  }

  /// 输出路径去重：重名时追加 _1 / _2 …
  ///
  /// 抽成公开静态函数（与 [resolveTrimEndMs] 同样的理由）：去重规则只在
  /// 「同名文件已存在」时才会生效，而从外部驱动一次真实转换必须启动 ffmpeg，
  /// 规则一旦出错（计数初值写错、重名时直接返回原路径）就没有任何可在测试中
  /// 观察到的出口。生产路径（[startConversion] 第 4 步）调用的就是这个函数。
  static Future<String> resolveOutputPath(String dir, String fileName) async {
    var candidate = p.join(dir, fileName);
    if (!await File(candidate).exists()) return candidate;

    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dir, '${base}_$counter$ext');
      counter++;
    }
    return candidate;
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// 音频页 ViewModel Provider
final audioProvider = StateNotifierProvider<AudioViewModel, AudioState>((ref) {
  return AudioViewModel(
    AudioRepository(database),
    AppSettingsRepository(database),
  );
});

/// 转换记录（响应式）
final audioRecordsProvider = StreamProvider<List<AudioTask>>((ref) {
  return AudioRepository(database).watchAllTasks();
});
