import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// ============================================================================
/// EngineeringPainter - Ortak Teknik Resim Base Sınıfı
/// ============================================================================
///
/// Ortak özellikler:
/// - mm -> px ölçekleme
/// - model koordinatını canvas'a çevirme
/// - mavi teknik ölçülendirme çizgileri
/// - kesit taraması (hatching) için shader tabanlı dolgu
abstract class EngineeringPainter extends CustomPainter {
  final double modelWidthMm;
  final double modelHeightMm;
  final EdgeInsets canvasPadding;

  const EngineeringPainter({
    required this.modelWidthMm,
    required this.modelHeightMm,
    this.canvasPadding = const EdgeInsets.all(24),
  });

  /// mm değerini px'e çevirir (uniform scale).
  double mmToPixel(double mm, Size size) {
    final scale = _scale(size);
    return mm * scale;
  }

  /// Model koordinatı (x sağa, y yukarı) -> Canvas koordinatı (x sağa, y aşağı)
  Offset modelToCanvas(Offset modelPointMm, Size size) {
    final scale = _scale(size);
    final drawW = modelWidthMm * scale;
    final drawH = modelHeightMm * scale;
    final availableW = size.width - canvasPadding.horizontal;
    final availableH = size.height - canvasPadding.vertical;

    final originLeft = canvasPadding.left + (availableW - drawW) / 2;
    final originTop = canvasPadding.top + (availableH - drawH) / 2;

    final x = originLeft + modelPointMm.dx * scale;
    final y = originTop + drawH - modelPointMm.dy * scale;
    return Offset(x, y);
  }

  Rect modelRectToCanvasRect(Rect modelRectMm, Size size) {
    final topLeft = modelToCanvas(Offset(modelRectMm.left, modelRectMm.top), size);
    final bottomRight =
        modelToCanvas(Offset(modelRectMm.right, modelRectMm.bottom), size);
    return Rect.fromLTRB(
      math.min(topLeft.dx, bottomRight.dx),
      math.min(topLeft.dy, bottomRight.dy),
      math.max(topLeft.dx, bottomRight.dx),
      math.max(topLeft.dy, bottomRight.dy),
    );
  }

  /// Teknik ölçü çizgisi (mavi oklar + metin).
  void drawDimensionLine(
    Canvas canvas,
    Size size, {
    required Offset startMm,
    required Offset endMm,
    required String text,
    double offsetMm = 5,
    double extensionMm = 2.5,
  }) {
    const dimensionColor = Color(0xFF0066CC);

    final paint = Paint()
      ..color = dimensionColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final start = modelToCanvas(startMm, size);
    final end = modelToCanvas(endMm, size);

    final v = end - start;
    final length = v.distance;
    if (length < 1) return;

    final dir = Offset(v.dx / length, v.dy / length);
    final normal = Offset(-dir.dy, dir.dx);

    final offsetPx = mmToPixel(offsetMm, size);
    final extPx = mmToPixel(extensionMm, size);

    final ds = start + normal * offsetPx;
    final de = end + normal * offsetPx;

    // extension lines
    canvas.drawLine(start + normal * extPx, ds, paint);
    canvas.drawLine(end + normal * extPx, de, paint);

    // dimension line
    canvas.drawLine(ds, de, paint);

    _drawArrow(canvas, at: ds, dir: dir, paint: paint);
    _drawArrow(canvas, at: de, dir: -dir, paint: paint);

    final mid = Offset((ds.dx + de.dx) / 2, (ds.dy + de.dy) / 2);
    final tp = TextPainter(
      text: const TextSpan().copyWith(
        text: text,
        style: const TextStyle(
          color: dimensionColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bg = Rect.fromCenter(
      center: mid + normal * 10,
      width: tp.width + 6,
      height: tp.height + 4,
    );
    canvas.drawRect(bg, Paint()..color = Colors.white.withOpacity(0.92));
    tp.paint(canvas, Offset(bg.left + 3, bg.top + 2));
  }

  /// Kapalı path alanını hatch shader ile doldurur.
  ///
  /// Not: Tarama doğrudan `Paint.shader` ile yapılır.
  void drawHatchedPath(
    Canvas canvas,
    Size size,
    Path closedPath, {
    Color baseColor = const Color(0xFFE0E0E0),
    Color hatchColor = const Color(0xFFC7C7C7),
    double hatchSpacingMm = 2.0,
    double hatchStrokePx = 1.0,
  }) {
    final bounds = closedPath.getBounds();
    if (bounds.isEmpty) return;

    // Base fill
    canvas.drawPath(
      closedPath,
      Paint()
        ..style = PaintingStyle.fill
        ..color = baseColor,
    );

    final spacingPx = math.max(4.0, mmToPixel(hatchSpacingMm, size));
    final shader = _createHatchShader(
      spacingPx: spacingPx,
      strokePx: hatchStrokePx,
      hatchColor: hatchColor,
    );

    canvas.drawPath(
      closedPath,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = shader,
    );
  }

  double _scale(Size size) {
    final availableW = size.width - canvasPadding.horizontal;
    final availableH = size.height - canvasPadding.vertical;
    return math.min(availableW / modelWidthMm, availableH / modelHeightMm);
  }

  ui.Shader _createHatchShader({
    required double spacingPx,
    required double strokePx,
    required Color hatchColor,
  }) {
    final tile = spacingPx * 2;
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder, Rect.fromLTWH(0, 0, tile, tile));
    final p = Paint()
      ..color = hatchColor
      ..strokeWidth = strokePx
      ..style = PaintingStyle.stroke;

    // 45° hatch
    c.drawLine(Offset(-tile * 0.2, tile), Offset(tile, -tile * 0.2), p);
    c.drawLine(Offset(0, tile * 1.2), Offset(tile * 1.2, 0), p);

    final img = recorder.endRecording().toImageSync(tile.ceil(), tile.ceil());
    return ImageShader(
      img,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.identity().storage,
    );
  }

  void _drawArrow(
    Canvas canvas, {
    required Offset at,
    required Offset dir,
    required Paint paint,
  }) {
    const len = 8.0;
    const angle = 24 * math.pi / 180;

    final left = Offset(
      at.dx - len * (dir.dx * math.cos(angle) - dir.dy * math.sin(angle)),
      at.dy - len * (dir.dx * math.sin(angle) + dir.dy * math.cos(angle)),
    );
    final right = Offset(
      at.dx - len * (dir.dx * math.cos(-angle) - dir.dy * math.sin(-angle)),
      at.dy - len * (dir.dx * math.sin(-angle) + dir.dy * math.cos(-angle)),
    );

    canvas.drawLine(at, left, paint);
    canvas.drawLine(at, right, paint);
  }
}
