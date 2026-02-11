import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/hydraulic_cylinder.dart';
import '../../models/mounting_type.dart';
import '../../models/mounting_types/front_flange.dart';
import '../../models/mounting_types/rear_clevis.dart';
import '../../models/mounting_types/spherical_bearing.dart';
import '../../models/mounting_types/trunnion.dart';
import '../engineering/engineering_painter.dart';

/// ============================================================================
/// CylinderAssemblyPainter - Hidrolik Silindir Montaj Resmi
/// ============================================================================
///
/// İstenen sıralama ve geometri mantığı:
/// 1) Arka kapak  x=0
/// 2) Boru        x=base.thickness .. base.thickness + tubeLength
/// 3) Piston      x=base.thickness + currentExtension
/// 4) Kep/Gland   boru sağ ucunda
/// 5) Arka/Ön bağlantılar
class CylinderAssemblyPainter extends EngineeringPainter {
  final HydraulicCylinder cylinder;
  final double currentExtension;
  final MountingType? rearMounting;
  final MountingType? frontMounting;

  const CylinderAssemblyPainter({
    required this.cylinder,
    required this.currentExtension,
    this.rearMounting,
    this.frontMounting,
  }) : super(
          modelWidthMm: _modelWidth(cylinder),
          modelHeightMm: _modelHeight(cylinder),
          canvasPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        );

  static double _modelWidth(HydraulicCylinder c) {
    final safeBase = c.base.thickness > 0 ? c.base.thickness : 12.0;
    final tubeLength = c.stroke + c.closedLength - safeBase;
    final safeHeadLen = c.head.totalLength > 0 ? c.head.totalLength : c.rodDiameter;
    final rodFrontOverhang = c.stroke + safeHeadLen * 0.45;
    final rearMountLen = math.max(20, c.boreDiameter * 0.35);
    final frontMountLen = math.max(20, c.rodDiameter * 1.2);
    return rearMountLen + safeBase + tubeLength + safeHeadLen + rodFrontOverhang + frontMountLen + 20;
  }

  static double _modelHeight(HydraulicCylinder c) {
    final safeHeadLen = c.head.totalLength > 0 ? c.head.totalLength : c.rodDiameter;
    final maxBody = math.max(c.boreDiameter, safeHeadLen * 0.9);
    return maxBody + 70;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ext = currentExtension.clamp(0.0, cylinder.stroke).toDouble();

    // Engineering logic inputs (fallback korumalı)
    final baseThickness =
        (cylinder.base.thickness > 0 ? cylinder.base.thickness : 12.0);
    final pistonWidth =
        (cylinder.piston.width > 0 ? cylinder.piston.width : cylinder.rodDiameter * 0.6);
    final headLength =
        (cylinder.head.totalLength > 0 ? cylinder.head.totalLength : cylinder.rodDiameter);

    final tubeLength = math.max(
      cylinder.stroke + cylinder.closedLength - baseThickness,
      cylinder.stroke + baseThickness,
    );
    final pistonX = baseThickness + ext;
    final headX = baseThickness + tubeLength;

    final boreR = math.max(cylinder.boreDiameter / 2, 5);
    final rodR = math.max(cylinder.rodDiameter / 2, 2);
    final centerY = 0.0;

    final bodyOutline = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rodPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final pistonPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.fill;

    // Layer 1: İç parçalar (piston + mil)
    final pistonHalfH = boreR * 0.88;
    final pistonRect = Rect.fromLTRB(
      pistonX,
      -pistonHalfH,
      pistonX + pistonWidth,
      pistonHalfH,
    );
    canvas.drawRect(modelRectToCanvasRect(pistonRect, size), pistonPaint);

    final rodStart = pistonX + pistonWidth;
    final rodEnd = headX + headLength + ext;
    final rodRect = Rect.fromLTRB(rodStart, -rodR, rodEnd, rodR);
    canvas.drawRect(modelRectToCanvasRect(rodRect, size), rodPaint);

    // Layer 2: Dış gövde (arka kapak, boru, kep)
    final baseRect = Rect.fromLTRB(0, -boreR, baseThickness, boreR);
    final tubeOuterRect = Rect.fromLTRB(baseThickness, -boreR, headX, boreR);
    final tubeInnerRect = Rect.fromLTRB(baseThickness, -boreR * 0.78, headX, boreR * 0.78);

    final headRect = Rect.fromLTRB(headX, -boreR, headX + headLength, boreR);
    final headBoreRect = Rect.fromLTRB(headX, -rodR * 1.15, headX + headLength, rodR * 1.15);

    final tubeSection = Path()
      ..addRect(modelRectToCanvasRect(tubeOuterRect, size));
    final tubeVoid = Path()
      ..addRect(modelRectToCanvasRect(tubeInnerRect, size));
    final tubePath = Path.combine(PathOperation.difference, tubeSection, tubeVoid);

    drawHatchedPath(
      canvas,
      size,
      tubePath,
      baseColor: Colors.grey.shade300,
      hatchColor: Colors.grey.shade500,
      hatchSpacingMm: 2.0,
      hatchStrokePx: 0.85,
    );

    final basePath = Path()..addRect(modelRectToCanvasRect(baseRect, size));
    drawHatchedPath(
      canvas,
      size,
      basePath,
      baseColor: Colors.grey.shade300,
      hatchColor: Colors.grey.shade500,
      hatchSpacingMm: 1.8,
      hatchStrokePx: 0.85,
    );

    final headOuter = Path()..addRect(modelRectToCanvasRect(headRect, size));
    final headInner = Path()..addRect(modelRectToCanvasRect(headBoreRect, size));
    final headSection = Path.combine(PathOperation.difference, headOuter, headInner);
    drawHatchedPath(
      canvas,
      size,
      headSection,
      baseColor: Colors.grey.shade300,
      hatchColor: Colors.grey.shade500,
      hatchSpacingMm: 1.8,
      hatchStrokePx: 0.85,
    );

    canvas.drawRect(modelRectToCanvasRect(baseRect, size), bodyOutline);
    canvas.drawRect(modelRectToCanvasRect(tubeOuterRect, size), bodyOutline);
    canvas.drawRect(modelRectToCanvasRect(headRect, size), bodyOutline);

    // Step 5: Dış bağlantılar
    final rear = rearMounting ?? const RearClevis(pinDiameter: 18, clevisWidth: 26, axisDistance: 20);
    final front = frontMounting ?? const SphericalBearing(sphereDiameter: 30, boreDiameter: 18);

    _drawRearMounting(canvas, size, rear, x: -12, centerY: centerY, bodyRadius: boreR);
    _drawFrontMounting(canvas, size, front, x: rodEnd, centerY: centerY, rodRadius: rodR);

    // Dinamik ölçülendirme
    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(baseThickness, boreR + 4),
      endMm: Offset(baseThickness + cylinder.stroke, boreR + 4),
      text: 'Stroke ${cylinder.stroke.toStringAsFixed(1)} mm',
      offsetMm: 4,
    );

    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(0, -(boreR + 6)),
      endMm: Offset(cylinder.closedLength, -(boreR + 6)),
      text: 'Closed ${cylinder.closedLength.toStringAsFixed(1)} mm',
      offsetMm: 4,
    );

    drawDimensionLine(
      canvas,
      size,
      startMm: Offset(pistonX, -pistonHalfH),
      endMm: Offset(pistonX + pistonWidth, -pistonHalfH),
      text: 'Piston ${pistonWidth.toStringAsFixed(1)}',
      offsetMm: 3,
    );

    // Extension info badge
    final info = TextPainter(
      text: TextSpan(
        text: 'Anlık Uzama: ${ext.toStringAsFixed(1)} mm',
        style: const TextStyle(
          color: Color(0xFF0066CC),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    info.paint(canvas, const Offset(12, 8));
  }

  void _drawRearMounting(
    Canvas canvas,
    Size size,
    MountingType type, {
    required double x,
    required double centerY,
    required double bodyRadius,
  }) {
    final p = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    if (type is RearClevis) {
      final w = math.max(type.clevisWidth, bodyRadius * 0.8);
      final h = bodyRadius * 0.85;
      final rect = modelRectToCanvasRect(Rect.fromLTRB(x - w, centerY - h, x, centerY + h), size);
      canvas.drawRect(rect, p);
      final holeR = mmToPixel(type.pinDiameter / 2, size).clamp(2.0, rect.height * 0.35).toDouble();
      canvas.drawCircle(rect.center, holeR, p);
      return;
    }

    final mountLen = bodyRadius * 0.9;
    final tri = Path()
      ..moveTo(modelToCanvas(Offset(x - mountLen, centerY), size).dx,
          modelToCanvas(Offset(x - mountLen, centerY), size).dy)
      ..lineTo(modelToCanvas(Offset(x, centerY + bodyRadius * 0.55), size).dx,
          modelToCanvas(Offset(x, centerY + bodyRadius * 0.55), size).dy)
      ..lineTo(modelToCanvas(Offset(x, centerY - bodyRadius * 0.55), size).dx,
          modelToCanvas(Offset(x, centerY - bodyRadius * 0.55), size).dy)
      ..close();
    canvas.drawPath(tri, p);
  }

  void _drawFrontMounting(
    Canvas canvas,
    Size size,
    MountingType type, {
    required double x,
    required double centerY,
    required double rodRadius,
  }) {
    final p = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    if (type is FrontFlange) {
      final d = math.max(type.flangeDiameter, rodRadius * 2.2);
      final rect = modelRectToCanvasRect(
        Rect.fromLTRB(x, centerY - d / 2, x + d * 0.28, centerY + d / 2),
        size,
      );
      canvas.drawRect(rect, p);
      return;
    }

    if (type is SphericalBearing) {
      final rOuter = mmToPixel(type.sphereDiameter / 2, size);
      final rInner = mmToPixel(type.boreDiameter / 2, size);
      final c = modelToCanvas(Offset(x + type.sphereDiameter / 2, centerY), size);
      canvas.drawCircle(c, rOuter, p);
      canvas.drawCircle(c, rInner, p);
      return;
    }

    if (type is Trunnion) {
      final w = mmToPixel(type.headDistance / 3, size).clamp(8.0, 26.0).toDouble();
      final h = mmToPixel(type.trunnionDiameter / 2, size).clamp(4.0, 14.0).toDouble();
      final c = modelToCanvas(Offset(x + 8, centerY), size);
      canvas.drawRect(Rect.fromCenter(center: c, width: w, height: h), p);
      return;
    }

    // fallback generic eye
    final c = modelToCanvas(Offset(x + rodRadius * 1.4, centerY), size);
    canvas.drawCircle(c, mmToPixel(rodRadius * 1.3, size), p);
  }

  @override
  bool shouldRepaint(covariant CylinderAssemblyPainter oldDelegate) {
    return oldDelegate.cylinder != cylinder ||
        oldDelegate.currentExtension != currentExtension ||
        oldDelegate.rearMounting != rearMounting ||
        oldDelegate.frontMounting != frontMounting;
  }
}
