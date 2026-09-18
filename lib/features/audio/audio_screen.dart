/// 音频提取页面
///
/// 视频 → MP3，封装封面图与歌名/歌手/专辑 ID3 标签。
library;

import 'package:flutter/material.dart';

import '../../ui/theme/colors.dart';

class AudioScreen extends StatelessWidget {
  const AudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '音频提取',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          '音频提取页面',
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
