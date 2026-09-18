import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/ffmpeg/audio_metadata_probe.dart';

void main() {
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
