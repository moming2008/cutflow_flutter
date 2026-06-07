/// 编辑器表单面板
///
/// 右侧面板，包含：
/// - 输出文件名 + 后缀输入框
/// - 剪辑范围控制
/// - 裁切模式选择 (原始/预设/自定义)
/// - 预设/原始裁切数据只读展示
/// - 取消 / 确认加入队列 按钮
library;

import 'package:flutter/material.dart';
import '../../../core/model/crop_preset.dart';
import '../../../ui/theme/colors.dart';
import '../editor_viewmodel.dart';
import 'trim_range_control.dart';

class EditorFormPanel extends StatefulWidget {
  final String outputName;
  final String outputSuffix;
  final ValueChanged<String> onOutputNameChanged;
  final ValueChanged<String> onOutputSuffixChanged;
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
  final VoidCallback? onOpenCropPanel;
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int currentPositionMs;
  final VoidCallback onSetTrimStart;
  final VoidCallback onSetTrimEnd;
  final ValueChanged<int> onTrimStartManualChanged;
  final ValueChanged<int> onTrimEndManualChanged;
  final ValueChanged<double>? onSliderChanged;
  final double frameRate;
  final VoidCallback onStepForward;
  final VoidCallback onStepBackward;
  final List<CropPreset> cropPresets;
  final int videoWidth;
  final int videoHeight;
  final Map<String, String> errors;
  final bool isSubmitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const EditorFormPanel({
    super.key,
    required this.outputName,
    required this.outputSuffix,
    required this.onOutputNameChanged,
    required this.onOutputSuffixChanged,
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
    this.onOpenCropPanel,
    required this.durationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.currentPositionMs,
    required this.onSetTrimStart,
    required this.onSetTrimEnd,
    required this.onTrimStartManualChanged,
    required this.onTrimEndManualChanged,
    this.onSliderChanged,
    required this.frameRate,
    required this.onStepForward,
    required this.onStepBackward,
    required this.cropPresets,
    required this.videoWidth,
    required this.videoHeight,
    required this.errors,
    required this.isSubmitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<EditorFormPanel> createState() => _EditorFormPanelState();
}

class _EditorFormPanelState extends State<EditorFormPanel> {
  late TextEditingController _nameController;
  late TextEditingController _suffixController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.outputName);
    _suffixController = TextEditingController(text: widget.outputSuffix);
  }

  @override
  void didUpdateWidget(covariant EditorFormPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 仅当外部值与当前文本不同时更新，避免打断 IME 组合
    if (widget.outputName != _nameController.text) {
      _nameController.text = widget.outputName;
      _nameController.selection = TextSelection.collapsed(
        offset: _nameController.text.length,
      );
    }
    if (widget.outputSuffix != _suffixController.text) {
      _suffixController.text = widget.outputSuffix;
      _suffixController.selection = TextSelection.collapsed(
        offset: _suffixController.text.length,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _suffixController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 可滚动表单区域
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 输出文件名 + 后缀
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
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameController,
                        onChanged: widget.onOutputNameChanged,
                        decoration: InputDecoration(
                          hintText: '请输入输出文件名',
                          errorText: widget.errors['outputName'],
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
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _suffixController,
                        onChanged: widget.onOutputSuffixChanged,
                        decoration: InputDecoration(
                          hintText: '-crop',
                          suffixText: '.mp4',
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
                            horizontal: 12,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 剪辑范围
                TrimRangeControl(
                  durationMs: widget.durationMs,
                  trimStartMs: widget.trimStartMs,
                  trimEndMs: widget.trimEndMs,
                  currentPositionMs: widget.currentPositionMs,
                  onSetStart: widget.onSetTrimStart,
                  onSetEnd: widget.onSetTrimEnd,
                  onTrimStartManualChanged: widget.onTrimStartManualChanged,
                  onTrimEndManualChanged: widget.onTrimEndManualChanged,
                  onSliderChanged: widget.onSliderChanged,
                  frameRate: widget.frameRate,
                  onStepForward: widget.onStepForward,
                  onStepBackward: widget.onStepBackward,
                ),

                if (widget.errors['trim'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.errors['trim']!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // 裁切
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
                      selected: widget.selectedCropPresetId == null,
                      onSelected: (_) => widget.onCropModeChanged(null),
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedCropPresetId == null
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: widget.selectedCropPresetId == null
                            ? AppColors.primary
                            : AppColors.outline,
                      ),
                    ),
                    ...widget.cropPresets.map((preset) {
                      final isSelected =
                          widget.selectedCropPresetId == preset.id;
                      return ChoiceChip(
                        label: Text(preset.name),
                        selected: isSelected,
                        onSelected: (_) => widget.onCropModeChanged(preset.id),
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
                      selected:
                          widget.selectedCropPresetId == kCustomCropSentinel,
                      onSelected: (_) =>
                          widget.onCropModeChanged(kCustomCropSentinel),
                      selectedColor: AppColors.primaryContainer,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: widget.selectedCropPresetId == kCustomCropSentinel
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color: widget.selectedCropPresetId == kCustomCropSentinel
                            ? AppColors.primary
                            : AppColors.outline,
                      ),
                    ),
                  ],
                ),

                // 原始模式：展示视频尺寸
                if (widget.selectedCropPresetId == null) ...[
                  const SizedBox(height: 12),
                  _buildReadOnlyCropInfo(
                    w: widget.videoWidth,
                    h: widget.videoHeight,
                    x: 0,
                    y: 0,
                  ),
                ],

                // 预设模式：展示预设数据
                if (widget.selectedCropPresetId != null &&
                    widget.selectedCropPresetId != kCustomCropSentinel) ...[
                  const SizedBox(height: 12),
                  _buildPresetReadOnlyInfo(),
                ],

                // 自定义裁切参数
                if (widget.selectedCropPresetId == kCustomCropSentinel) ...[
                  const SizedBox(height: 12),
                  if (widget.onOpenCropPanel != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton.icon(
                        onPressed: widget.onOpenCropPanel,
                        icon: const Icon(Icons.crop_free, size: 16),
                        label: const Text('可视化裁切'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                        ),
                      ),
                    ),
                  // 宽度和高度一行
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropInputField(
                          label: '宽度',
                          value: widget.customCropW,
                          onChanged: widget.onCustomCropWChanged,
                          hint: '像素',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCropInputField(
                          label: '高度',
                          value: widget.customCropH,
                          onChanged: widget.onCustomCropHChanged,
                          hint: '像素',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // X偏移和Y偏移一行
                  Row(
                    children: [
                      Expanded(
                        child: _buildCropInputField(
                          label: 'X偏移',
                          value: widget.customCropX,
                          onChanged: widget.onCustomCropXChanged,
                          hint: '默认 0',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCropInputField(
                          label: 'Y偏移',
                          value: widget.customCropY,
                          onChanged: widget.onCustomCropYChanged,
                          hint: '默认 0',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // 固定底部区域：错误提示 + 按钮
        if (widget.errors['general'] != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              widget.errors['general']!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.isSubmitting ? null : widget.onCancel,
                child: const Text('取消'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: widget.isSubmitting ? null : widget.onSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: widget.isSubmitting
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
        ),
      ],
    );
  }

  /// 只读裁切信息展示（原始模式）
  Widget _buildReadOnlyCropInfo({
    required int w,
    required int h,
    required int x,
    required int y,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          _buildInfoChip('宽', '$w'),
          const SizedBox(width: 12),
          _buildInfoChip('高', '$h'),
          const SizedBox(width: 12),
          _buildInfoChip('X', '$x'),
          const SizedBox(width: 12),
          _buildInfoChip('Y', '$y'),
        ],
      ),
    );
  }

  /// 预设模式的只读信息
  Widget _buildPresetReadOnlyInfo() {
    final preset = widget.cropPresets.where((p) => p.id == widget.selectedCropPresetId).firstOrNull;
    if (preset == null) return const SizedBox.shrink();
    return _buildReadOnlyCropInfo(
      w: preset.outputW,
      h: preset.outputH,
      x: preset.offsetX,
      y: preset.offsetY,
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCropInputField({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 32,
          child: TextFormField(
            key: ValueKey(value),
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
      ],
    );
  }
}
