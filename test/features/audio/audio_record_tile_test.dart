import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutflow_flutter/core/model/audio_task.dart';
import 'package:cutflow_flutter/features/audio/widgets/audio_record_tile.dart';

AudioTask _task({
  AudioTaskStatus status = AudioTaskStatus.done,
  String? errorMessage,
  int trimStartMs = 0,
  int trimEndMs = 60000,
}) {
  return AudioTask(
    id: 1,
    sourcePath: '/in/video.mp4',
    sourceName: 'video.mp4',
    sourceDurationMs: 180000,
    trimStartMs: trimStartMs,
    trimEndMs: trimEndMs,
    title: '晴天',
    artist: '周杰伦',
    album: '叶惠美',
    targetBitrateKbps: 320,
    outputName: '晴天.mp3',
    status: status,
    progress: 100,
    errorMessage: errorMessage,
    createdAt: 0,
  );
}

Future<void> _pump(
  WidgetTester tester,
  AudioTask task, {
  bool fileExists = true,
  VoidCallback? onOpen,
  VoidCallback? onDelete,
  VoidCallback? onRetry,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: AudioRecordTile(
        task: task,
        fileExists: fileExists,
        onOpen: onOpen ?? () {},
        onDelete: onDelete ?? () {},
        onRetry: onRetry ?? () {},
      ),
    ),
  ));
}

void main() {
  testWidgets('已完成且产物存在时可打开所在文件夹', (tester) async {
    var opened = 0;
    await _pump(tester, _task(), onOpen: () => opened++);

    await tester.tap(find.byIcon(Icons.folder_open));
    expect(opened, equals(1));
    // 已完成的记录没有重试入口
    expect(find.byIcon(Icons.refresh), findsNothing);
  });

  testWidgets('已完成但产物文件已不在时不显示打开按钮', (tester) async {
    await _pump(tester, _task(), fileExists: false);

    expect(find.byIcon(Icons.folder_open), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('失败记录显示错误信息并可回填重试', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      _task(status: AudioTaskStatus.failed, errorMessage: '转换失败: 磁盘已满'),
      onRetry: () => retried++,
    );

    expect(find.text('转换失败'), findsOneWidget);
    expect(find.text('转换失败: 磁盘已满'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    expect(retried, equals(1));
  });

  testWidgets('摘要与输出区间文案', (tester) async {
    await _pump(tester, _task(trimStartMs: 30000, trimEndMs: 90000));

    expect(find.text('晴天 · 周杰伦 · 叶惠美'), findsOneWidget);
    expect(find.text('01:00 · 320 kbps'), findsOneWidget);
  });
}
