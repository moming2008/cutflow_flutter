/// 裁剪工作流容器页
///
/// 将「准备 / 转码队列 / 已转码」三个阶段合并到一个标签页，
/// 通过顶部分段控件切换，各阶段面板通过 IndexedStack 保活。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../preparation/preparation_screen.dart';
import '../preparation/preparation_viewmodel.dart';
import '../queue/queue_screen.dart';
import '../queue/queue_viewmodel.dart';
import '../completed/completed_screen.dart';
import '../completed/completed_viewmodel.dart';
import '../../ui/theme/colors.dart';

class ClipScreen extends ConsumerStatefulWidget {
  const ClipScreen({super.key});

  @override
  ConsumerState<ClipScreen> createState() => _ClipScreenState();
}

class _ClipScreenState extends ConsumerState<ClipScreen> {
  /// 当前阶段：0=准备 1=队列 2=已转码
  int _index = 0;

  /// 导入视频文件（准备阶段动作）
  Future<void> _importVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            await ref
                .read(preparationProvider.notifier)
                .importVideo(file.path!);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 各阶段数量，用于分段控件角标
    final prepCount = ref.watch(preparationProvider).videos.length;
    final queueCount = ref.watch(queueProvider).tasks.length;
    final completedCount = ref.watch(completedProvider).tasks.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '裁剪',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_index == 0) ...[
            TextButton.icon(
              onPressed: _importVideo,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('导入视频'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: Column(
        children: [
          _StageSwitcher(
            index: _index,
            prepCount: prepCount,
            queueCount: queueCount,
            completedCount: completedCount,
            onChanged: (i) => setState(() => _index = i),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.outline),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                PreparationPanel(),
                QueuePanel(),
                CompletedPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 阶段分段切换控件
class _StageSwitcher extends StatelessWidget {
  final int index;
  final int prepCount;
  final int queueCount;
  final int completedCount;
  final ValueChanged<int> onChanged;

  const _StageSwitcher({
    required this.index,
    required this.prepCount,
    required this.queueCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 0, label: Text(_label('准备', prepCount))),
            ButtonSegment(value: 1, label: Text(_label('队列', queueCount))),
            ButtonSegment(
              value: 2,
              label: Text(_label('已转码', completedCount)),
            ),
          ],
          selected: {index},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: SegmentedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );
  }

  String _label(String name, int count) => count > 0 ? '$name $count' : name;
}
