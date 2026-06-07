import 'package:equatable/equatable.dart';

class CropPreset extends Equatable {
  final int id;
  final String name;
  final String ratioLabel;
  final int ratioW;
  final int ratioH;
  final int outputW; // 固定输出宽度(0表示比例模式)
  final int outputH; // 固定输出高度
  final int offsetX;
  final int offsetY;
  final bool isBuiltin;
  final int sortOrder;

  const CropPreset({
    required this.id,
    required this.name,
    required this.ratioLabel,
    required this.ratioW,
    required this.ratioH,
    required this.outputW,
    required this.outputH,
    required this.offsetX,
    required this.offsetY,
    required this.isBuiltin,
    required this.sortOrder,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        ratioLabel,
        ratioW,
        ratioH,
        outputW,
        outputH,
        offsetX,
        offsetY,
        isBuiltin,
        sortOrder,
      ];

  /// 是否为固定像素模式
  bool get isFixedPixelMode => outputW > 0 && outputH > 0;

  /// 显示名称
  String get displayName {
    if (isFixedPixelMode) {
      return '$ratioLabel $outputW×$outputH';
    } else {
      return ratioLabel;
    }
  }
}
