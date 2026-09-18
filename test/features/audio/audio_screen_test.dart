import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutflow_flutter/core/database/app_database.dart';
import 'package:cutflow_flutter/core/model/audio_source_info.dart';
import 'package:cutflow_flutter/core/repository/app_settings_repository.dart';
import 'package:cutflow_flutter/core/repository/audio_repository.dart';
import 'package:cutflow_flutter/features/audio/audio_screen.dart';
import 'package:cutflow_flutter/features/audio/audio_viewmodel.dart';

import 'support/seedable_audio_viewmodel.dart';

void main() {
  late AppDatabase testDb;

  setUp(() {
    testDb = AppDatabase.forTest(NativeDatabase.memory());
  });

  tearDown(() async {
    await testDb.close();
  });

  /// 用内存库替掉两个 Provider，避免测试触碰 lib/main.dart 的全局 database
  ///
  /// 不覆盖的话，构造 audioProvider 会读到从未初始化的
  /// `late AppDatabase database` 并抛 LateInitializationError。
  /// [seed] 用于铺「已选好文件」这类前置状态（选文件会触发 ffprobe，测试里不能真跑）。
  Widget buildApp({AudioState? seed}) {
    final viewModel = SeedableAudioViewModel(
      AudioRepository(testDb),
      AppSettingsRepository(testDb),
    );
    if (seed != null) viewModel.seed(seed);

    return ProviderScope(
      overrides: [
        audioProvider.overrideWith((ref) => viewModel),
        audioRecordsProvider
            .overrideWith((ref) => AudioRepository(testDb).watchAllTasks()),
      ],
      child: const MaterialApp(home: AudioScreen()),
    );
  }

  /// 包装 testWidgets：结束后主动卸载组件树并跑掉 drift 的零延时定时器
  ///
  /// ProviderScope 释放时会取消 drift 的查询流，drift 随即挂上一个零延时
  /// 定时器（stream_queries.markAsClosed）。它落在「卸载那一帧」之后，必须在
  /// 测试体内推进假时钟把它跑掉，否则测试会以「A Timer is still pending」失败。
  void screenTest(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });
  }

  /// 「已选好视频、已探测出音轨、区间有效」的前置状态
  AudioState selectedSource({
    int trimStartMs = 0,
    int trimEndMs = 60000,
    int durationMs = 60000,
  }) {
    return AudioState(
      sourcePath: '/nope/video.mp4',
      sourceName: 'video.mp4',
      sourceDurationMs: durationMs,
      trimStartMs: trimStartMs,
      trimEndMs: trimEndMs,
      outputDirectory: '/nope',
      sourceInfo: AudioSourceInfo(hasAudio: true, durationMs: durationMs),
    );
  }

  screenTest('空态显示引导文案', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('音频提取'), findsOneWidget);
    expect(find.text('选择一个视频开始提取音频'), findsOneWidget);
  });

  // 空态不渲染表单，因此「未选文件」这一情形下根本没有开始转换按钮 ——
  // 比「按钮存在但禁用」更早地把用户挡在门外，故断言按钮不存在，
  // 并另行断言入口按钮（选择视频）可用。
  screenTest('未选文件时不出现开始转换按钮', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.widgetWithText(ElevatedButton, '开始转换'), findsNothing);

    final pickButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '选择视频'),
    );
    expect(pickButton.onPressed, isNotNull);
  });

  screenTest('出点不大于入点时开始转换按钮禁用', (tester) async {
    await tester.pumpWidget(
      buildApp(seed: selectedSource(trimStartMs: 30000, trimEndMs: 30000)),
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始转换'),
    );
    expect(button.onPressed, isNull);
  });

  // 按钮变灰时必须说明原因，否则用户只看到一个不可点的按钮
  screenTest('区间非法时说明按钮为何不可用', (tester) async {
    await tester.pumpWidget(
      buildApp(seed: selectedSource(trimStartMs: 30000, trimEndMs: 30000)),
    );
    await tester.pump();

    expect(find.text('出点必须大于入点'), findsOneWidget);
  });

  screenTest('区间有效时开始转换按钮可用', (tester) async {
    await tester.pumpWidget(buildApp(seed: selectedSource()));
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始转换'),
    );
    expect(button.onPressed, isNotNull);
    expect(find.text('出点必须大于入点'), findsNothing);
  });

  screenTest('无音轨时给出拦截提示', (tester) async {
    await tester.pumpWidget(
      buildApp(
        seed: selectedSource().copyWith(sourceInfo: AudioSourceInfo.noAudio),
      ),
    );
    await tester.pump();

    // findsOneWidget 同时钉住「无音轨只报一次」：该文案既在 blockingError 里，
    // 也曾有独立的无音轨条，两处都渲染就会变成 2
    expect(find.text('该视频没有音频轨道，无法提取音频'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '开始转换'),
    );
    expect(button.onPressed, isNull);
  });

  screenTest('已有错误提示时不再叠一条阻断条', (tester) async {
    await tester.pumpWidget(
      buildApp(
        seed: selectedSource().copyWith(
          sourceInfo: AudioSourceInfo.noAudio,
          error: '该视频没有音频轨道，无法提取音频',
        ),
      ),
    );
    await tester.pump();

    // 同一时刻只给一条消息（否则这里会是 2）
    expect(find.text('该视频没有音频轨道，无法提取音频'), findsOneWidget);
  });

  // 「快退 1s / 快进 1s」按 TrimRangeControl 的契约步进**播放头**（与编辑器一致），
  // 不是挪动入点：若去推入点，连点几下就能把入点顶到出点，让按钮无解释地变灰。
  screenTest('步进按钮移动播放头而非区间', (tester) async {
    await tester.pumpWidget(
      buildApp(
        seed: selectedSource(
          trimStartMs: 2000,
          trimEndMs: 50000,
          durationMs: 70000,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('00:00:02.000'), findsOneWidget); // 入点
    expect(find.text('00:00:50.000'), findsOneWidget); // 出点

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '快进 1s'));

    // 逐次点击后都要断言：若两次点击之间入点被推动、又被下一次点击推回来，
    // 只看最终状态是看不出来的
    await tester.tap(find.widgetWithText(OutlinedButton, '快进 1s'));
    await tester.pump();
    expect(find.text('00:00:03.000'), findsNothing);
    expect(find.text('00:00:02.000'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '快退 1s'));
    await tester.pump();
    expect(find.text('00:00:01.000'), findsNothing);
    expect(find.text('00:00:02.000'), findsOneWidget);
    expect(find.text('00:00:50.000'), findsOneWidget);
  });

  // 探测中入点/出点都还是 0，此时报「出点必须大于入点」是误导
  screenTest('探测中不报出点问题', (tester) async {
    await tester.pumpWidget(
      buildApp(
        seed: AudioState(
          sourcePath: '/nope/video.mp4',
          sourceName: 'video.mp4',
          outputDirectory: '/nope',
          isProbing: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('出点必须大于入点'), findsNothing);
  });
}
