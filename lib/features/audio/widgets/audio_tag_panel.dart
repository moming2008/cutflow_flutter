/// 歌曲信息面板：歌名 / 歌手 / 专辑 + 封面选择
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../ui/theme/colors.dart';

class AudioTagPanel extends StatefulWidget {
  final String title;
  final String artist;
  final String album;
  final String? coverPath;
  final bool enabled;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onArtistChanged;
  final ValueChanged<String> onAlbumChanged;
  final ValueChanged<String?> onCoverChanged;

  const AudioTagPanel({
    super.key,
    required this.title,
    required this.artist,
    required this.album,
    required this.coverPath,
    required this.enabled,
    required this.onTitleChanged,
    required this.onArtistChanged,
    required this.onAlbumChanged,
    required this.onCoverChanged,
  });

  @override
  State<AudioTagPanel> createState() => _AudioTagPanelState();
}

class _AudioTagPanelState extends State<AudioTagPanel> {
  /// 三个输入框的控制器由 State 持有
  ///
  /// 不能在 build() 里就地 new：每次 onChanged → 父级重建都会换成一个
  /// 全新的控制器，并把光标强制拨到文本末尾，用户将无法在中间插字，
  /// 同时每个被换掉的控制器都不会被 dispose。
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _artistController = TextEditingController(text: widget.artist);
    _albumController = TextEditingController(text: widget.album);
  }

  @override
  void didUpdateWidget(covariant AudioTagPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅在外部值与输入框内容确实不同时才回写（如历史记录回填、
    // 从记录恢复参数）。用户自己敲字时父级会把同样的文本传回来，
    // 此时必须保持原样，否则每敲一个字符都要重建一次光标位置。
    _syncFromWidget(_titleController, widget.title);
    _syncFromWidget(_artistController, widget.artist);
    _syncFromWidget(_albumController, widget.album);
  }

  void _syncFromWidget(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.text = value;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '歌曲信息',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        _field(
          label: '歌名',
          hint: '留空则不写入标签，文件名用源文件名',
          controller: _titleController,
          onChanged: widget.onTitleChanged,
        ),
        const SizedBox(height: 8),
        _field(
          label: '歌手',
          hint: '留空则不写入标签',
          controller: _artistController,
          onChanged: widget.onArtistChanged,
        ),
        const SizedBox(height: 8),
        _field(
          label: '专辑',
          hint: '留空则不写入标签',
          controller: _albumController,
          onChanged: widget.onAlbumChanged,
        ),
        const SizedBox(height: 12),
        _coverRow(context),
      ],
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              enabled: widget.enabled,
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 12, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppColors.outline),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverRow(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 44,
          child: Text('封面',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ),
        _coverThumbnail(),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: widget.enabled ? () => _pickCover(context) : null,
          icon: const Icon(Icons.image_outlined, size: 16),
          label: Text(widget.coverPath == null ? '选择图片' : '更换图片'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        if (widget.coverPath != null) ...[
          const SizedBox(width: 6),
          TextButton.icon(
            onPressed:
                widget.enabled ? () => widget.onCoverChanged(null) : null,
            icon: const Icon(Icons.close, size: 14, color: AppColors.textTertiary),
            label: const Text('清除',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ),
        ],
      ],
    );
  }

  Widget _coverThumbnail() {
    final coverPath = widget.coverPath;
    if (coverPath == null) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.outline),
        ),
        child: const Icon(Icons.music_note, size: 18, color: AppColors.textHint),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.file(
        File(coverPath),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        // 用户可能选了非图片文件，兜底避免崩溃
        errorBuilder: (context, error, stack) => Container(
          width: 40,
          height: 40,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined,
              size: 18, color: AppColors.textHint),
        ),
      ),
    );
  }

  Future<void> _pickCover(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
        allowMultiple: false,
      );
      final path = result?.files.firstOrNull?.path;
      if (path != null) widget.onCoverChanged(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('选择封面失败: $e')));
      }
    }
  }
}
