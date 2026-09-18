/// 输出文件名清洗
///
/// Windows 文件名禁止 `\ / : * ? " < > |`，而歌名极易含 `/`（如 AC/DC）
/// 或 `:`。生成输出文件名前必须清洗。
///
/// **只清洗文件名，不清洗 ID3 标签内容** —— 标签里保留用户原样输入。
library;

class FilenameSanitizer {
  static final RegExp _illegalChars = RegExp(r'[\\/:*?"<>|]');
  static final RegExp _controlChars = RegExp(r'[\x00-\x1f]');
  static final RegExp _leadingOrTrailing = RegExp(r'^[\s.]+|[\s.]+$');

  /// 清洗为安全的文件名主干（不含扩展名）
  ///
  /// 规则：非法字符 → `_` → 剔除控制字符 → 去除首尾空格与点号
  /// （Windows 下文件名不能以点或空格结尾）→ 空结果回退为 `audio`。
  static String sanitize(String raw) {
    var name = raw.replaceAll(_illegalChars, '_');
    name = name.replaceAll(_controlChars, '');
    name = name.replaceAll(_leadingOrTrailing, '');
    return name.isEmpty ? 'audio' : name;
  }
}
