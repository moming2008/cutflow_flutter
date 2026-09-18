import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/model/audio_source_info.dart';
import 'package:cutflow_flutter/features/audio/audio_viewmodel.dart';

AudioState _base({
  String? sourcePath = '/in/video.mp4',
  String? sourceName = 'video.mp4',
  int trimStartMs = 0,
  int trimEndMs = 60000,
  String title = '',
  String? coverPath,
  AudioSourceInfo? sourceInfo,
  bool isConverting = false,
}) {
  return AudioState(
    sourcePath: sourcePath,
    sourceName: sourceName,
    sourceDurationMs: 180000,
    trimStartMs: trimStartMs,
    trimEndMs: trimEndMs,
    title: title,
    artist: '',
    album: '',
    coverPath: coverPath,
    targetBitrateKbps: 320,
    sourceInfo: sourceInfo,
    isConverting: isConverting,
  );
}

void main() {
  group('输出文件名', () {
    test('歌名非空时用歌名', () {
      final state = _base(title: '晴天');
      expect(state.outputFileName, equals('晴天.mp3'));
    });

    test('歌名为空时回退源文件名', () {
      final state = _base(title: '   ');
      expect(state.outputFileName, equals('video.mp3'));
    });

    test('歌名含非法字符时被清洗', () {
      final state = _base(title: 'AC/DC: Live');
      expect(state.outputFileName, equals('AC_DC_ Live.mp3'));
    });

    test('清洗后为空则回退 audio', () {
      final state = _base(title: '...');
      expect(state.outputFileName, equals('audio.mp3'));
    });
  });

  group('校验 blockingError', () {
    test('未选文件时提示选择视频', () {
      final state = _base(sourcePath: null, sourceName: null);
      expect(state.blockingError, equals('请先选择视频文件'));
    });

    test('无音轨时拦截', () {
      final state = _base(sourceInfo: AudioSourceInfo.noAudio);
      expect(state.blockingError, equals('该视频没有音频轨道，无法提取音频'));
    });

    test('探测中不拦截（尚未知结果）', () {
      final state = _base(sourceInfo: null);
      expect(state.blockingError, isNull);
    });

    test('出点不大于入点时提示', () {
      expect(_base(trimStartMs: 5000, trimEndMs: 5000).blockingError,
          equals('出点必须大于入点'));
      expect(_base(trimStartMs: 5000, trimEndMs: 1000).blockingError,
          equals('出点必须大于入点'));
    });

    test('正常状态无拦截', () {
      expect(_base().blockingError, isNull);
    });
  });

  group('canConvert', () {
    test('无拦截项且不在转换中时可转换', () {
      expect(_base(title: '晴天').canConvert, isTrue);
    });

    test('转换中不可再转换', () {
      expect(_base(isConverting: true).canConvert, isFalse);
    });

    test('有拦截项时不可转换', () {
      expect(_base(sourcePath: null).canConvert, isFalse);
      expect(_base(trimStartMs: 0, trimEndMs: 0).canConvert, isFalse);
    });
  });

  group('码率档位', () {
    test('档位为 128/160/192/256/320', () {
      expect(kAudioBitrateOptions, equals([128, 160, 192, 256, 320]));
    });
  });

  // copyWith 用哨兵区分「不传」与「显式传 null」：
  // 若退回朴素的 `??` 合并，「清空封面」会静默失效。
  group('copyWith 显式置空', () {
    test('显式传 null 清空封面', () {
      final state = _base(coverPath: '/in/cover.jpg');
      expect(state.copyWith(coverPath: null).coverPath, isNull);
      expect(state.copyWith().coverPath, equals('/in/cover.jpg'));
    });

    test('显式传 null 清空错误与成功提示', () {
      const state = AudioState(error: '出错了', success: '完成了');
      final cleared = state.copyWith(error: null, success: null);
      expect(cleared.error, isNull);
      expect(cleared.success, isNull);
      expect(state.copyWith().error, equals('出错了'));
      expect(state.copyWith().success, equals('完成了'));
    });

    test('显式传 null 清空探测结果与输出目录', () {
      const state = AudioState(
        sourceInfo: AudioSourceInfo(hasAudio: true, durationMs: 1000),
        outputDirectory: '/out',
      );
      final cleared = state.copyWith(sourceInfo: null, outputDirectory: null);
      expect(cleared.sourceInfo, isNull);
      expect(cleared.outputDirectory, isNull);
      expect(state.copyWith().outputDirectory, equals('/out'));
    });

    test('未传的字段保持原值', () {
      final state = _base(title: '晴天');
      final next = state.copyWith(progress: 42);
      expect(next.progress, equals(42));
      expect(next.title, equals('晴天'));
      expect(next.sourcePath, equals('/in/video.mp4'));
      expect(next.targetBitrateKbps, equals(320));
    });
  });
}
