import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/app_mode.dart';
import 'package:cutflow_flutter/navigation/nav_destinations.dart';

void main() {
  group('导航目标过滤', () {
    test('全量列表含 5 个目标，音频排在末位', () {
      expect(kNavDestinations.length, equals(5));
      expect(kNavDestinations.last.path, equals('/audio'));
      expect(kNavDestinations.last.audioOnly, isTrue);
    });

    test('音频版只保留 audioOnly 目标，且首个路径为 /audio', () {
      final result = destinationsFor(audioOnly: true);
      expect(result.length, equals(1));
      expect(result.first.path, equals('/audio'));
      expect(result.first.label, equals('音频'));
    });

    test('完整版保留全部 5 个目标，且首个路径为 /clip', () {
      final result = destinationsFor(audioOnly: false);
      expect(result.length, equals(5));
      expect(result.first.path, equals('/clip'));
    });

    test('所有 path 唯一（避免路由冲突）', () {
      final paths = kNavDestinations.map((d) => d.path).toList();
      expect(paths.toSet().length, equals(paths.length));
    });

    test('activeDestinations 与 kAudioOnlyMode 一致', () {
      expect(activeDestinations.length, equals(kAudioOnlyMode ? 1 : 5));
      expect(activeDestinations.first.path,
          equals(kAudioOnlyMode ? '/audio' : '/clip'));
    });
  });
}
