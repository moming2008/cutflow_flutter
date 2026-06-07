import 'package:equatable/equatable.dart';

enum TaskStatus {
  pending,    // 等待中
  preparing,  // 准备导出
  exporting,  // 正在导出
  done,       // 已完成
  failed,     // 导出失败
}

class ExportTask extends Equatable {
  final int id;
  final int sourceVideoId;
  final String outputName;
  final int trimStartMs;
  final int trimEndMs;
  final int? cropPresetId;
  final String? cropSnapshot;
  final String? cropPresetName;
  final String? cropRatioLabel;
  final String? sourceVideoName;
  final TaskStatus status;
  final int progress; // 0-100
  final int createdAt; // 时间戳
  // v2 新增字段
  final String? outputPath;    // 导出文件完整路径
  final int? completedAt;      // 完成时间戳
  final int? archivedAt;       // 归档时间戳
  final String? errorMessage;  // FFmpeg 错误信息

  const ExportTask({
    required this.id,
    required this.sourceVideoId,
    required this.outputName,
    required this.trimStartMs,
    required this.trimEndMs,
    this.cropPresetId,
    this.cropSnapshot,
    this.cropPresetName,
    this.cropRatioLabel,
    this.sourceVideoName,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.outputPath,
    this.completedAt,
    this.archivedAt,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        id,
        sourceVideoId,
        outputName,
        trimStartMs,
        trimEndMs,
        cropPresetId,
        cropSnapshot,
        cropPresetName,
        cropRatioLabel,
        sourceVideoName,
        status,
        progress,
        createdAt,
        outputPath,
        completedAt,
        archivedAt,
        errorMessage,
      ];

  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case TaskStatus.pending:
        return '等待中';
      case TaskStatus.preparing:
        return '准备导出';
      case TaskStatus.exporting:
        return '正在导出';
      case TaskStatus.done:
        return '已完成';
      case TaskStatus.failed:
        return '导出失败';
    }
  }

  /// 是否正在处理中
  bool get isProcessing =>
      status == TaskStatus.preparing || status == TaskStatus.exporting;

  /// 是否完成
  bool get isCompleted => status == TaskStatus.done;

  /// 是否失败
  bool get isFailed => status == TaskStatus.failed;

  /// 是否已归档
  bool get isArchived => archivedAt != null;

  ExportTask copyWith({
    int? id,
    int? sourceVideoId,
    String? outputName,
    int? trimStartMs,
    int? trimEndMs,
    int? cropPresetId,
    String? cropSnapshot,
    String? cropPresetName,
    String? cropRatioLabel,
    String? sourceVideoName,
    TaskStatus? status,
    int? progress,
    int? createdAt,
    String? outputPath,
    int? completedAt,
    int? archivedAt,
    String? errorMessage,
  }) {
    return ExportTask(
      id: id ?? this.id,
      sourceVideoId: sourceVideoId ?? this.sourceVideoId,
      outputName: outputName ?? this.outputName,
      trimStartMs: trimStartMs ?? this.trimStartMs,
      trimEndMs: trimEndMs ?? this.trimEndMs,
      cropPresetId: cropPresetId ?? this.cropPresetId,
      cropSnapshot: cropSnapshot ?? this.cropSnapshot,
      cropPresetName: cropPresetName ?? this.cropPresetName,
      cropRatioLabel: cropRatioLabel ?? this.cropRatioLabel,
      sourceVideoName: sourceVideoName ?? this.sourceVideoName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      outputPath: outputPath ?? this.outputPath,
      completedAt: completedAt ?? this.completedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
