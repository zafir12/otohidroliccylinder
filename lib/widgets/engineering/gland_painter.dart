import 'package:flutter/material.dart';

import 'engineering_painter.dart';

/// ============================================================================
/// GlandPainter - Kep / Boğaz Kesit Çizimi
/// ============================================================================
///
/// Parametrik bir gland kesiti üretir.
/// Kotlin'deki KepCanvas mantığına benzer şekilde:
/// - dış kontur
/// - rod deliği
/// - Nutring / Toz keçesi / O-ring kanal boşlukları
/// - kesit taraması
/// - temel ölçülendirme
class GlandPainter extends EngineeringPainter {
  final double rodDiameter;
  final double outerDiameter;
  final double flangeDiameter;
  final double totalLength;

  const GlandPainter({
    required this.rodDiameter,
    required this.outerDiameter,
    required this.flangeDiameter,
    required this.totalLength,
  }) : super(
          modelWidthMm: totalLength + 20,
          modelHeightMm: (flangeDiameter > outerDiameter ? flangeDiameter : outerDiameter) + 24,
        );

  @override
  void paint(Canvas canvas, Size size) {
    final bodyStroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    final sectionFill = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final centerY = modelHeightMm / 2;

    final bodyTop = centerY + outerDiameter / 2;
    final bodyBottom = centerY - outerDiameter / 2;

    final flangeTop = centerY + flangeDiameter / 2;
    final flangeBottom = centerY - flangeDiameter / 2;

    final xStart = 10.0;
    final xEnd = xStart + totalLength;

    // Flanş omuzu
    final flangeStep =
        (totalLength * 0.18).clamp(4.0, totalLength * 0.35).toDouble();
    final xFlangeShoulder = xEnd - flangeStep;

    // Ana dış kontur (yarım kesit mantığı için tam kesit polyline)
    final contour = Path()
      ..moveTo(modelToCanvas(Offset(xStart, bodyBottom), size).dx, modelToCanvas(Offset(xStart, bodyBottom), size).dy)
      ..lineTo(modelToCanvas(Offset(xFlangeShoulder, bodyBottom), size).dx, modelToCanvas(Offset(xFlangeShoulder, bodyBottom), size).dy)
      ..lineTo(modelToCanvas(Offset(xFlangeShoulder, flangeBottom), size).dx, modelToCanvas(Offset(xFlangeShoulder, flangeBottom), size).dy)
      ..lineTo(modelToCanvas(Offset(xEnd, flangeBottom), size).dx, modelToCanvas(Offset(xEnd, flangeBottom), size).dy)
      ..lineTo(modelToCanvas(Offset(xEnd, flangeTop), size).dx, modelToCanvas(Offset(xEnd, flangeTop), size).dy)
      ..lineTo(modelToCanvas(Offset(xFlangeShoulder, flangeTop), size).dx, modelToCanvas(Offset(xFlangeShoulder, flangeTop), size).dy)
      ..lineTo(modelToCanvas(Offset(xFlangeShoulder, bodyTop), size).dx, modelToCanvas(Offset(xFlangeShoulder, bodyTop), size).dy)
      ..lineTo(modelToCanvas(Offset(xStart, bodyTop), size).dx, modelToCanvas(Offset(xStart, bodyTop), size).dy)
      ..close();

    // Rod deliği (ana boşluk)
    final rodTop = centerY + rodDiameter / 2;
    final rodBottom = centerY - rodDiameter / 2;

    final rodPath = Path()
      ..addRect(
        Rect.fromPoints(
          modelToCanvas(Offset(xStart - 1, rodBottom), size),
          modelToCanvas(Offset(xEnd + 1, rodTop), size),
        ),
      );

    // Groove geometrileri (boşluk olarak çıkar)
    final grooveDepth = (rodDiameter * 0.08).clamp(0.7, 2.0).toDouble();

    // Toz keçesi (rod çıkış tarafına yakın)
    final dustW = (totalLength * 0.08).clamp(2.0, 6.0).toDouble();
    final dustX = xEnd - dustW - 1.2;

    // Nutring yuvası (orta bölge)
    final nutringW = (totalLength * 0.10).clamp(2.5, 7.0).toDouble();
    final nutringX = xFlangeShoulder - nutringW - 0.8;

    // O-ring yuvası (arka bölgede)
    final oRingW = (totalLength * 0.075).clamp(2.0, 5.0).toDouble();
    final oRingX = xStart + totalLength * 0.22;

    Path grooveRect(double x, double w) {
      return Path()
        ..addRect(
          Rect.fromPoints(
            modelToCanvas(Offset(x, rodBottom - grooveDepth), size),
            modelToCanvas(Offset(x + w, rodTop + grooveDepth), size),
          ),
        );
    }

    final groovePath = Path()
      ..addPath(grooveRect(dustX, dustW), Offset.zero)
      ..addPath(grooveRect(nutringX, nutringW), Offset.zero)
      ..addPath(grooveRect(oRingX, oRingW), Offset.zero);

    final sectionPath = Path.combine(PathOperation.difference, contour, rodPath);
    final sectionWithoutGrooves = Path.combine(PathOperation.difference, sectionPath, groovePath);

    // Dolu kesit + tarama
    canvas.drawPath(sectionWithoutGrooves, sectionFill);
    drawHatchedPath(
      canvas,
      size,
      sectionWithoutGrooves,
      spacingMm: 1.8,
      angleDeg: 45,
      lineColor: Colors.grey.shade400,
      strokeWidth: 1,
    );

    // Kontur çizgileri
    canvas.drawPath(sectionWithoutGrooves, bodyStroke);

    // Groove sınırlarını teknik çizim gibi göster
    final grooveStroke = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(groovePath, grooveStroke);

    // Ölçülendirme - toplam boy
    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(xStart, flangeTop + 4),
      endMm: Offset(xEnd, flangeTop + 4),
      label: '${totalLength.toStringAsFixed(1)} mm',
      extensionMm: 3.5,
    );

    // Dış çap ölçüsü
    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(xStart - 6, bodyBottom),
      endMm: Offset(xStart - 6, bodyTop),
      label: '⌀${outerDiameter.toStringAsFixed(1)}',
      extensionMm: 3,
    );

    // Flanş çap ölçüsü
    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(xEnd + 2, flangeBottom),
      endMm: Offset(xEnd + 2, flangeTop),
      label: '⌀${flangeDiameter.toStringAsFixed(1)}',
      extensionMm: 3,
    );

    // Rod deliği ölçüsü
    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(xStart + totalLength * 0.45, rodBottom),
      endMm: Offset(xStart + totalLength * 0.45, rodTop),
      label: '⌀${rodDiameter.toStringAsFixed(1)}',
      extensionMm: 5,
    );
  }

  @override
  bool shouldRepaint(covariant GlandPainter oldDelegate) {
    return rodDiameter != oldDelegate.rodDiameter ||
        outerDiameter != oldDelegate.outerDiameter ||
        flangeDiameter != oldDelegate.flangeDiameter ||
        totalLength != oldDelegate.totalLength;
  }
}
