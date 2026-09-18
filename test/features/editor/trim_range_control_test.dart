import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cutflow_flutter/features/editor/widgets/trim_range_control.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

TrimRangeControl _control({
  String stepBackwardLabel = '逐帧向前',
  String stepForwardLabel = '逐帧向后',
}) {
  return TrimRangeControl(
    durationMs: 60000,
    trimStartMs: 0,
    trimEndMs: 60000,
    currentPositionMs: 0,
    onSetStart: () {},
    onSetEnd: () {},
    onTrimStartManualChanged: (_) {},
    onTrimEndManualChanged: (_) {},
    frameRate: 0,
    onStepForward: () {},
    onStepBackward: () {},
    stepBackwardLabel: stepBackwardLabel,
    stepForwardLabel: stepForwardLabel,
  );
}

void main() {
  testWidgets('默认显示逐帧文案（现有调用方行为不变）', (tester) async {
    await tester.pumpWidget(_wrap(_control()));
    expect(find.text('逐帧向前'), findsOneWidget);
    expect(find.text('逐帧向后'), findsOneWidget);
  });

  testWidgets('可自定义步进按钮文案', (tester) async {
    await tester.pumpWidget(_wrap(_control(
      stepBackwardLabel: '快退 1s',
      stepForwardLabel: '快进 1s',
    )));
    expect(find.text('快退 1s'), findsOneWidget);
    expect(find.text('快进 1s'), findsOneWidget);
    expect(find.text('逐帧向前'), findsNothing);
  });
}
