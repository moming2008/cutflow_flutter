/// 音频码率选择：左侧展示源码率供参考，右侧选择目标码率
library;

import 'package:flutter/material.dart';

import '../../../core/model/audio_source_info.dart';
import '../../../ui/theme/colors.dart';
import '../audio_viewmodel.dart';

class AudioBitrateSelector extends StatelessWidget {
  final AudioSourceInfo? sourceInfo;
  final int targetBitrateKbps;
  final bool enabled;
  final ValueChanged<int> onChanged;

  const AudioBitrateSelector({
    super.key,
    required this.sourceInfo,
    required this.targetBitrateKbps,
    required this.enabled,
    required this.onChanged,
  });

  /// 源码率展示文案
  String get _sourceLabel {
    final info = sourceInfo;
    if (info == null) return '源: 探测中…';
    if (!info.hasAudio) return '源: 无音频轨';
    final kbps = info.bitrateKbps;
    if (kbps == null) return '源: 未知';
    // 来自容器总码率时必须标注，避免用户误以为这是音轨码率
    if (info.bitrateIsApproximate) {
      return '源: 约 $kbps kbps（容器总码率，仅供参考）';
    }
    return '源: $kbps kbps';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 210,
          child: Text(
            _sourceLabel,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        const Text('目标',
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: targetBitrateKbps,
              isDense: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
              items: [
                for (final kbps in kAudioBitrateOptions)
                  DropdownMenuItem<int>(
                    value: kbps,
                    child: Text('$kbps kbps'),
                  ),
              ],
              onChanged: enabled
                  ? (value) {
                      if (value != null) onChanged(value);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
