/// 裁切画布 — 显示全分辨率帧，支持参考线拖拽
///
/// 不使用 InteractiveViewer（会抢占手势），改为 Listener 手动管理缩放/平移：
/// - 左键拖拽：拖拽参考线
/// - 右键/中键拖拽：平移画布
/// - 滚轮：缩放（以鼠标位置为中心）
library;

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../ui/theme/colors.dart';

/// 裁切线位置数据（帧像素坐标）
class CropGuides {
  final int left;
  final int right;
  final int top;
  final int bottom;

  const CropGuides({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });

  int get cropW => (right - left) & ~1;
  int get cropH => (bottom - top) & ~1;
  int get offsetX => left;
  int get offsetY => top;

  CropGuides copyWith({int? left, int? right, int? top, int? bottom}) {
    return CropGuides(
      left: left ?? this.left,
      right: right ?? this.right,
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
    );
  }
}

/// 可拖拽的参考线类型
enum GuideType { left, right, top, bottom }

class CropCanvas extends StatefulWidget {
  final String framePath;
  final int frameWidth;
  final int frameHeight;
  final ValueChanged<CropGuides> onGuidesChanged;

  const CropCanvas({
    super.key,
    required this.framePath,
    required this.frameWidth,
    required this.frameHeight,
    required this.onGuidesChanged,
  });

  @override
  State<CropCanvas> createState() => CropCanvasState();
}

class CropCanvasState extends State<CropCanvas> {
  CropGuides? _guides;
  GuideType? _draggingGuide;
  Offset? _dragStartFrame;
  CropGuides? _dragStartGuides;
  ui.Image? _frameImage;

  // 变换状态
  double _scale = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  double _fitScale = 1.0;
  bool _initialFitApplied = false;

  // 右键平移状态
  bool _isPanning = false;
  Offset? _panStartScreen;
  double _panStartOffsetX = 0.0;
  double _panStartOffsetY = 0.0;

  @override
  void initState() {
    super.initState();
    _loadFrame();
  }

  void _loadFrame() {
    final file = File(widget.framePath);
    if (!file.existsSync()) return;
    final bytes = file.readAsBytesSync();
    if (bytes.isEmpty) return;
    ui.decodeImageFromList(bytes, (image) {
      if (mounted) setState(() => _frameImage = image);
    });
  }

  /// 计算初始适应缩放（居中显示）
  void _applyInitialFit(double canvasW, double canvasH) {
    if (_initialFitApplied) return;
    final scaleX = canvasW / widget.frameWidth;
    final scaleY = canvasH / widget.frameHeight;
    _fitScale = scaleX < scaleY ? scaleX : scaleY;
    _scale = _fitScale;
    _offsetX = (canvasW - widget.frameWidth * _scale) / 2;
    _offsetY = (canvasH - widget.frameHeight * _scale) / 2;
    _initialFitApplied = true;
  }

  void addGuides() {
    const margin = 50;
    final g = CropGuides(
      left: margin,
      right: widget.frameWidth - margin,
      top: margin,
      bottom: widget.frameHeight - margin,
    );
    setState(() => _guides = g);
    widget.onGuidesChanged(g);
  }

  void removeGuides() {
    setState(() => _guides = null);
  }

  CropGuides? get currentGuides => _guides;

  /// 屏幕坐标 → 帧坐标
  Offset _screenToFrame(Offset screenPos) {
    return Offset(
      (screenPos.dx - _offsetX) / _scale,
      (screenPos.dy - _offsetY) / _scale,
    );
  }

  CropGuides _clampGuides(CropGuides g) {
    int l = g.left.clamp(0, widget.frameWidth);
    int r = g.right.clamp(0, widget.frameWidth);
    int t = g.top.clamp(0, widget.frameHeight);
    int b = g.bottom.clamp(0, widget.frameHeight);
    if (l >= r) r = (l + 2).clamp(0, widget.frameWidth);
    if (t >= b) b = (t + 2).clamp(0, widget.frameHeight);
    return CropGuides(left: l, right: r, top: t, bottom: b);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildZoomToolbar(),
        const SizedBox(height: 4),
        Expanded(child: _buildCanvasArea()),
      ],
    );
  }

  Widget _buildZoomToolbar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          if (_guides == null)
            TextButton.icon(
              onPressed: addGuides,
              icon: const Icon(Icons.crop_free, size: 16),
              label: const Text('添加裁切线', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            )
          else
            TextButton.icon(
              onPressed: removeGuides,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('移除裁切线', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textTertiary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          const Spacer(),
          Text(
            '滚轮缩放 · 右键平移',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _applyInitialFit(constraints.maxWidth, constraints.maxHeight);

        return Listener(
          onPointerSignal: _onPointerSignal,
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          child: ClipRect(
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _CropCanvasPainter(
                frameImage: _frameImage,
                guides: _guides,
                frameWidth: widget.frameWidth,
                frameHeight: widget.frameHeight,
                hoveredGuide: _draggingGuide,
                scale: _scale,
                offsetX: _offsetX,
                offsetY: _offsetY,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- 鼠标事件处理 ---

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    final zoomDelta = -event.scrollDelta.dy / 300;
    final newScale = (_scale * (1 + zoomDelta)).clamp(_fitScale * 0.5, 5.0);

    // 以鼠标位置为中心缩放
    final mouseX = event.localPosition.dx;
    final mouseY = event.localPosition.dy;
    final frameX = (mouseX - _offsetX) / _scale;
    final frameY = (mouseY - _offsetY) / _scale;

    setState(() {
      _scale = newScale;
      _offsetX = mouseX - frameX * _scale;
      _offsetY = mouseY - frameY * _scale;
    });
  }

  void _onPointerDown(PointerDownEvent event) {
    if (event.buttons == 2 || event.buttons == 4) {
      // 右键/中键：平移
      _isPanning = true;
      _panStartScreen = event.localPosition;
      _panStartOffsetX = _offsetX;
      _panStartOffsetY = _offsetY;
    } else if (event.buttons == 1 && _guides != null) {
      // 左键：拖拽参考线
      final framePos = _screenToFrame(event.localPosition);
      final guide = _findNearestGuide(framePos.dx, framePos.dy);
      if (guide != null) {
        setState(() {
          _draggingGuide = guide;
          _dragStartFrame = framePos;
          _dragStartGuides = _guides;
        });
      }
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isPanning && _panStartScreen != null) {
      setState(() {
        _offsetX = _panStartOffsetX + (event.localPosition.dx - _panStartScreen!.dx);
        _offsetY = _panStartOffsetY + (event.localPosition.dy - _panStartScreen!.dy);
      });
    } else if (_draggingGuide != null && _dragStartFrame != null && _dragStartGuides != null) {
      final framePos = _screenToFrame(event.localPosition);
      final dx = (framePos.dx - _dragStartFrame!.dx).round();
      final dy = (framePos.dy - _dragStartFrame!.dy).round();

      CropGuides updated;
      switch (_draggingGuide!) {
        case GuideType.left:
          updated = _dragStartGuides!.copyWith(left: _dragStartGuides!.left + dx);
        case GuideType.right:
          updated = _dragStartGuides!.copyWith(right: _dragStartGuides!.right + dx);
        case GuideType.top:
          updated = _dragStartGuides!.copyWith(top: _dragStartGuides!.top + dy);
        case GuideType.bottom:
          updated = _dragStartGuides!.copyWith(bottom: _dragStartGuides!.bottom + dy);
      }

      updated = _clampGuides(updated);
      setState(() => _guides = updated);
      widget.onGuidesChanged(updated);
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isPanning) {
      _isPanning = false;
      _panStartScreen = null;
    }
    if (_draggingGuide != null) {
      setState(() {
        _draggingGuide = null;
        _dragStartFrame = null;
        _dragStartGuides = null;
      });
    }
  }

  /// 查找最近的参考线（阈值根据缩放比例自适应）
  GuideType? _findNearestGuide(double x, double y) {
    final threshold = 20.0 / _scale;
    final g = _guides!;

    double? minDist;
    GuideType? nearest;

    void check(double dist, GuideType type) {
      if (dist < threshold && (minDist == null || dist < minDist!)) {
        minDist = dist;
        nearest = type;
      }
    }

    check((x - g.left).abs(), GuideType.left);
    check((x - g.right).abs(), GuideType.right);
    check((y - g.top).abs(), GuideType.top);
    check((y - g.bottom).abs(), GuideType.bottom);

    return nearest;
  }
}

/// 画布绘制器 — 所有坐标在帧空间内，通过 canvas.translate/scale 变换
class _CropCanvasPainter extends CustomPainter {
  final ui.Image? frameImage;
  final CropGuides? guides;
  final int frameWidth;
  final int frameHeight;
  final GuideType? hoveredGuide;
  final double scale;
  final double offsetX;
  final double offsetY;

  _CropCanvasPainter({
    required this.frameImage,
    required this.guides,
    required this.frameWidth,
    required this.frameHeight,
    required this.hoveredGuide,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 深色背景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF2A2A2A),
    );

    // 变换到帧坐标系
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale, scale);

    // 绘制帧底图
    final image = frameImage;
    if (image != null) {
      canvas.drawImage(image, Offset.zero, Paint());
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, frameWidth.toDouble(), frameHeight.toDouble()),
        Paint()..color = AppColors.surfaceVariant,
      );
    }

    if (guides == null) {
      canvas.restore();
      return;
    }
    final g = guides!;

    // 遮罩（裁切区域外半透明）
    final maskPaint = Paint()..color = const Color(0xCC000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, frameWidth.toDouble(), g.top.toDouble()), maskPaint);
    canvas.drawRect(Rect.fromLTWH(0, g.bottom.toDouble(), frameWidth.toDouble(), (frameHeight - g.bottom).toDouble()), maskPaint);
    canvas.drawRect(Rect.fromLTWH(0, g.top.toDouble(), g.left.toDouble(), (g.bottom - g.top).toDouble()), maskPaint);
    canvas.drawRect(Rect.fromLTWH(g.right.toDouble(), g.top.toDouble(), (frameWidth - g.right).toDouble(), (g.bottom - g.top).toDouble()), maskPaint);

    // 参考线（线宽除以 scale 保持视觉粗细一致）
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.5 / scale;

    final activePaint = Paint()
      ..color = const Color(0xFFFFD600)
      ..strokeWidth = 2.5 / scale;

    // 竖线贯穿整个帧高度
    canvas.drawLine(
      Offset(g.left.toDouble(), 0),
      Offset(g.left.toDouble(), frameHeight.toDouble()),
      hoveredGuide == GuideType.left ? activePaint : linePaint,
    );
    canvas.drawLine(
      Offset(g.right.toDouble(), 0),
      Offset(g.right.toDouble(), frameHeight.toDouble()),
      hoveredGuide == GuideType.right ? activePaint : linePaint,
    );
    // 横线贯穿整个帧宽度
    canvas.drawLine(
      Offset(0, g.top.toDouble()),
      Offset(frameWidth.toDouble(), g.top.toDouble()),
      hoveredGuide == GuideType.top ? activePaint : linePaint,
    );
    canvas.drawLine(
      Offset(0, g.bottom.toDouble()),
      Offset(frameWidth.toDouble(), g.bottom.toDouble()),
      hoveredGuide == GuideType.bottom ? activePaint : linePaint,
    );

    // 中心 W×H 标注
    final labelFontSize = 12 / scale;
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: labelFontSize,
      backgroundColor: const Color(0xCC000000),
    );
    final centerX = (g.left + g.right) / 2;
    final centerY = (g.top + g.bottom) / 2;
    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(text: '${g.cropW}×${g.cropH}', style: textStyle)
      ..layout();
    tp.paint(canvas, Offset(centerX - tp.width / 2, centerY - tp.height / 2));

    // 边距标注
    final smallFontSize = 10 / scale;
    _drawLabel(canvas, '${g.left}', Offset(g.left.toDouble(), (g.top - 20 / scale).toDouble()), smallFontSize);
    _drawLabel(canvas, '${g.right}', Offset(g.right.toDouble(), (g.top - 20 / scale).toDouble()), smallFontSize);
    _drawLabel(canvas, '${g.top}', Offset(g.left.toDouble(), (g.top - 20 / scale).toDouble()), smallFontSize);
    _drawLabel(canvas, '${g.bottom}', Offset(g.left.toDouble(), (g.bottom - 20 / scale).toDouble()), smallFontSize);

    canvas.restore();
  }

  void _drawLabel(Canvas canvas, String text, Offset position, double fontSize) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: AppColors.primary, fontSize: fontSize, backgroundColor: const Color(0xCC000000)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant _CropCanvasPainter oldDelegate) {
    return oldDelegate.guides != guides ||
        oldDelegate.hoveredGuide != hoveredGuide ||
        oldDelegate.frameImage != frameImage ||
        oldDelegate.scale != scale ||
        oldDelegate.offsetX != offsetX ||
        oldDelegate.offsetY != offsetY;
  }
}
