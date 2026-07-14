/// 准备阶段面板
///
/// 显示尚未配置 ExportTask 的视频。
/// 点击视频打开编辑器弹窗，支持删除视频操作。
/// 导入动作由外层裁剪容器提供。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'preparation_viewmodel.dart';
import 'widgets/preparation_video_card.dart';
import '../editor/editor_dialog.dart';
import '../../ui/theme/colors.dart';

class PreparationPanel extends ConsumerStatefulWidget {
  const PreparationPanel({super.key});

  @override
  ConsumerState<PreparationPanel> createState() => _PreparationPanelState();
}

class _PreparationPanelState extends ConsumerState<PreparationPanel> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(preparationProvider.notifier).loadVideos();
    });
  }

  /// 显示删除确认对话框
  Future<void> _showDeleteDialog(int videoId, String videoName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除视频'),
        content: Text('确定要删除 "$videoName" 吗？\n关联的编辑草稿也会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(preparationProvider.notifier).deleteVideo(videoId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(preparationProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _buildError(state.error!);
    }
    if (state.videos.isEmpty) {
      return _buildEmpty();
    }
    return _buildList(state);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            '暂无视频',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '点击右上角「导入视频」按钮添加视频文件',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              ref.read(preparationProvider.notifier).loadVideos();
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildList(PreparationState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.videos.length,
      itemBuilder: (context, index) {
        final video = state.videos[index];
        final hasDraft = state.draftVideoIds.contains(video.id);
        return PreparationVideoCard(
          video: video,
          hasDraft: hasDraft,
          onTap: () async {
            final messenger = ScaffoldMessenger.of(context);
            final result = await EditorDialog.show(context, video.id);
            if (result && mounted) {
              ref.read(preparationProvider.notifier).loadVideos();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('已添加到转码队列'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onDelete: () => _showDeleteDialog(video.id, video.name),
        );
      },
    );
  }
}
