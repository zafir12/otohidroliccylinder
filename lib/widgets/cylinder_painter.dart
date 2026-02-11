import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/hydraulic_cylinder.dart';
import '../models/mounting_type.dart';
import '../models/mounting_types/front_flange.dart';
import '../models/mounting_types/rear_clevis.dart';
import '../models/mounting_types/spherical_bearing.dart';
import '../models/mounting_types/trunnion.dart';

/// ============================================================================
/// CylinderPainter - Parametrik Teknik Resim CustomPainter
/// ============================================================================
///
/// HydraulicCylinder ve MountingType objelerini alarak Canvas üzerine
/// ölçeklendirilmiş 2D yan görünüş (side view) teknik resmi çizer.
///
/// Çizim düzeni (Layout):
///
///   ┌── dimMargin ──┐
///   │               │
///   │   ←── D ölçü ──→            ← Üst ölçü çizgisi
///   │               │
///   │   ┌═══════════════════════════════┬────┬──────────────────┐
///   │   │  Arka      GÖVDE             │PİST│      ROD         │ Ön
///   │   │  Bağlantı  (Bore D)          │ ON │      (d)         │ Bağlantı
///   │   │           ════════           │    │                  │
///   │   └═══════════════════════════════┴────┴──────────────────┘
///   │               │
///   │   ←────────── Strok ──────────→  ← Alt ölçü çizgisi
///   │   ←──────────── Kapalı Boy ───────────────→
///   │               │
///   └───────────────┘
///
/// Ölçeklendirme:
///   Tüm mm değerleri canvas piksellerine oranlanır.
///   En/boy oranı korunur (aspect ratio lock).
class CylinderPainter extends CustomPainter {
  final HydraulicCylinder cylinder;
  final MountingType mountingType;
  final Color primaryColor;
  final Color dimensionColor;
  final Color mountingColor;

  CylinderPainter({
    required this.cylinder,
    required this.mountingType,
    this.primaryColor = const Color(0xFF37474F), // Blue Grey 800
    this.dimensionColor = const Color(0xFFE53935), // Red 600
    this.mountingColor = const Color(0xFF1565C0), // Blue 800
  });

  // ---------------------------------------------------------------------------
  // Çizim sabitleri
  // ---------------------------------------------------------------------------

  /// Ölçü çizgileri için kenarlarda bırakılan boşluk (piksel)
  static const double dimMargin = 48.0;

  /// Arka bağlantı elemanı için ayrılan ek uzunluk (mm cinsinden, oransal)
  static const double _mountingLenRatio = 0.08;

  /// Piston kalınlığı oranı (gövde uzunluğuna göre)
  static const double _pistonWidthRatio = 0.04;

  /// Ön kapak (head) kalınlığı oranı
  static const double _capWidthRatio = 0.025;

  /// Rod ucundaki bağlantı elemanı uzunluk oranı
  static const double _rodEndRatio = 0.06;

  // ---------------------------------------------------------------------------
  // Paint
  // ---------------------------------------------------------------------------
  @override
  void paint(Canvas canvas, Size size) {
    // ── Ölçeklendirme ────────────────────────────────────────────────────────
    //
    // Toplam çizim genişliği (mm):
    //   mountingLen + closedLength + rodExtension + rodEndLen
    //
    // Rod extension: strok boyunca dışarı çıkan kısım (açık konumda)
    // mountingLen: arka bağlantı elemanı uzunluğu
    // rodEndLen: rod ucundaki bağlantı elemanı

    final double mountingLen = cylinder.closedLength * _mountingLenRatio;
    final double rodExtension = cylinder.stroke;
    final double rodEndLen = cylinder.closedLength * _rodEndRatio;

    final double totalLenMm =
        mountingLen + cylinder.closedLength + rodExtension + rodEndLen;
    final double totalHeightMm = cylinder.boreDiameter * 1.2;

    // Çizim alanı (ölçü çizgileri hariç)
    final double drawW = size.width - dimMargin * 2;
    final double drawH = size.height - dimMargin * 2;

    // Uniform scale – en/boy oranını koru
    final double scale =
        math.min(drawW / totalLenMm, drawH / totalHeightMm);

    // Çizimin merkez ofseti
    final double scaledTotalW = totalLenMm * scale;
    final double scaledTotalH = totalHeightMm * scale;
    final double offsetX = dimMargin + (drawW - scaledTotalW) / 2;
    final double centerY = size.height / 2;

    // mm → piksel dönüşüm
    double sx(double mm) => offsetX + mm * scale;
    double sy(double mm) => mm * scale;

    // ── Boyutlar (piksel) ────────────────────────────────────────────────────
    final double boreH = cylinder.boreDiameter * scale; // Gövde yüksekliği
    final double rodH = cylinder.rodDiameter * scale; // Rod yüksekliği
    final double bodyLen = cylinder.closedLength * scale; // Gövde uzunluğu
    final double strokeLen = cylinder.stroke * scale; // Strok uzunluğu
    final double mountLen = mountingLen * scale; // Bağlantı uzunluğu
    final double pistonW = cylinder.closedLength * _pistonWidthRatio * scale;
    final double capW = cylinder.closedLength * _capWidthRatio * scale;
    final double rodEndL = rodEndLen * scale;
    final double rodLen = strokeLen + rodEndL; // Rod toplam uzunluk

    // Sol başlangıç noktası (arka bağlantı elemanından sonra gövde başlar)
    final double bodyLeft = offsetX + mountLen;
    final double bodyRight = bodyLeft + bodyLen;
    final double bodyTop = centerY - boreH / 2;
    final double bodyBottom = centerY + boreH / 2;

    // ── Kalem tanımlamaları ──────────────────────────────────────────────────
    final bodyPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final bodyFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final rodPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final rodFill = Paint()
      ..color = primaryColor.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;

    final pistonPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final hatchPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final dimPaint = Paint()
      ..color = dimensionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final mountPaint = Paint()
      ..color = mountingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final mountFill = Paint()
      ..color = mountingColor.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final centerLinePaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.butt;

    // ── 1. Merkez çizgisi (Dash-dot: uzun-kısa-uzun) ────────────────────────
    _drawDashDotLine(
      canvas,
      Offset(offsetX - 10, centerY),
      Offset(bodyRight + rodLen + 10, centerY),
      centerLinePaint,
    );

    // ── 2. Silindir gövdesi (Bore) ──────────────────────────────────────────
    final bodyRect = Rect.fromLTRB(bodyLeft, bodyTop, bodyRight, bodyBottom);
    canvas.drawRect(bodyRect, bodyFill);
    canvas.drawRect(bodyRect, bodyPaint);

    // Et kalınlığı tarama (hatch) – üst ve alt duvar
    final double wallH = boreH * 0.10; // görsel et kalınlığı
    _drawHatchArea(canvas, bodyLeft, bodyTop, bodyRight, bodyTop + wallH, hatchPaint);
    _drawHatchArea(canvas, bodyLeft, bodyBottom - wallH, bodyRight, bodyBottom, hatchPaint);

    // ── 3. Ön kapak (Head Cap) ──────────────────────────────────────────────
    final capRect = Rect.fromLTRB(
      bodyRight - capW,
      bodyTop,
      bodyRight,
      bodyBottom,
    );
    canvas.drawRect(capRect, pistonPaint.withAlpha(40));
    canvas.drawRect(capRect, bodyPaint);

    // ── 4. Piston ───────────────────────────────────────────────────────────
    // Piston pozisyonu: gövdenin sağ tarafında (tam ileri konum)
    final double pistonX = bodyRight - capW - pistonW;
    final pistonRect = Rect.fromLTRB(
      pistonX,
      bodyTop + wallH * 0.4,
      pistonX + pistonW,
      bodyBottom - wallH * 0.4,
    );
    canvas.drawRect(pistonRect, pistonPaint.withAlpha(80));
    canvas.drawRect(pistonRect, bodyPaint);

    // ── 5. Rod (Piston kolu) ────────────────────────────────────────────────
    final double rodTop = centerY - rodH / 2;
    final double rodBottom = centerY + rodH / 2;
    final double rodRight = bodyRight + rodLen;

    final rodRect = Rect.fromLTRB(bodyRight, rodTop, rodRight, rodBottom);
    canvas.drawRect(rodRect, rodFill);
    canvas.drawRect(rodRect, rodPaint);

    // Rod-piston bağlantı çizgisi (pistondan rod'a geçiş)
    canvas.drawLine(
      Offset(pistonX + pistonW, centerY - rodH / 2),
      Offset(bodyRight, centerY - rodH / 2),
      rodPaint..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(pistonX + pistonW, centerY + rodH / 2),
      Offset(bodyRight, centerY + rodH / 2),
      rodPaint..strokeWidth = 0.8,
    );
    rodPaint.strokeWidth = 1.8;

    // ── 6. Arka bağlantı elemanı (Rear Mounting) ────────────────────────────
    _drawRearMounting(
      canvas,
      mountingType,
      bodyLeft,
      centerY,
      boreH,
      mountLen,
      mountPaint,
      mountFill,
    );

    // ── 7. Ön bağlantı elemanı (Rod End) ────────────────────────────────────
    _drawFrontRodEnd(
      canvas,
      rodRight,
      centerY,
      rodH,
      rodEndL,
      mountPaint,
      mountFill,
    );

    // ── 8. Ölçü çizgileri (Dimension Lines) ─────────────────────────────────
    final dimTextStyle = TextStyle(
      color: dimensionColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );

    // 8a. Boru Çapı (D) – sol tarafta dikey ölçü
    _drawVerticalDimension(
      canvas: canvas,
      x: bodyLeft - 20,
      y1: bodyTop,
      y2: bodyBottom,
      label: '\u00D8${cylinder.boreDiameter.toStringAsFixed(0)}',
      paint: dimPaint,
      style: dimTextStyle,
      side: _DimSide.left,
    );

    // 8b. Rod Çapı (d) – sağ tarafta dikey ölçü
    _drawVerticalDimension(
      canvas: canvas,
      x: rodRight + 16,
      y1: rodTop,
      y2: rodBottom,
      label: '\u00D8${cylinder.rodDiameter.toStringAsFixed(0)}',
      paint: dimPaint,
      style: dimTextStyle,
      side: _DimSide.right,
    );

    // 8c. Strok (L) – alt tarafta yatay ölçü
    _drawHorizontalDimension(
      canvas: canvas,
      y: bodyBottom + 24,
      x1: bodyLeft,
      x2: bodyLeft + strokeLen,
      label: 'Strok ${cylinder.stroke.toStringAsFixed(0)}',
      paint: dimPaint,
      style: dimTextStyle,
      refY1: bodyBottom,
      refY2: bodyBottom,
    );

    // 8d. Kapalı Boy – en altta yatay ölçü
    _drawHorizontalDimension(
      canvas: canvas,
      y: bodyBottom + 42,
      x1: bodyLeft,
      x2: bodyRight,
      label: 'Kapali Boy ${cylinder.closedLength.toStringAsFixed(0)}',
      paint: dimPaint,
      style: dimTextStyle,
      refY1: bodyBottom,
      refY2: bodyBottom,
    );

    // 8e. Açık Boy – üstte yatay ölçü
    _drawHorizontalDimension(
      canvas: canvas,
      y: bodyTop - 24,
      x1: bodyLeft,
      x2: rodRight - rodEndL,
      label: 'Acik Boy ${cylinder.openLength.toStringAsFixed(0)}',
      paint: dimPaint,
      style: dimTextStyle,
      refY1: bodyTop,
      refY2: rodTop,
    );
  }

  // ---------------------------------------------------------------------------
  // Arka Bağlantı Elemanı Çizimi (Polimorfik)
  // ---------------------------------------------------------------------------
  void _drawRearMounting(
    Canvas canvas,
    MountingType type,
    double bodyLeft,
    double centerY,
    double boreH,
    double mountLen,
    Paint linePaint,
    Paint fillPaint,
  ) {
    if (type is FrontFlange) {
      _drawFlange(canvas, bodyLeft, centerY, boreH, mountLen, linePaint, fillPaint);
    } else if (type is RearClevis) {
      _drawClevis(canvas, bodyLeft, centerY, boreH, mountLen, linePaint, fillPaint);
    } else if (type is Trunnion) {
      _drawTrunnion(canvas, bodyLeft, centerY, boreH, mountLen, linePaint, fillPaint);
    } else if (type is SphericalBearing) {
      _drawSphericalRear(canvas, bodyLeft, centerY, boreH, mountLen, linePaint, fillPaint);
    }
  }

  /// Ön Flanş – Geniş dikdörtgen + cıvata delik daireleri
  ///
  ///   ┌─────────┐
  ///   │ ○     ○ │
  ///   │         │──── Gövde
  ///   │ ○     ○ │
  ///   └─────────┘
  void _drawFlange(
    Canvas canvas,
    double bodyLeft,
    double centerY,
    double boreH,
    double mountLen,
    Paint linePaint,
    Paint fillPaint,
  ) {
    final double flangeH = boreH * 1.35;
    final double flangeW = mountLen * 0.8;

    final rect = Rect.fromCenter(
      center: Offset(bodyLeft - flangeW / 2, centerY),
      width: flangeW,
      height: flangeH,
    );
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, linePaint);

    // Cıvata delikleri (4 köşe)
    final double boltR = flangeH * 0.04;
    final double boltInsetX = flangeW * 0.25;
    final double boltInsetY = flangeH * 0.22;

    final boltPaint = Paint()
      ..color = linePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final dy in [-1.0, 1.0]) {
      for (final dx in [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(
            bodyLeft - flangeW / 2 + dx * boltInsetX,
            centerY + dy * boltInsetY,
          ),
          boltR,
          boltPaint,
        );
      }
    }

    // Gövdeye bağlantı çizgisi
    canvas.drawLine(
      Offset(bodyLeft - flangeW, centerY - boreH / 2),
      Offset(bodyLeft, centerY - boreH / 2),
      linePaint..strokeWidth = 0.8,
    );
    canvas.drawLine(
      Offset(bodyLeft - flangeW, centerY + boreH / 2),
      Offset(bodyLeft, centerY + boreH / 2),
      linePaint..strokeWidth = 0.8,
    );
    linePaint.strokeWidth = 1.5;
  }

  /// Arka Çatal – U şekli + pim dairesi
  ///
  ///   ┌───┐
  ///   │   │
  ///   │ ● │──── Gövde
  ///   │   │
  ///   └───┘
  void _drawClevis(
    Canvas canvas,
    double bodyLeft,
    double centerY,
    double boreH,
    double mountLen,
    Paint linePaint,
    Paint fillPaint,
  ) {
    final double clevisW = mountLen * 0.7;
    final double clevisH = boreH * 0.9;
    final double forkGap = clevisH * 0.4; // iç boşluk
    final double forkThick = (clevisH - forkGap) / 2;

    final double left = bodyLeft - clevisW;

    // Üst kol
    final topFork = Rect.fromLTRB(
      left, centerY - clevisH / 2,
      bodyLeft, centerY - clevisH / 2 + forkThick,
    );
    canvas.drawRect(topFork, fillPaint);
    canvas.drawRect(topFork, linePaint);

    // Alt kol
    final bottomFork = Rect.fromLTRB(
      left, centerY + clevisH / 2 - forkThick,
      bodyLeft, centerY + clevisH / 2,
    );
    canvas.drawRect(bottomFork, fillPaint);
    canvas.drawRect(bottomFork, linePaint);

    // Sol kapatma (U'nun alt tarafı)
    canvas.drawLine(
      Offset(left, centerY - clevisH / 2),
      Offset(left, centerY + clevisH / 2),
      linePaint,
    );

    // Pim deliği
    final double pinR = forkGap * 0.3;
    final pinCenter = Offset(left + clevisW * 0.35, centerY);
    canvas.drawCircle(pinCenter, pinR, fillPaint);
    canvas.drawCircle(
      pinCenter,
      pinR,
      linePaint..style = PaintingStyle.stroke,
    );
    // Pim merkez noktası
    canvas.drawCircle(
      pinCenter,
      1.5,
      Paint()..color = linePaint.color,
    );
  }

  /// Orta Eklem (Trunnion) – Gövdenin alt/üstünden çıkan çıkıntı + daire
  ///
  ///         ┌════════════════┐
  ///    ─────┤    GÖVDE       ├────
  ///         └══════┬═════════┘
  ///              ┌─┴─┐
  ///              │ ● │  ← Trunnion
  ///              └───┘
  void _drawTrunnion(
    Canvas canvas,
    double bodyLeft,
    double centerY,
    double boreH,
    double mountLen,
    Paint linePaint,
    Paint fillPaint,
  ) {
    // Trunnion pozisyonu: gövdenin ön kısmına yakın
    final double trunnionX = bodyLeft + mountLen * 0.5;
    final double trunnionH = boreH * 0.28;
    final double trunnionW = mountLen * 0.5;

    // Üst çıkıntı
    final topRect = Rect.fromLTRB(
      trunnionX - trunnionW / 2,
      centerY - boreH / 2 - trunnionH,
      trunnionX + trunnionW / 2,
      centerY - boreH / 2,
    );
    canvas.drawRect(topRect, fillPaint);
    canvas.drawRect(topRect, linePaint);

    // Üst pim deliği
    final double pinR = trunnionW * 0.2;
    canvas.drawCircle(
      Offset(trunnionX, centerY - boreH / 2 - trunnionH / 2),
      pinR,
      linePaint..style = PaintingStyle.stroke,
    );

    // Alt çıkıntı
    final bottomRect = Rect.fromLTRB(
      trunnionX - trunnionW / 2,
      centerY + boreH / 2,
      trunnionX + trunnionW / 2,
      centerY + boreH / 2 + trunnionH,
    );
    canvas.drawRect(bottomRect, fillPaint);
    canvas.drawRect(bottomRect, linePaint);

    // Alt pim deliği
    canvas.drawCircle(
      Offset(trunnionX, centerY + boreH / 2 + trunnionH / 2),
      pinR,
      linePaint..style = PaintingStyle.stroke,
    );
    linePaint.style = PaintingStyle.stroke;
  }

  /// Küresel yatak – arka tarafta basit daire
  void _drawSphericalRear(
    Canvas canvas,
    double bodyLeft,
    double centerY,
    double boreH,
    double mountLen,
    Paint linePaint,
    Paint fillPaint,
  ) {
    // Basit bir göz (eye) bağlantısı çiz
    final double eyeR = boreH * 0.22;
    final eyeCenter = Offset(bodyLeft - mountLen * 0.4, centerY);

    canvas.drawCircle(eyeCenter, eyeR, fillPaint);
    canvas.drawCircle(eyeCenter, eyeR, linePaint);
    canvas.drawCircle(eyeCenter, eyeR * 0.35, linePaint);
    canvas.drawCircle(
      eyeCenter,
      2,
      Paint()..color = linePaint.color,
    );

    // Gövdeye bağlantı
    canvas.drawLine(
      Offset(eyeCenter.dx + eyeR, centerY - boreH * 0.15),
      Offset(bodyLeft, centerY - boreH * 0.15),
      linePaint,
    );
    canvas.drawLine(
      Offset(eyeCenter.dx + eyeR, centerY + boreH * 0.15),
      Offset(bodyLeft, centerY + boreH * 0.15),
      linePaint,
    );
  }

  // ---------------------------------------------------------------------------
  // Ön Rod Ucu (her zaman göz bağlantısı olarak çizilir)
  // ---------------------------------------------------------------------------
  void _drawFrontRodEnd(
    Canvas canvas,
    double rodRight,
    double centerY,
    double rodH,
    double rodEndL,
    Paint linePaint,
    Paint fillPaint,
  ) {
    final double eyeR = rodH * 0.45;
    final eyeCenter = Offset(rodRight - rodEndL * 0.1, centerY);

    canvas.drawCircle(eyeCenter, eyeR, fillPaint);
    canvas.drawCircle(eyeCenter, eyeR, linePaint);
    // İç delik
    canvas.drawCircle(eyeCenter, eyeR * 0.35, linePaint);
    // Merkez noktası
    canvas.drawCircle(
      eyeCenter,
      1.5,
      Paint()..color = linePaint.color,
    );
  }

  // ---------------------------------------------------------------------------
  // Ölçü çizgisi yardımcıları (Dimension Line Helpers)
  // ---------------------------------------------------------------------------

  /// Yatay ölçü çizgisi – teknik resim standardına uygun
  ///
  ///   refY1        refY2
  ///    │             │         ← Extension lines (uzatma çizgileri)
  ///    │             │
  ///    ◄────────────►         ← Dimension line (ölçü çizgisi)
  ///         label              ← Ölçü metni
  void _drawHorizontalDimension({
    required Canvas canvas,
    required double y,
    required double x1,
    required double x2,
    required String label,
    required Paint paint,
    required TextStyle style,
    required double refY1,
    required double refY2,
  }) {
    // Extension lines (referans noktalarından ölçü çizgisine)
    final extPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final double extGap = 3;
    final double extOver = 3;

    if (y > refY1) {
      canvas.drawLine(Offset(x1, refY1 + extGap), Offset(x1, y + extOver), extPaint);
    } else {
      canvas.drawLine(Offset(x1, refY1 - extGap), Offset(x1, y - extOver), extPaint);
    }
    if (y > refY2) {
      canvas.drawLine(Offset(x2, refY2 + extGap), Offset(x2, y + extOver), extPaint);
    } else {
      canvas.drawLine(Offset(x2, refY2 - extGap), Offset(x2, y - extOver), extPaint);
    }

    // Dimension line (yatay ok çizgisi)
    canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);

    // Oklar
    _drawArrowHead(canvas, Offset(x1, y), 0, paint); // ← sol ok
    _drawArrowHead(canvas, Offset(x2, y), math.pi, paint); // → sağ ok

    // Label
    _drawTextCentered(canvas, label, Offset((x1 + x2) / 2, y - 10), style);
  }

  /// Dikey ölçü çizgisi
  void _drawVerticalDimension({
    required Canvas canvas,
    required double x,
    required double y1,
    required double y2,
    required String label,
    required Paint paint,
    required TextStyle style,
    required _DimSide side,
  }) {
    // Dimension line (dikey)
    canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);

    // Extension lines
    final extPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;

    final double extDir = side == _DimSide.left ? -1 : 1;
    // No extension lines needed for side dims – they connect to body edges

    // Oklar
    _drawArrowHead(canvas, Offset(x, y1), math.pi / 2, paint); // ↑
    _drawArrowHead(canvas, Offset(x, y2), -math.pi / 2, paint); // ↓

    // Label – rotated or side
    final labelOffset = side == _DimSide.left
        ? Offset(x - 8, (y1 + y2) / 2)
        : Offset(x + 8, (y1 + y2) / 2);

    _drawTextRotated(canvas, label, labelOffset, style, side);
  }

  /// Ok ucu çizimi (üçgen)
  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Paint paint) {
    const double arrowLen = 6;
    const double arrowHalfW = 2.5;

    final path = Path();
    path.moveTo(tip.dx, tip.dy);
    path.lineTo(
      tip.dx + arrowLen * math.cos(angle) + arrowHalfW * math.sin(angle),
      tip.dy + arrowLen * math.sin(angle) - arrowHalfW * math.cos(angle),
    );
    path.lineTo(
      tip.dx + arrowLen * math.cos(angle) - arrowHalfW * math.sin(angle),
      tip.dy + arrowLen * math.sin(angle) + arrowHalfW * math.cos(angle),
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill,
    );
  }

  /// Merkeze hizalı metin
  void _drawTextCentered(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  /// Dikey etiket için 90° döndürülmüş metin
  void _drawTextRotated(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle style,
    _DimSide side,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 2);
    tp.paint(canvas, Offset(-tp.width / 2, side == _DimSide.left ? -tp.height : 0));
    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Tarama (Hatch) ve yardımcı çizimler
  // ---------------------------------------------------------------------------

  /// Diagonal tarama (45° hatch lines) – kesit görünüşü efekti
  void _drawHatchArea(
    Canvas canvas,
    double left,
    double top,
    double right,
    double bottom,
    Paint paint,
  ) {
    const double spacing = 4.0;
    final double width = right - left;
    final double height = bottom - top;
    final double totalDiag = width + height;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, top, right, bottom));

    for (double d = 0; d < totalDiag; d += spacing) {
      canvas.drawLine(
        Offset(left + d, top),
        Offset(left + d - height, bottom),
        paint,
      );
    }

    canvas.restore();
  }

  /// Dash-dot merkez çizgisi (ISO teknik resim standardı)
  void _drawDashDotLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const double dashLen = 12;
    const double dotLen = 2;
    const double gap = 4;
    const double patternLen = dashLen + gap + dotLen + gap;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLen = math.sqrt(dx * dx + dy * dy);
    final ux = dx / totalLen;
    final uy = dy / totalLen;

    double d = 0;
    while (d < totalLen) {
      // Dash
      final double dEnd = math.min(d + dashLen, totalLen);
      canvas.drawLine(
        Offset(start.dx + ux * d, start.dy + uy * d),
        Offset(start.dx + ux * dEnd, start.dy + uy * dEnd),
        paint,
      );
      d = dEnd + gap;

      if (d >= totalLen) break;

      // Dot
      final double dotEnd = math.min(d + dotLen, totalLen);
      canvas.drawLine(
        Offset(start.dx + ux * d, start.dy + uy * d),
        Offset(start.dx + ux * dotEnd, start.dy + uy * dotEnd),
        paint,
      );
      d = dotEnd + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CylinderPainter oldDelegate) {
    return cylinder != oldDelegate.cylinder ||
        mountingType != oldDelegate.mountingType;
  }
}

/// Ölçü çizgisi yönü (sol/sağ)
enum _DimSide { left, right }
