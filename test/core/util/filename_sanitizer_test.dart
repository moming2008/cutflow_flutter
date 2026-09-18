import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/util/filename_sanitizer.dart';

void main() {
  group('FilenameSanitizer.sanitize', () {
    test('斜杠替换为下划线（AC/DC 场景）', () {
      expect(FilenameSanitizer.sanitize('AC/DC - Back in Black'),
          equals('AC_DC - Back in Black'));
    });

    test('冒号替换为下划线', () {
      expect(FilenameSanitizer.sanitize('Song: Live'), equals('Song_ Live'));
    });

    test('覆盖全部 Windows 非法字符', () {
      expect(FilenameSanitizer.sanitize(r'a\b/c:d*e?f"g<h>i|j'),
          equals('a_b_c_d_e_f_g_h_i_j'));
    });

    test('去除首尾空格与点号', () {
      expect(FilenameSanitizer.sanitize('  ..歌名..  '), equals('歌名'));
    });

    test('中文与常见符号原样保留', () {
      expect(FilenameSanitizer.sanitize('晴天 - 周杰伦 (Live)'),
          equals('晴天 - 周杰伦 (Live)'));
    });

    test('清洗后为空时回退为 audio', () {
      expect(FilenameSanitizer.sanitize(''), equals('audio'));
      expect(FilenameSanitizer.sanitize('   '), equals('audio'));
      expect(FilenameSanitizer.sanitize('...'), equals('audio'));
      expect(FilenameSanitizer.sanitize('///'), equals('___'));
    });

    test('剔除控制字符', () {
      expect(FilenameSanitizer.sanitize('song\u0000name'), equals('songname'));
    });
  });
}
