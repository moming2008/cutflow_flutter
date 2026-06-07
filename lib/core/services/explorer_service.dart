/// Windows 资源管理器服务
///
/// 提供打开文件所在位置和系统播放器播放功能。
library;

import 'dart:io';
import 'package:path/path.dart' as p;

class ExplorerService {
  /// 在 Windows 资源管理器中打开文件所在位置并选中文件
  static Future<void> openFileLocation(String filePath) async {
    if (!Platform.isWindows) return;
    final normalized = p.normalize(filePath);
    await Process.run('explorer.exe', ['/select,$normalized']);
  }

  /// 使用系统默认播放器播放视频
  static Future<void> playWithSystemPlayer(String filePath) async {
    if (!Platform.isWindows) return;
    await Process.run('cmd.exe', ['/c', 'start', '', filePath]);
  }
}
