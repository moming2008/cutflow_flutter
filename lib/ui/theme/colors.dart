/// 应用配色方案 - 蓝色主题
library;

import 'package:flutter/material.dart';

class AppColors {
  // === 主色调 ===
  static const primary = Color(0xFF2563EB);       // Trust Blue
  static const primaryLight = Color(0xFF3B82F6);  // Blue 500
  static const primaryDark = Color(0xFF1D4ED8);   // Blue 700
  static const primaryContainer = Color(0xFFDBEAFE); // Blue 50 (选中/高亮背景)

  // === 功能色 ===
  static const success = Color(0xFF16A34A);       // Green 600
  static const warning = Color(0xFFF59E0B);       // Amber 500
  static const error = Color(0xFFDC2626);         // Red 600
  static const info = Color(0xFF0EA5E9);          // Sky 500

  // === 中性色 ===
  static const background = Color(0xFFF8FAFC);    // Slate 50 (页面背景)
  static const surface = Colors.white;
  static const surfaceVariant = Color(0xFFF1F5F9); // Slate 100 (次级面板)
  static const cardBackground = Color(0xFFFAFAFA);

  // === 文本颜色 ===
  static const textPrimary = Color(0xFF0F172A);   // Slate 900
  static const textSecondary = Color(0xFF475569); // Slate 600
  static const textTertiary = Color(0xFF94A3B8);  // Slate 400
  static const textHint = Color(0xFFBDBDBD);

  // === 边框/分割线 ===
  static const outline = Color(0xFFE2E8F0);       // Slate 200
  static const divider = Color(0xFFE2E8F0);

  // === 侧栏专用 ===
  static const sidebarBackground = Color(0xFF0F172A);  // Slate 900
  static const sidebarText = Color(0xFFCBD5E1);        // Slate 300
  static const sidebarSelectedBg = Color(0xFF1E293B);  // Slate 800
  static const sidebarSelectedText = Color(0xFFFFFFFF);
  static const sidebarIcon = Color(0xFF64748B);        // Slate 500
  static const sidebarSelectedIcon = Color(0xFFFFFFFF);

  // === 状态标签色 ===
  static const statusPending = Color(0xFF64748B);
  static const statusExporting = Color(0xFF2563EB);
  static const statusDone = Color(0xFF16A34A);
  static const statusFailed = Color(0xFFDC2626);
}
