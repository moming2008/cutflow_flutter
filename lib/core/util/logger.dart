/// 全局日志工具
///
/// 使用方式: log('ModuleName').i('info message')
///           log('ModuleName').e('error message', error: e)
///           log('ModuleName').d('debug message')
///           log('ModuleName').w('warning message')
library;

import 'package:logger/logger.dart';

final _printer = SimplePrinter(colors: false);

/// 通用日志实例，按模块传名使用：`log('FfmpegEngine').d(...)`
Logger log([String? tag]) => Logger(
      printer: tag != null ? _TagPrinter(tag, _printer) : _printer,
      level: Level.debug,
    );

class _TagPrinter extends LogPrinter {
  final String tag;
  final SimplePrinter _inner;

  _TagPrinter(this.tag, this._inner);

  @override
  List<String> log(LogEvent event) {
    final lines = _inner.log(event);
    return lines.map((line) => '[$tag] $line').toList();
  }
}
