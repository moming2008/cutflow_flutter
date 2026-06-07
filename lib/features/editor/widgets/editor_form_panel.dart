/// 编辑器表单面板
///
/// 右侧面板，包含：
/// - 输出文件名输入框
/// - 裁切模式选择 (原始/自定义)
/// - 剪辑范围控制 (嵌入 TrimRangeControl)
/// - 取消 / 确认加入队列 按钮
library;

import 'package:flutter/material.dart';
import '../../../core/model/crop_preset.dart';
import '../../../ui/theme/colors.dart';
import '../editor_viewmodel.dart';
import 'trim_range_control.dart';

class EditorFormPanel extends StatelessWidget {
  final String outputName;
  final ValueChanged<String> onOutputNameChanged;
  final int? selectedCropPresetId; // null=原始, -1=自定义
  final ValueChanged<int?> onCropModeChanged;
  final int customCropW;
  final int customCropH;
  final int customCropX;
  final int customCropY;
  final ValueChanged<int> onCustomCropWChanged;
  final ValueChanged<int> onCustomCropHChanged;
  final ValueChanged<int> onCustomCropXChanged;
  final ValueChanged<int> onCustomCropYChanged;
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int currentPositionMs;
  final VoidCallback onSetTrimStart;
  final VoidCallback onSetTrimEnd;
  final ValueChanged<int> onTrimStartManualChanged;
  final ValueChanged<int> onTrimEndManualChanged;
  final ValueChanged<double>? onSliderChanged;
  final List<CropPreset> cropPresets;
  final Map<String, String> errors;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const EditorFormPanel({
    super.key,
    required this.outputName,
    required this.onOutputNameChanged,
    required this.selectedCropPresetId,
    required this.onCropModeChanged,
    required this.customCropW,
    required this.customCropH,
    required this.customCropX,
    required this.customCropY,
    required this.onCustomCropWChanged,
    required this.onCustomCropHChanged,
    required this.onCustomCropXChanged,
    required this.onCustomCropYChanged,
    required this.durationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.currentPositionMs,
    required this.onSetTrimStart,
    required this.onSetTrimEnd,
    required this.onTrimStartManualChanged,
    required this.onTrimEndManualChanged,
    this.onSliderChanged,
    required this.cropPresets,
    required this.errors,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 输出文件名
          const Text(
            '输出文件名',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: TextEditingController(text: outputName)
              ..selection = TextSelection.collapsed(offset: outputName.length),
            onChanged: onOutputNameChanged,
            decoration: InputDecoration(
              hintText: '请输入输出文件名',
              suffixText: '.mp4',
              errorText: errors['outputName'],
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),

          const SizedBox(height: 20),

          // 裁切模式
          const Text(
            '裁切',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('原始'),
                selected: selectedCropPresetId == null,
                onSelected: (_) => onCropModeChanged(null),
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedCropPresetId == null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: selectedCropPresetId == null
                      ? AppColors.primary
                      : AppColors.outline,
                ),
              ),
              ...cropPresets.map((preset) {
                final isSelected = selectedCropPresetId == preset.id;
                return ChoiceChip(
                  label: Text(preset.name),
                  selected: isSelected,
                  onSelected: (_) => onCropModeChanged(preset.id),
                  selectedColor: AppColors.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.outline,
                  ),
                );
              }),
              ChoiceChip(
                label: const Text('自定义'),
                selected: selectedCropPresetId == kCustomCropSentinel,
                onSelected: (_) => onCropModeChanged(kCustomCropSentinel),
                selectedColor: AppColors.primaryContainer,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: selectedCropPresetId == kCustomCropSentinel
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                side: BorderSide(
                  color: selectedCropPresetId == kCustomCropSentinel
                      ? AppColors.primary
                      : AppColors.outline,
                ),
              ),
            ],
          ),

          // 自定义裁切参数（仅选中"自定义"时显示）
          if (selectedCropPresetId == kCustomCropSentinel) ...[
            const SizedBox(height: 12),
            _buildCropInputRow(
              label: '宽度',
              value: customCropW,
              onChanged: onCustomCropWChanged,
              hint: '像素',
            ),
            const SizedBox(height: 8),
            _buildCropInputRow(
              label: '高度',
              value: customCropH,
              onChanged: onCustomCropHChanged,
              hint: '像素',
            ),
            const SizedBox(height: 8),
            _buildCropInputRow(
              label: 'X偏移',
              value: customCropX,
              onChanged: onCustomCropXChanged,
              hint: '默认 0',
            ),
            const SizedBox(height: 8),
            _buildCropInputRow(
              label: 'Y偏移',
              value: customCropY,
              onChanged: onCustomCropYChanged,
              hint: '默认 0',
            ),
          ],

          const SizedBox(height: 20),

          // 剪辑范围
          TrimRangeControl(
            durationMs: durationMs,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            currentPositionMs: currentPositionMs,
            onSetStart: onSetTrimStart,
            onSetEnd: onSetTrimEnd,
            onTrimStartManualChanged: onTrimStartManualChanged,
            onTrimEndManualChanged: onTrimEndManualChanged,
            onSliderChanged: onSliderChanged,
          ),

          if (errors['trim'] != null) ...[
            const SizedBox(height: 4),
            Text(
              errors['trim']!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ],

          const Spacer(),

          // 通用错误提示
          if (errors['general'] != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                errors['general']!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 底部按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: isSubmitting ? null : onCancel,
                child: const Text('取消'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isSubmitting ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('确认加入队列'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropInputRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required String hint,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: TextFormField(
              initialValue: value > 0 ? value.toString() : '',
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                isDense: true,
              ),
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              onChanged: (text) {
                final parsed = int.tryParse(text);
                if (parsed != null && parsed >= 0) {
                  onChanged(parsed);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
