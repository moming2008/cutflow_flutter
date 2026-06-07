/// 裁切面板右侧信息区
library;

import 'package:flutter/material.dart';
import '../../../ui/theme/colors.dart';
import 'crop_canvas.dart';

class CropInfoPanel extends StatelessWidget {
  final int sourceWidth;
  final int sourceHeight;
  final CropGuides? guides;

  const CropInfoPanel({
    super.key,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.guides,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '裁切参数',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow('源视频分辨率', '$sourceWidth × $sourceHeight'),
          const SizedBox(height: 12),
          const Divider(color: AppColors.outline),
          const SizedBox(height: 12),

          if (guides != null) ...[
            _buildValueRow('宽度 W', '${guides!.cropW}', 'px'),
            const SizedBox(height: 8),
            _buildValueRow('高度 H', '${guides!.cropH}', 'px'),
            const SizedBox(height: 8),
            _buildValueRow('X 偏移', '${guides!.offsetX}', 'px'),
            const SizedBox(height: 8),
            _buildValueRow('Y 偏移', '${guides!.offsetY}', 'px'),
            const SizedBox(height: 12),
            const Divider(color: AppColors.outline),
            const SizedBox(height: 12),
            _buildInfoRow('裁切后尺寸', '${guides!.cropW} × ${guides!.cropH}'),
          ] else
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  '点击「添加裁切线」开始',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildValueRow(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text('$value $unit', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary, fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
