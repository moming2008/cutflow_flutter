/// 剪辑范围控制组件
///
/// PR 风格入点/出点交互：
/// - 进度条显示已选范围高亮
/// - 入点/出点时间码可点击编辑
/// - 设定按钮使用当前播放器位置
library;

import 'package:flutter/material.dart';
import '../../../core/util/time_formatter.dart';
import '../../../ui/theme/colors.dart';

class TrimRangeControl extends StatelessWidget {
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int currentPositionMs;
  final VoidCallback onSetStart;
  final VoidCallback onSetEnd;
  final ValueChanged<int> onTrimStartManualChanged;
  final ValueChanged<int> onTrimEndManualChanged;
  final ValueChanged<double>? onSliderChanged;

  const TrimRangeControl({
    super.key,
    required this.durationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.currentPositionMs,
    required this.onSetStart,
    required this.onSetEnd,
    required this.onTrimStartManualChanged,
    required this.onTrimEndManualChanged,
    this.onSliderChanged,
  });

  int get _trimDuration {
    if (trimEndMs > trimStartMs) return trimEndMs - trimStartMs;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '剪辑范围',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),

        // 进度条 + 范围高亮
        if (durationMs > 0) ...[
          _RangeSlider(
            durationMs: durationMs,
            trimStartMs: trimStartMs,
            trimEndMs: trimEndMs,
            currentPositionMs: currentPositionMs,
            onChanged: onSliderChanged,
          ),
        ],

        const SizedBox(height: 8),

        // 入点 / 出点 / 剪辑时长
        Row(
          children: [
            // 入点
            _TimeInputField(
              label: '入点',
              timeMs: trimStartMs,
              maxMs: durationMs,
              onConfirmed: onTrimStartManualChanged,
            ),
            const SizedBox(width: 16),
            // 剪辑时长
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                TimeFormatter.formatDuration(_trimDuration),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 16),
            // 出点
            _TimeInputField(
              label: '出点',
              timeMs: trimEndMs,
              maxMs: durationMs,
              onConfirmed: onTrimEndManualChanged,
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 设定按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSetStart,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('设定入点'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onSetEnd,
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('设定出点'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 范围进度条 — 显示当前位置 + 已选范围高亮
class _RangeSlider extends StatelessWidget {
  final int durationMs;
  final int trimStartMs;
  final int trimEndMs;
  final int currentPositionMs;
  final ValueChanged<double>? onChanged;

  const _RangeSlider({
    required this.durationMs,
    required this.trimStartMs,
    required this.trimEndMs,
    required this.currentPositionMs,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final duration = durationMs.toDouble();
    final start = trimStartMs.toDouble().clamp(0, duration);
    final end = trimEndMs.toDouble().clamp(0, duration);
    final current = currentPositionMs.toDouble().clamp(0, duration);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final trackHeight = 4.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (details) {
            if (onChanged != null) {
              final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
              onChanged!(ratio * duration);
            }
          },
          onTapUp: (details) {
            if (onChanged != null) {
              final ratio = (details.localPosition.dx / width).clamp(0.0, 1.0);
              onChanged!(ratio * duration);
            }
          },
          child: SizedBox(
            height: 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 轨道背景
                Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 已选范围高亮
                if (end > start)
                  Positioned(
                    left: (start / duration) * width,
                    right: width - (end / duration) * width,
                    child: Container(
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                // 入点标记
                if (duration > 0)
                  Positioned(
                    left: (start / duration) * width - 1,
                    child: Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                // 出点标记
                if (duration > 0)
                  Positioned(
                    left: (end / duration) * width - 1,
                    child: Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                // 当前位置指示器
                if (duration > 0)
                  Positioned(
                    left: (current / duration) * width - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 可点击编辑的时间码输入组件
class _TimeInputField extends StatefulWidget {
  final String label;
  final int timeMs;
  final int maxMs;
  final ValueChanged<int> onConfirmed;

  const _TimeInputField({
    required this.label,
    required this.timeMs,
    required this.maxMs,
    required this.onConfirmed,
  });

  @override
  State<_TimeInputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends State<_TimeInputField> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _confirm();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    setState(() {
      _isEditing = true;
      _controller.text = TimeFormatter.formatDuration(widget.timeMs);
    });
    Future.microtask(() {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _confirm() {
    final parsed = _parseTimeCode(_controller.text);
    if (parsed != null && parsed >= 0 && parsed <= widget.maxMs) {
      widget.onConfirmed(parsed);
    }
    setState(() => _isEditing = false);
  }

  /// 解析时间码字符串为毫秒
  /// 支持格式: "MM:SS", "HH:MM:SS", "SS" (纯秒数)
  int? _parseTimeCode(String input) {
    input = input.trim();
    if (input.isEmpty) return null;

    final parts = input.split(':');
    try {
      if (parts.length == 1) {
        // 纯秒数
        final seconds = int.parse(parts[0]);
        return seconds * 1000;
      } else if (parts.length == 2) {
        // MM:SS
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60 + seconds) * 1000;
      } else if (parts.length == 3) {
        // HH:MM:SS
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final seconds = int.parse(parts[2]);
        return (hours * 3600 + minutes * 60 + seconds) * 1000;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.label} ',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        _isEditing
            ? SizedBox(
                width: 64,
                height: 26,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.visiblePassword,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _confirm(),
                ),
              )
            : GestureDetector(
                onTap: _startEdit,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.outline,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      TimeFormatter.formatDuration(widget.timeMs),
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        color: widget.timeMs > 0
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }
}
