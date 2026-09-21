import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/ffmpeg/audio_metadata_probe.dart';

void main() {
  group('探测命令与解析器的字段契约', () {
    // 本组是线上缺陷的防回归测试。
    //
    // 缺陷：命令用 -select_streams a:0 取音轨，解析器却按 codec_type == 'audio'
    // 筛选；而命令的 -show_entries 没有请求 codec_type，于是解析器永远匹配不到
    // 音轨 —— 任何视频都报「没有音频轨道」。
    //
    // 为什么纯解析测试抓不到：它们喂的是**手写 JSON**，里面恰好带了真实命令
    // 不会产出的 codec_type 字段。测的是解析器面对虚构输入的行为。
    //
    // 故这里断言的是另一件事：命令必须请求解析器实际读取的每一个字段。

    /// 取出所有 `-show_entries <key>=a,b,c` 里的字段名
    List<String> showEntryFields(String key, List<String> args) {
      final fields = <String>[];
      for (var i = 0; i < args.length - 1; i++) {
        final value = args[i + 1];
        if (args[i] == '-show_entries' && value.startsWith('$key=')) {
          fields.addAll(value.substring(key.length + 1).split(','));
        }
      }
      return fields;
    }

    test('stream 字段覆盖 parseFfprobeJson 读取的全部字段', () {
      final args = AudioMetadataProbe.buildProbeArgs('/x/y.mp4');

      // parseFfprobeJson 读取：codec_type（判定是否音轨）、
      // bit_rate / codec_name / channels / sample_rate（音轨属性）
      expect(
        showEntryFields('stream', args),
        containsAll(<String>[
          'codec_type',
          'bit_rate',
          'codec_name',
          'channels',
          'sample_rate',
        ]),
      );
    });

    test('format 字段覆盖 parseFfprobeJson 读取的全部字段', () {
      final args = AudioMetadataProbe.buildProbeArgs('/x/y.mp4');

      // parseFfprobeJson 读取：duration、bit_rate（容器码率回退）
      expect(
        showEntryFields('format', args),
        containsAll(<String>['duration', 'bit_rate']),
      );
    });

    test('命令仍保留音轨选择、JSON 输出与输入路径', () {
      final args = AudioMetadataProbe.buildProbeArgs('/x/y.mp4');

      expect(args[args.indexOf('-select_streams') + 1], equals('a:0'));
      expect(args[args.indexOf('-of') + 1], equals('json'));
      expect(args.last, equals('/x/y.mp4'));
    });
  });

  group('真实 ffprobe 输出快照', () {
    test('竖屏录屏（HEVC + AAC）能被识别为含音轨', () {
      // 逐字取自真实 ffprobe 对
      // Screenrecorder-2026-09-18-13-45-38-486.mp4（480x800 竖屏录屏，
      // 4 分 46 秒，HEVC 视频 + AAC 单声道音轨）的输出。
      // 与其它 fixture 的区别：这一份不是手写的，是真实命令的产出。
      const json = '''
      {
          "programs": [],
          "stream_groups": [],
          "streams": [
              {
                  "codec_name": "aac",
                  "codec_type": "audio",
                  "sample_rate": "44100",
                  "channels": 1,
                  "bit_rate": "264600"
              }
          ],
          "format": {
              "duration": "286.255556",
              "bit_rate": "709806"
          }
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.codec, equals('aac'));
      expect(info.channels, equals(1));
      expect(info.sampleRate, equals(44100));
      // 音轨自带 bit_rate，故取精确值（264.6 → 265），不标记为近似
      expect(info.bitrateKbps, equals(265));
      expect(info.bitrateIsApproximate, isFalse);
      expect(info.durationMs, equals(286256));
    });
  });

  group('AudioMetadataProbe.parseFfprobeJson', () {
    test('音轨自带 bit_rate 时取精确值，不标记为近似', () {
      const json = '''
      {
        "streams": [
          {"codec_type": "audio", "codec_name": "aac", "bit_rate": "192000",
           "channels": 2, "sample_rate": "48000"}
        ],
        "format": {"duration": "180.500", "bit_rate": "3000000"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.bitrateKbps, equals(192));
      expect(info.bitrateIsApproximate, isFalse);
      expect(info.codec, equals('aac'));
      expect(info.channels, equals(2));
      expect(info.sampleRate, equals(48000));
      expect(info.durationMs, equals(180500));
    });

    test('音轨缺 bit_rate 时回退容器码率，并标记为近似', () {
      const json = '''
      {
        "streams": [
          {"codec_type": "audio", "codec_name": "aac",
           "channels": 6, "sample_rate": "48000"}
        ],
        "format": {"duration": "240.0", "bit_rate": "3200000"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.bitrateKbps, equals(3200)); // 容器总码率，不是音轨码率
      expect(info.bitrateIsApproximate, isTrue);
      expect(info.channels, equals(6));
    });

    test('音轨与容器都没有码率时返回 null', () {
      const json = '''
      {
        "streams": [{"codec_type": "audio", "codec_name": "pcm_s16le"}],
        "format": {"duration": "12.0"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isTrue);
      expect(info.bitrateKbps, isNull);
      expect(info.bitrateIsApproximate, isFalse);
    });

    test('没有音频流时 hasAudio 为 false', () {
      const json = '''
      {
        "streams": [{"codec_type": "video", "codec_name": "h264"}],
        "format": {"duration": "60.0", "bit_rate": "1500000"}
      }
      ''';
      final info = AudioMetadataProbe.parseFfprobeJson(json);

      expect(info.hasAudio, isFalse);
      expect(info.bitrateKbps, isNull);
      expect(info.durationMs, equals(60000));
    });

    test('空 streams 数组同样判为无音轨', () {
      final info = AudioMetadataProbe.parseFfprobeJson(
          '{"streams": [], "format": {"duration": "5.0"}}');
      expect(info.hasAudio, isFalse);
    });

    test('非法 JSON 不抛异常，返回 noAudio', () {
      final info = AudioMetadataProbe.parseFfprobeJson('not json at all');
      expect(info.hasAudio, isFalse);
      expect(info.bitrateKbps, isNull);
    });

    test('缺 format 时 durationMs 为 0', () {
      const json = '{"streams": [{"codec_type": "audio", "codec_name": "mp3"}]}';
      final info = AudioMetadataProbe.parseFfprobeJson(json);
      expect(info.hasAudio, isTrue);
      expect(info.durationMs, equals(0));
    });
  });
}
