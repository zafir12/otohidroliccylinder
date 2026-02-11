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
    final topLeft = modelToCanvas(
      Offset(modelRectMm.left, modelRectMm.top),
      size,
    );
    final bottomRight = modelToCanvas(
      Offset(modelRectMm.right, modelRectMm.bottom),
      size,
    );

    return Rect.fromLTRB(
      math.min(topLeft.dx, bottomRight.dx),
      math.min(topLeft.dy, bottomRight.dy),
      math.max(topLeft.dx, bottomRight.dx),
      math.max(topLeft.dy, bottomRight.dy),
    );
  }

  /// Kapalı bir path'i teknik resim kesit taraması ile doldurur.
  ///
  /// 1) İç dolgu: 10x10 tile üzerinden üretilen 45° hatch shader
  /// 2) Dış kontur: [borderColor], 1.5 px stroke
  void drawHatchedPath(
    Canvas canvas,
    Path path, {
    Color borderColor = Colors.black,
  }) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = _createHatchShader(),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = borderColor,
    );
  }

  /// İki nokta arasına teknik resim ölçü çizgisi çizer.
  ///
  /// - Ok yönü mesafeye göre otomatik ayarlanır:
  ///   - Uygun mesafede: içten içe (oklar birbirini gösterir)
  ///   - Kısa mesafede: dıştan dışa (oklar dışarı bakar)
  /// - Ölçü metni çizgi ortasına (üst tarafına) yazılır.
  void drawDimensionLine(Canvas canvas, Offset start, Offset end, String text) {
    final dimensionColor = Colors.blue.shade700;

    final linePaint = Paint()
      ..color = dimensionColor
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    final v = end - start;
    final length = v.distance;
    if (length <= 0.1) return;

    final dir = Offset(v.dx / length, v.dy / length);
    final normal = Offset(-dir.dy, dir.dx);

    canvas.drawLine(start, end, linePaint);

    const arrowLength = 8.0;
    final bool useOutwardArrows = length < (arrowLength * 5);

    final startArrowDir = useOutwardArrows ? -dir : dir;
    final endArrowDir = useOutwardArrows ? dir : -dir;

    _drawArrowHead(canvas, at: start, dir: startArrowDir, paint: linePaint);
    _drawArrowHead(canvas, at: end, dir: endArrowDir, paint: linePaint);

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final textCenter = mid + normal * 12;

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: dimensionColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgRect = Rect.fromCenter(
      center: textCenter,
      width: tp.width + 8,
      height: tp.height + 4,
    );

    canvas.drawRect(bgRect, Paint()..color = Colors.white.withOpacity(0.92));
    tp.paint(canvas, Offset(bgRect.left + 4, bgRect.top + 2));
  }

  /// Model koordinatları ile ölçü oku çizimi için yardımcı metod.
  void drawDimensionLineMm(
    Canvas canvas,
    Size size, {
    required Offset startMm,
    required Offset endMm,
    required String text,
    double offsetMm = 0,
    double extensionMm = 0,
  }) {
    final start = modelToCanvas(startMm, size);
    final end = modelToCanvas(endMm, size);

    final v = end - start;
    final length = v.distance;
    if (length <= 0.1) return;

    final dir = Offset(v.dx / length, v.dy / length);
    final normal = Offset(-dir.dy, dir.dx);

    final offsetPx = mmToPixel(offsetMm, size);
    final extensionPx = mmToPixel(extensionMm, size);

    final ds = start + normal * offsetPx;
    final de = end + normal * offsetPx;

    if (extensionPx > 0) {
      final extPaint = Paint()
        ..color = Colors.blue.shade700
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(start, start + normal * (offsetPx + extensionPx), extPaint);
      canvas.drawLine(end, end + normal * (offsetPx + extensionPx), extPaint);
    }

    drawDimensionLine(canvas, ds, de, text);
  }

  double _scale(Size size) {
    final availableW = size.width - canvasPadding.horizontal;
    final availableH = size.height - canvasPadding.vertical;
    return math.min(availableW / modelWidthMm, availableH / modelHeightMm);
  }

  /// 10x10 px tile üzerinde 45° hatch pattern üretir ve ImageShader döndürür.
  ui.Shader _createHatchShader() {
    const tileSize = 10.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, tileSize, tileSize),
    );

    final linePaint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // 45° çizgi (sol-alt -> sağ-üst)
    canvas.drawLine(
      const Offset(0, tileSize),
      const Offset(tileSize, 0),
      linePaint,
    );

    final picture = recorder.endRecording();
    final image = picture.toImageSync(tileSize.toInt(), tileSize.toInt());

    return ImageShader(
      image,
      TileMode.repeated,
      TileMode.repeated,
      Matrix4.identity().storage,
    );
  }

  void _drawArrowHead(
    Canvas canvas, {
    required Offset at,
    required Offset dir,
    required Paint paint,
  }) {
    const arrowLength = 8.0;
    const angle = 24 * math.pi / 180;

    final left = Offset(
      at.dx - arrowLength * (dir.dx * math.cos(angle) - dir.dy * math.sin(angle)),
      at.dy - arrowLength * (dir.dx * math.sin(angle) + dir.dy * math.cos(angle)),
    );

    final right = Offset(
      at.dx -
          arrowLength * (dir.dx * math.cos(-angle) - dir.dy * math.sin(-angle)),
      at.dy -
          arrowLength * (dir.dx * math.sin(-angle) + dir.dy * math.cos(-angle)),
    );

    canvas.drawLine(at, left, paint);
    canvas.drawLine(at, right, paint);
  }
}
