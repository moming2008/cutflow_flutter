import 'package:equatable/equatable.dart';

class EditorDraft extends Equatable {
  final int id;
  final int sourceVideoId;
  final String outputName;
  final int trimStartMs;
  final int trimEndMs;
  final int? selectedCropPresetId;
  final int updatedAt; // 时间戳

  const EditorDraft({
    required this.id,
    required this.sourceVideoId,
    required this.outputName,
    required this.trimStartMs,
    required this.trimEndMs,
    this.selectedCropPresetId,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sourceVideoId,
        outputName,
        trimStartMs,
        trimEndMs,
        selectedCropPresetId,
        updatedAt,
      ];
}
