import 'package:flutter/material.dart';

import 'engineering_painter.dart';

/// ============================================================================
/// KepPainter - Kep / Gland Yarım Kesit Teknik Resim
/// ============================================================================
///
/// Parametreler (mm):
/// - D1: Flanş çapı
/// - D2: Gövde çapı
/// - d:  Mil delik çapı
/// - L1: Flanş kalınlığı
/// - L2: Toplam boy
/// - L3: Diş uzunluğu (gövde ucunda)
class KepPainter extends EngineeringPainter {
  final double d1;
  final double d2;
  final double d;
  final double l1;
  final double l2;
  final double l3;

  const KepPainter({
    required this.d1,
    required this.d2,
    required this.d,
    required this.l1,
    required this.l2,
    required this.l3,
  }) : super(
          modelWidthMm: l2 + 20,
          modelHeightMm: d1 + 30,
          canvasPadding: const EdgeInsets.all(26),
        );

  @override
  void paint(Canvas canvas, Size size) {
    final r1 = d1 / 2;
    final r2 = d2 / 2;
    final ri = d / 2;

    // Kotlin mantığına yakın profil:
    // x=0..L1 => D1 (flanş), x=L1..L2 => D2 (gövde)
    final outerPath = Path()
      ..moveTo(modelToCanvas(Offset(0, r1), size).dx, modelToCanvas(Offset(0, r1), size).dy)
      ..lineTo(modelToCanvas(Offset(l1, r1), size).dx, modelToCanvas(Offset(l1, r1), size).dy)
      ..lineTo(modelToCanvas(Offset(l1, r2), size).dx, modelToCanvas(Offset(l1, r2), size).dy)
      ..lineTo(modelToCanvas(Offset(l2, r2), size).dx, modelToCanvas(Offset(l2, r2), size).dy)
      ..lineTo(modelToCanvas(Offset(l2, -r2), size).dx, modelToCanvas(Offset(l2, -r2), size).dy)
      ..lineTo(modelToCanvas(Offset(l1, -r2), size).dx, modelToCanvas(Offset(l1, -r2), size).dy)
      ..lineTo(modelToCanvas(Offset(l1, -r1), size).dx, modelToCanvas(Offset(l1, -r1), size).dy)
      ..lineTo(modelToCanvas(Offset(0, -r1), size).dx, modelToCanvas(Offset(0, -r1), size).dy)
      ..close();

    // Ana iç delik (d)
    final borePath = Path()
      ..addRect(
        modelRectToCanvasRect(Rect.fromLTRB(-1, -ri, l2 + 1, ri), size),
      );

    // İç çap kanalları:
    // - Wiper: flanş önü
    final wiperW = (l1 * 0.30).clamp(1.8, 8.0).toDouble();
    final wiperDepth = (d * 0.08).clamp(0.6, 2.0).toDouble();
    final wiperX = l1 * 0.08;

    // - Nutring: orta bölge
    final nutringW = ((l2 - l1) * 0.18).clamp(2.4, 10.0).toDouble();
    final nutringDepth = (d * 0.10).clamp(0.8, 2.8).toDouble();
    final nutringX = l1 + (l2 - l1) * 0.45;

    final innerGrooves = Path()
      ..addRect(
        modelRectToCanvasRect(
          Rect.fromLTRB(wiperX, -(ri + wiperDepth), wiperX + wiperW, ri + wiperDepth),
          size,
        ),
      )
      ..addRect(
        modelRectToCanvasRect(
          Rect.fromLTRB(
            nutringX,
            -(ri + nutringDepth),
            nutringX + nutringW,
            ri + nutringDepth,
          ),
          size,
        ),
      );

    // Dış yüzey O-ring kanalı (D2 dış yüzeyinde, flanşa yakın)
    final oRingW = ((l2 - l1) * 0.12).clamp(2.2, 8.0).toDouble();
    final oRingDepth = (d2 * 0.04).clamp(0.8, 2.5).toDouble();
    final oRingX = l1 + (l2 - l1) * 0.12;

    final outerGrooves = Path()
      ..addRect(
        modelRectToCanvasRect(
          Rect.fromLTRB(oRingX, r2 - oRingDepth, oRingX + oRingW, r2),
          size,
        ),
      )
      ..addRect(
        modelRectToCanvasRect(
          Rect.fromLTRB(oRingX, -r2, oRingX + oRingW, -r2 + oRingDepth),
          size,
        ),
      );

    var sectionPath = Path.combine(PathOperation.difference, outerPath, borePath);
    sectionPath = Path.combine(PathOperation.difference, sectionPath, innerGrooves);
    sectionPath = Path.combine(PathOperation.difference, sectionPath, outerGrooves);

    // Kesit tarama + kontur
    drawHatchedPath(canvas, sectionPath, borderColor: Colors.black);

    // Diş gösterimi: L3 boyunca üst/alt kenarda kısa çizgiler
    _drawThreadMarks(canvas, size, r2: r2);

    // Ölçülendirme (mavi #0066CC)
    drawDimensionLineMm(
      canvas,
      size,
      startMm: Offset(0, r1 + 3),
      endMm: Offset(l2, r1 + 3),
      text: 'L2 ${l2.toStringAsFixed(1)} mm',
      offsetMm: 4.5,
    );

    drawDimensionLineMm(
      canvas,
      size,
      startMm: Offset(0, -r1 - 3),
      endMm: Offset(l1, -r1 - 3),
      text: 'L1 ${l1.toStringAsFixed(1)} mm',
      offsetMm: 4,
    );

    drawDimensionLineMm(
      canvas,
      size,
      startMm: Offset(l2 - l3, r2 + 2),
      endMm: Offset(l2, r2 + 2),
      text: 'L3 ${l3.toStringAsFixed(1)}',
      offsetMm: 4,
    );

    drawDimensionLineMm(
      canvas,
      size,
      startMm: Offset(-3.5, -r1),
      endMm: Offset(-3.5, r1),
      text: 'D1 ⌀${d1.toStringAsFixed(1)}',
      offsetMm: 3,
    );

    drawDimensionLineMm(
      canvas,
      size,
      startMm: Offset(l2 + 2.5, -r2),
      endMm: Offset(l2 + 2.5, r2),
      text: 'D2 ⌀${d2.toStringAsFixed(1)}',
      offsetMm: 3,
    );

    drawDimensionLineMm(
      canvas,
      size,
      startMm: Offset(l1 + (l2 - l1) * 0.5, -ri),
      endMm: Offset(l1 + (l2 - l1) * 0.5, ri),
      text: 'd ⌀${d.toStringAsFixed(1)}',
      offsetMm: 5,
    );
  }

  void _drawThreadMarks(Canvas canvas, Size size, {required double r2}) {
    final p = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    final startX = (l2 - l3).clamp(0, l2).toDouble();
    final pitch = (l3 / 8).clamp(0.8, 2.5).toDouble();
    for (double x = startX; x <= l2; x += pitch) {
      final topA = modelToCanvas(Offset(x, r2), size);
      final topB = modelToCanvas(Offset(x + pitch * 0.55, r2 - r2 * 0.09), size);
      canvas.drawLine(topA, topB, p);

      final botA = modelToCanvas(Offset(x, -r2), size);
      final botB = modelToCanvas(Offset(x + pitch * 0.55, -r2 + r2 * 0.09), size);
      canvas.drawLine(botA, botB, p);
    }
  }

  @override
  bool shouldRepaint(covariant KepPainter oldDelegate) {
    return d1 != oldDelegate.d1 ||
        d2 != oldDelegate.d2 ||
        d != oldDelegate.d ||
        l1 != oldDelegate.l1 ||
        l2 != oldDelegate.l2 ||
        l3 != oldDelegate.l3;
  }
}
