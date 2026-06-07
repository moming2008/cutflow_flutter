/// 裁切预设编辑对话框
///
/// 参考"自定义裁切"参数格式：名称 + W/H/X/Y 绝对像素值。
library;

import 'package:flutter/material.dart';
import '../../../core/model/crop_preset.dart';
import '../../../ui/theme/colors.dart';

class CropPresetEditDialog extends StatefulWidget {
  final CropPreset? existingPreset;

  const CropPresetEditDialog({super.key, this.existingPreset});

  static Future<CropPreset?> show(
    BuildContext context, {
    CropPreset? existing,
  }) {
    return showDialog<CropPreset>(
      context: context,
      builder: (_) => CropPresetEditDialog(existingPreset: existing),
    );
  }

  @override
  State<CropPresetEditDialog> createState() => _CropPresetEditDialogState();
}

class _CropPresetEditDialogState extends State<CropPresetEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _cropWCtrl;
  late TextEditingController _cropHCtrl;
  late TextEditingController _offsetXCtrl;
  late TextEditingController _offsetYCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPreset;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _cropWCtrl = TextEditingController(
      text: p != null && p.outputW > 0 ? p.outputW.toString() : '',
    );
    _cropHCtrl = TextEditingController(
      text: p != null && p.outputH > 0 ? p.outputH.toString() : '',
    );
    _offsetXCtrl = TextEditingController(
      text: p?.offsetX.toString() ?? '0',
    );
    _offsetYCtrl = TextEditingController(
      text: p?.offsetY.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cropWCtrl.dispose();
    _cropHCtrl.dispose();
    _offsetXCtrl.dispose();
    _offsetYCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final cropW = int.tryParse(_cropWCtrl.text) ?? 0;
    final cropH = int.tryParse(_cropHCtrl.text) ?? 0;
    final offsetX = int.tryParse(_offsetXCtrl.text) ?? 0;
    final offsetY = int.tryParse(_offsetYCtrl.text) ?? 0;

    if (name.isEmpty || cropW <= 0 || cropH <= 0) return;

    final preset = CropPreset(
      id: widget.existingPreset?.id ?? 0,
      name: name,
      ratioLabel: '',
      ratioW: 0,
      ratioH: 0,
      outputW: cropW,
      outputH: cropH,
      offsetX: offsetX,
      offsetY: offsetY,
      isBuiltin: false,
      sortOrder: widget.existingPreset?.sortOrder ?? 99,
    );

    Navigator.pop(context, preset);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingPreset != null;

    return AlertDialog(
      title: Text(isEdit ? '编辑预设' : '添加预设'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(_nameCtrl, '名称', '如: 横屏 1920x1080'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildField(_cropWCtrl, '宽度 W', '像素')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_cropHCtrl, '高度 H', '像素')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildField(_offsetXCtrl, 'X 偏移', '默认 0')),
                const SizedBox(width: 8),
                Expanded(child: _buildField(_offsetYCtrl, 'Y 偏移', '默认 0')),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? '保存' : '添加'),
        ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String hint,
  ) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}
