import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/ffmpeg/command_builder.dart';

/// 取 `-flag` 后紧跟的值
String? _valueOf(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index < 0 || index + 1 >= args.length) return null;
  return args[index + 1];
}

/// 第 n 个 `-metadata`（含 `-metadata:s:v`）之后的值
List<String> _allValuesOf(List<String> args, String flag) {
  final result = <String>[];
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == flag) result.add(args[i + 1]);
  }
  return result;
}

void main() {
  group('buildExtractMp3（带封面）', () {
    late List<String> args;

    setUp(() {
      args = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/video.mp4',
        outputPath: '/out/song.mp3',
        startMs: 30000,
        endMs: 195000,
        targetBitrateKbps: 320,
        coverPath: '/in/cover.jpg',
        title: '晴天',
        artist: '周杰伦',
        album: '叶惠美',
      );
    });

    test('输出路径在末尾', () {
      expect(args.last, equals('/out/song.mp3'));
    });

    test('-ss 在 -i 输入之前（输入 seek）', () {
      expect(args.indexOf('-ss'), lessThan(args.indexOf('-i')));
    });

    test('-t 在所有输入之后（输出时长限制）', () {
      final lastInput = args.lastIndexOf('-i');
      expect(args.indexOf('-t'), greaterThan(lastInput));
    });

    test('时长为 出点-入点（165 秒）', () {
      expect(_valueOf(args, '-t'), equals('00:02:45.000'));
    });

    test('码率参数正确', () {
      expect(_valueOf(args, '-b:a'), equals('320k'));
      expect(_valueOf(args, '-c:a'), equals('libmp3lame'));
    });

    test('ID3 版本固定为 3', () {
      expect(_valueOf(args, '-id3v2_version'), equals('3'));
    });

    test('三个标签正确写入', () {
      expect(_allValuesOf(args, '-metadata'),
          containsAll(['title=晴天', 'artist=周杰伦', 'album=叶惠美']));
    });

    test('封面映射与 attached_pic 齐备', () {
      expect(_allValuesOf(args, '-map'), equals(['0:a:0', '1:v:0']));
      expect(_valueOf(args, '-c:v'), equals('mjpeg'));
      expect(_valueOf(args, '-disposition:v'), equals('attached_pic'));
    });

    test('封面缩放滤镜限制最长边 600 且不放大', () {
      expect(_valueOf(args, '-vf'),
          equals(r'scale=w=min(600\,iw):h=min(600\,ih):force_original_aspect_ratio=decrease'));
    });

    test('封面流带 Album cover 元数据', () {
      expect(_allValuesOf(args, '-metadata:s:v'),
          equals(['title=Album cover', 'comment=Cover (front)']));
    });
  });

  group('buildExtractMp3（不带封面）', () {
    late List<String> args;

    setUp(() {
      args = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/video.mp4',
        outputPath: '/out/song.mp3',
        startMs: 0,
        endMs: 60000,
        targetBitrateKbps: 192,
      );
    });

    test('不出现任何封面相关参数', () {
      expect(args.contains('-c:v'), isFalse);
      expect(args.contains('-vf'), isFalse);
      expect(args.contains('-q:v'), isFalse);
      expect(args.contains('-disposition:v'), isFalse);
      expect(args.contains('-metadata:s:v'), isFalse);
      expect(_allValuesOf(args, '-map'), isEmpty);
      expect(args.where((a) => a == '-i').length, equals(1));
    });

    test('标签留空时不写入对应 -metadata', () {
      expect(_allValuesOf(args, '-metadata'), isEmpty);
    });

    test('音频参数与 ID3 版本仍在', () {
      expect(_valueOf(args, '-c:a'), equals('libmp3lame'));
      expect(_valueOf(args, '-b:a'), equals('192k'));
      expect(_valueOf(args, '-id3v2_version'), equals('3'));
      expect(args.last, equals('/out/song.mp3'));
    });
  });

  group('声道选择', () {
    // 单声道源（手机录屏的麦克风音轨）转出的 MP3 也是单声道，
    // 在部分车机/蓝牙设备上只从一个声道出声。默认强制立体声（-ac 2），
    // 保留「跟随源」给在意同码率下保真度的用户。
    // 采样率刻意不提供选项：向上重采样不会增加音质，44.1kHz 是 MP3 最标准率。

    List<String> build({bool? forceStereo}) {
      // forceStereo 为 null 表示「不传参数」本身，用于断言缺省行为
      final forceStereoArg = forceStereo;
      return FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/video.mp4',
        outputPath: '/out/song.mp3',
        startMs: 0,
        endMs: 60000,
        targetBitrateKbps: 256,
        if (forceStereoArg != null) forceStereo: forceStereoArg,
      );
    }

    test('forceStereo 为 true 时加 -ac 2', () {
      expect(_valueOf(build(forceStereo: true), '-ac'), equals('2'));
    });

    test('forceStereo 为 false 时不加 -ac（跟随源）', () {
      expect(build(forceStereo: false).contains('-ac'), isFalse);
    });

    test('缺省时不加 -ac（历史行为不变）', () {
      // 上面 setUp 里的旧调用点都不传该参数，必须保持原行为
      expect(build(forceStereo: null).contains('-ac'), isFalse);
    });
  });

  group('标签值规整', () {
    test('换行折为空格、去首尾空格', () {
      expect(FfmpegCommandBuilder.normalizeTagValue('  晴天\nLive  '),
          equals('晴天 Live'));
      expect(FfmpegCommandBuilder.normalizeTagValue('a\r\nb'),
          equals('a b'));
    });

    test('null 与纯空白返回 null', () {
      expect(FfmpegCommandBuilder.normalizeTagValue(null), isNull);
      expect(FfmpegCommandBuilder.normalizeTagValue('   '), isNull);
      expect(FfmpegCommandBuilder.normalizeTagValue('\n\n'), isNull);
    });

    test('含引号与 & | 的标签原样保留（不经 shell，无需转义）', () {
      expect(FfmpegCommandBuilder.normalizeTagValue('Rock "n" Roll & More'),
          equals('Rock "n" Roll & More'));
    });

    test('空标签不生成 -metadata 参数', () {
      final args = FfmpegCommandBuilder.buildExtractMp3(
        inputPath: '/in/v.mp4',
        outputPath: '/out/o.mp3',
        startMs: 0,
        endMs: 1000,
        targetBitrateKbps: 128,
        title: '   ',
        artist: '周杰伦',
        album: null,
      );
      expect(_allValuesOf(args, '-metadata'), equals(['artist=周杰伦']));
    });
  });
}
