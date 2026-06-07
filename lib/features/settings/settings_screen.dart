/// 设置页面
///
/// 包含导出目录设置和裁切预设管理。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'settings_viewmodel.dart';
import 'widgets/crop_preset_edit_dialog.dart';
import '../../ui/theme/colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 导出设置区
                _buildSectionTitle('导出设置'),
                const SizedBox(height: 8),
                _buildExportDirCard(context, state, ref),

                const SizedBox(height: 24),

                // 裁切预设区
                _buildSectionTitle('裁切预设'),
                const SizedBox(height: 8),
                ...state.presets.map((preset) {
                  return Card(
                    elevation: 0,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(
                        color: AppColors.outline,
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      title: Text(
                        preset.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${preset.outputW}×${preset.outputH}  偏移(${preset.offsetX}, ${preset.offsetY})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editPreset(
                              context,
                              ref,
                              preset,
                            ),
                            tooltip: '编辑',
                            color: AppColors.textSecondary,
                          ),
                          IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                              ),
                              onPressed: () => _deletePreset(
                                context,
                                ref,
                                preset,
                              ),
                              tooltip: '删除',
                              color: AppColors.textTertiary,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _addPreset(context, ref),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加预设'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildExportDirCard(
    BuildContext context,
    SettingsState state,
    WidgetRef ref,
  ) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.outline, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              Icons.folder_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '导出目录',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.exportDirectory,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _pickDirectory(ref),
              child: const Text('浏览...'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDirectory(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '选择导出目录',
    );
    if (result != null) {
      ref.read(settingsProvider.notifier).setExportDirectory(result);
    }
  }

  Future<void> _addPreset(BuildContext context, WidgetRef ref) async {
    final preset = await CropPresetEditDialog.show(context);
    if (preset != null) {
      ref.read(settingsProvider.notifier).addPreset(preset);
    }
  }

  Future<void> _editPreset(
    BuildContext context,
    WidgetRef ref,
    dynamic preset,
  ) async {
    final result = await CropPresetEditDialog.show(
      context,
      existing: preset,
    );
    if (result != null) {
      ref.read(settingsProvider.notifier).updatePreset(result);
    }
  }

  Future<void> _deletePreset(
    BuildContext context,
    WidgetRef ref,
    dynamic preset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除预设'),
        content: Text('确定要删除 "${preset.name}" 吗？'),
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
    if (confirmed == true) {
      ref.read(settingsProvider.notifier).deletePreset(preset.id);
    }
  }
}
