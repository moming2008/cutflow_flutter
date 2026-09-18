/// 音频提取任务领域模型
///
/// 与视频侧的 ExportTask 结构上隔离；状态枚举刻意不含 PREPARING，
/// 因为音频转换无需导出前准备阶段。
library;

import 'package:equatable/equatable.dart';

enum AudioTaskStatus {
  pending,   // 等待中
  exporting, // 转换中
  done,      // 已完成
  failed,    // 转换失败
}

class AudioTask extends Equatable {
  final int id;
  final String sourcePath;
  final String sourceName;
  final int sourceDurationMs;
  final int? sourceBitrateKbps; // null = 探测不到
  final int trimStartMs;
  final int trimEndMs;
  final String? title;
  final String? artist;
  final String? album;
  final String? coverPath;
  final int targetBitrateKbps;
  final String outputName;
  final String? outputPath;
  final AudioTaskStatus status;
  final int progress; // 0-100
  final String? errorMessage;
  final int createdAt;
  final int? completedAt;

  const AudioTask({
    required this.id,
    required this.sourcePath,
    required this.sourceName,
    required this.sourceDurationMs,
    this.sourceBitrateKbps,
    required this.trimStartMs,
    required this.trimEndMs,
    this.title,
    this.artist,
    this.album,
    this.coverPath,
    required this.targetBitrateKbps,
    required this.outputName,
    this.outputPath,
    required this.status,
    required this.progress,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sourcePath,
        sourceName,
        sourceDurationMs,
        sourceBitrateKbps,
        trimStartMs,
        trimEndMs,
        title,
        artist,
        album,
        coverPath,
        targetBitrateKbps,
        outputName,
        outputPath,
        status,
        progress,
        errorMessage,
        createdAt,
        completedAt,
      ];

  String get statusText {
    switch (status) {
      case AudioTaskStatus.pending:
        return '等待中';
      case AudioTaskStatus.exporting:
        return '转换中';
      case AudioTaskStatus.done:
        return '已完成';
      case AudioTaskStatus.failed:
        return '转换失败';
    }
  }

  bool get isProcessing => status == AudioTaskStatus.exporting;
  bool get isCompleted => status == AudioTaskStatus.done;
  bool get isFailed => status == AudioTaskStatus.failed;

  AudioTask copyWith({
    int? id,
    String? sourcePath,
    String? sourceName,
    int? sourceDurationMs,
    int? sourceBitrateKbps,
    int? trimStartMs,
    int? trimEndMs,
    String? title,
    String? artist,
    String? album,
    String? coverPath,
    int? targetBitrateKbps,
    String? outputName,
    String? outputPath,
    AudioTaskStatus? status,
    int? progress,
    String? errorMessage,
    int? createdAt,
    int? completedAt,
  }) {
    return AudioTask(
      id: id ?? this.id,
      sourcePath: sourcePath ?? this.sourcePath,
      sourceName: sourceName ?? this.sourceName,
      sourceDurationMs: sourceDurationMs ?? this.sourceDurationMs,
      sourceBitrateKbps: sourceBitrateKbps ?? this.sourceBitrateKbps,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      coverPath: coverPath ?? this.coverPath,
      targetBitrateKbps: targetBitrateKbps ?? this.targetBitrateKbps,
      outputName: outputName ?? this.outputName,
      outputPath: outputPath ?? this.outputPath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
