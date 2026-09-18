import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/core/model/video_item.dart';
import 'package:cutflow_flutter/features/editor/widgets/video_preview_panel.dart';

VideoItem _video(String path, String name) => VideoItem(
      id: 0,
      path: path,
      name: name,
      duration: 60000,
      width: 1920,
      height: 1080,
      fileSize: 1024,
      frameRate: 30,
      codec: 'h264',
      importedAt: 0,
    );

Widget _app(VideoItem video) => MaterialApp(
      home: Scaffold(body: VideoPreviewPanel(video: video)),
    );

/// 挂载/更新预览面板，并等待组件内部的 dart:io 文件检查完成
///
/// 组件用 `File.exists()` 做真实磁盘 IO，`testWidgets` 默认的假异步环境
/// 不会让它完成，必须放在 `runAsync` 里才能真正跑到「文件不存在」分支。
Future<void> _mountAndSettleIo(WidgetTester tester, VideoItem video) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_app(video));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
}

void main() {
  testWidgets('文件不存在时显示错误', (tester) async {
    await _mountAndSettleIo(tester, _video('/nope/a.mp4', 'a.mp4'));

    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);
  });

  testWidgets('切换 video.path 时重新初始化（错误信息随之更新）', (tester) async {
    await _mountAndSettleIo(tester, _video('/nope/a.mp4', 'a.mp4'));
    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);

    // 换一个文件
    await _mountAndSettleIo(tester, _video('/nope/b.mp4', 'b.mp4'));

    expect(find.textContaining('/nope/b.mp4'), findsOneWidget);
    expect(find.textContaining('/nope/a.mp4'), findsNothing);
  });

  testWidgets('同一路径重建不触发重复初始化', (tester) async {
    await _mountAndSettleIo(tester, _video('/nope/a.mp4', 'a.mp4'));
    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);

    // 相同 path 但不同 VideoItem 实例 —— 不应重新初始化。
    // 这里故意不等文件检查：若触发了重新初始化，错误状态会被清空、退回加载中。
    await tester.runAsync(() async {
      await tester.pumpWidget(_app(_video('/nope/a.mp4', 'a.mp4')));
    });

    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    expect(find.textContaining('/nope/a.mp4'), findsOneWidget);
  });
}
