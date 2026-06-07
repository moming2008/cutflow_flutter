import 'package:equatable/equatable.dart';

class VideoItem extends Equatable {
  final int id;
  final String path;
  final String name;
  final int duration; // 毫秒
  final int width;
  final int height;
  final int fileSize;
  final double frameRate;
  final String codec;
  final int importedAt; // 时间戳

  const VideoItem({
    required this.id,
    required this.path,
    required this.name,
    required this.duration,
    required this.width,
    required this.height,
    required this.fileSize,
    required this.frameRate,
    required this.codec,
    required this.importedAt,
  });

  @override
  List<Object?> get props => [
        id,
        path,
        name,
        duration,
        width,
        height,
        fileSize,
        frameRate,
        codec,
        importedAt,
      ];

  /// 格式化时长显示 (mm:ss)
  String get formattedDuration {
    final minutes = duration ~/ 60000;
    final seconds = (duration % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化文件大小
  String get formattedFileSize {
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 分辨率字符串
  String get resolution => '${width}x$height';
}
