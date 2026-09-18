import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/app_mode.dart';
import 'package:cutflow_flutter/core/database/app_database.dart';
import 'package:cutflow_flutter/core/repository/app_settings_repository.dart';
import 'package:cutflow_flutter/core/repository/audio_repository.dart';
import 'package:cutflow_flutter/features/audio/audio_screen.dart';
import 'package:cutflow_flutter/features/audio/audio_viewmodel.dart';
import 'package:cutflow_flutter/features/clip/clip_screen.dart';
import 'package:cutflow_flutter/navigation/app_router.dart';
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

  group('路由接线', () {
    late AppDatabase testDb;

    setUp(() {
      testDb = AppDatabase.forTest(NativeDatabase.memory());
    });

    tearDown(() async {
      await testDb.close();
    });

    /// 渲染真实 appRouter
    ///
    /// 启动落点是音频页，路由会真的构建 AudioScreen —— 它会 watch 两个
    /// provider，而这两个 provider 的生产实现读 lib/main.dart 的全局
    /// `database`（测试环境从未初始化）。故与 audio_screen_test 同样注入内存库。
    Widget buildRouterApp() {
      return ProviderScope(
        overrides: [
          audioProvider.overrideWith(
            (ref) => AudioViewModel(
              AudioRepository(testDb),
              AppSettingsRepository(testDb),
            ),
          ),
          audioRecordsProvider
              .overrideWith((ref) => AudioRepository(testDb).watchAllTasks()),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      );
    }

    // 上面几组只断言 kNavDestinations / activeDestinations 这类**表达式**；
    // 真正把「音频版启动落在 /audio」落到实处的，是 app_router.dart 里
    // `initialLocation: activeDestinations.first.path` 这一行接线。
    // 若把它硬编码回 '/clip'，上面 5 个断言依然全绿 —— 故此处直接渲染
    // 真实 appRouter，验证启动落点。
    testWidgets('音频版启动落在音频页（initialLocation 接线有效）', (tester) async {
      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(AudioScreen), findsOneWidget);

      // 卸载组件树，并推进假时钟跑掉 drift 取消查询流时挂上的零延时定时器
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });

    testWidgets('音频版侧栏不含视频侧页签，且未落到裁剪页', (tester) async {
      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      // 负面断言：视频侧页面不进侧栏、也不作为启动页
      expect(find.byType(ClipScreen), findsNothing);
      expect(find.text('裁剪'), findsNothing);
      // 唯一的页签就是音频
      expect(find.text('音频'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });
  });
}
