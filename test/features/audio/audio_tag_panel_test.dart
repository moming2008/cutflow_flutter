import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cutflow_flutter/features/audio/widgets/audio_tag_panel.dart';

/// 模拟音频页的宿主：文本状态由父级持有，onChanged 后原样传回
/// （与 AudioScreen 的 `notifier.setTitle` → 重建 完全同构）
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String _title = '晴天';
  String _artist = '';
  String _album = '';

  /// 供测试模拟「外部回填」（如从历史记录恢复参数）
  void setTitleExternally(String value) => setState(() => _title = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: AudioTagPanel(
          title: _title,
          artist: _artist,
          album: _album,
          coverPath: null,
          enabled: true,
          onTitleChanged: (value) => setState(() => _title = value),
          onArtistChanged: (value) => setState(() => _artist = value),
          onAlbumChanged: (value) => setState(() => _album = value),
          onCoverChanged: (_) {},
        ),
      ),
    );
  }
}

void main() {
  Finder titleField() => find.byType(TextField).at(0);

  testWidgets('敲字时控制器不被替换，光标保持在中部', (tester) async {
    await tester.pumpWidget(const _Host());

    final controllerBefore = tester.widget<TextField>(titleField()).controller!;
    expect(controllerBefore.text, equals('晴天'));

    // 聚焦后经输入法通道送入一次「在中间插字」的编辑值：
    // 文本变为「晴X天」，光标停在 X 之后（offset 2）
    await tester.showKeyboard(titleField());
    tester.testTextInput.updateEditingValue(const TextEditingValue(
      text: '晴X天',
      selection: TextSelection.collapsed(offset: 2),
    ));
    await tester.pump();

    final controllerAfter = tester.widget<TextField>(titleField()).controller!;
    // 若控制器在 build() 里就地创建，这里会拿到一个全新的实例，
    // 且其光标被强制拨到文本末尾（offset 3）
    expect(identical(controllerBefore, controllerAfter), isTrue);
    expect(controllerAfter.text, equals('晴X天'));
    expect(controllerAfter.selection.baseOffset, equals(2));
  });

  testWidgets('外部回填时输入框跟随更新', (tester) async {
    await tester.pumpWidget(const _Host());
    expect(tester.widget<TextField>(titleField()).controller!.text,
        equals('晴天'));

    // 与 restoreFromTask 同构：值来自外部而非用户输入
    tester.state<_HostState>(find.byType(_Host)).setTitleExternally('叶惠美');
    await tester.pump();

    expect(tester.widget<TextField>(titleField()).controller!.text,
        equals('叶惠美'));
  });

  testWidgets('未选封面时不显示清除按钮', (tester) async {
    await tester.pumpWidget(const _Host());

    expect(find.text('选择图片'), findsOneWidget);
    expect(find.text('清除'), findsNothing);
  });

  testWidgets('已选封面时可清除，点击回传 null', (tester) async {
    String? coverPath = '/nope/cover.jpg'; // 文件不存在走 errorBuilder 兜底

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => AudioTagPanel(
            title: '',
            artist: '',
            album: '',
            coverPath: coverPath,
            enabled: true,
            onTitleChanged: (_) {},
            onArtistChanged: (_) {},
            onAlbumChanged: (_) {},
            onCoverChanged: (value) => setState(() => coverPath = value),
          ),
        ),
      ),
    ));

    expect(find.text('更换图片'), findsOneWidget);

    await tester.tap(find.text('清除'));
    await tester.pump();

    expect(find.text('选择图片'), findsOneWidget);
    expect(find.text('清除'), findsNothing);
  });
}
