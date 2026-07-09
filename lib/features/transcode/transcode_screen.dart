/// 转码页面
///
/// 独立的 HVC1 到 H264 转码功能
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as p;
import 'transcode_viewmodel.dart';
import '../../ui/theme/colors.dart';

class TranscodeScreen extends ConsumerStatefulWidget {
  const TranscodeScreen({super.key});

  @override
  ConsumerState<TranscodeScreen> createState() => _TranscodeScreenState();
}

class _TranscodeScreenState extends ConsumerState<TranscodeScreen> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transcodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '视频转码',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 输入文件路径
            _buildInputPathSection(state),
            const SizedBox(height: 12),

            // 输出文件路径
            _buildOutputPathSection(state),
            const SizedBox(height: 16),

            // 进度显示
            if (state.isTranscoding) ...[
              _buildProgressIndicator(state),
              const SizedBox(height: 16),
            ],

            // 错误消息
            if (state.error != null) ...[
              _buildErrorMessage(state.error!),
              const SizedBox(height: 16),
            ],

            // 成功消息
            if (state.successMessage != null) ...[
              _buildSuccessMessage(state.successMessage!),
              const SizedBox(height: 16),
            ],

            // 开始转码按钮
            _buildTranscodeButton(state),

            const Spacer(),

            // 拖拽提示区域
            _buildDropArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPathSection(TranscodeState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              state.inputPath ?? '选择或拖入视频文件',
              style: TextStyle(
                fontSize: 13,
                color: state.inputPath != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: state.isTranscoding ? null : _pickInputFile,
            icon: const Icon(Icons.folder_open, size: 18),
            label: const Text('选择文件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputPathSection(TranscodeState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outline),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              state.outputPath ?? '保存路径',
              style: TextStyle(
                fontSize: 13,
                color: state.outputPath != null
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: state.isTranscoding ? null : _pickOutputPath,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('保存路径'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(TranscodeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress / 100,
                  backgroundColor: AppColors.outline,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${state.progress}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                ref.read(transcodeProvider.notifier).cancelTranscode();
              },
              icon: const Icon(Icons.stop, size: 16, color: AppColors.error),
              label: const Text(
                '取消转码',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              ref.read(transcodeProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: AppColors.success),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscodeButton(TranscodeState state) {
    final canTranscode = state.inputPath != null &&
        state.outputPath != null &&
        !state.isTranscoding;

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: canTranscode
            ? () {
                ref.read(transcodeProvider.notifier).startTranscode();
              }
            : null,
        icon: state.isTranscoding
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.video_file, size: 18),
        label: Text(state.isTranscoding ? '转码中...' : '开始转码'),
        style: ElevatedButton.styleFrom(
          backgroundColor: canTranscode ? AppColors.primary : AppColors.outline,
          foregroundColor: canTranscode ? Colors.white : AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildDropArea() {
    return DropTarget(
      onDragEntered: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onDragExited: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      onDragDone: (details) {
        setState(() {
          _isDragging = false;
        });
        if (details.files.isNotEmpty) {
          final file = details.files.first;
          ref.read(transcodeProvider.notifier).setInputPath(file.path);
        }
      },
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: _isDragging
              ? AppColors.primaryContainer
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isDragging ? AppColors.primary : AppColors.outline,
            width: _isDragging ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 32,
              color: _isDragging ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              _isDragging ? '释放以添加视频' : '拖拽视频文件到此处',
              style: TextStyle(
                fontSize: 13,
                color: _isDragging ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickInputFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        ref.read(transcodeProvider.notifier).setInputPath(result.files.first.path!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Future<void> _pickOutputPath() async {
    final state = ref.read(transcodeProvider);
    final inputPath = state.inputPath;

    String? initialDirectory;
    String? suggestedName;

    if (inputPath != null) {
      initialDirectory = p.dirname(inputPath);
      final name = p.basenameWithoutExtension(inputPath);
      final ext = p.extension(inputPath);
      suggestedName = '$name-h264$ext';
    }

    try {
      final result = await FilePicker.platform.saveFile(
        dialogTitle: '选择保存路径',
        fileName: suggestedName ?? 'output.mp4',
        initialDirectory: initialDirectory,
        type: FileType.video,
        allowedExtensions: ['mp4'],
      );

      if (result != null) {
        ref.read(transcodeProvider.notifier).setOutputPath(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择保存路径失败: $e')),
        );
      }
    }
  }
}
