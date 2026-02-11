import 'package:flutter/material.dart';

import '../models/hydraulic_cylinder.dart';
import '../models/mounting_type.dart';
import 'cylinder_painter.dart';

/// ============================================================================
/// CylinderDrawing - Teknik Resim Widget'ı
/// ============================================================================
///
/// [CylinderPainter]'ı saran, boyutlandırma ve tema uyumu sağlayan widget.
///
/// Kullanım:
/// ```dart
/// CylinderDrawing(
///   cylinder: myCylinder,
///   mountingType: myMounting,
///   height: 220,
/// )
/// ```
class CylinderDrawing extends StatelessWidget {
  final HydraulicCylinder cylinder;
  final MountingType mountingType;
  final double height;

  const CylinderDrawing({
    super.key,
    required this.cylinder,
    required this.mountingType,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.draw,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Teknik Resim (Yan Gorunus)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Canvas
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: CustomPaint(
                painter: CylinderPainter(
                  cylinder: cylinder,
                  mountingType: mountingType,
                  primaryColor: isDark
                      ? const Color(0xFFB0BEC5) // Blue Grey 200
                      : const Color(0xFF37474F), // Blue Grey 800
                  dimensionColor: isDark
                      ? const Color(0xFFEF9A9A) // Red 200
                      : const Color(0xFFE53935), // Red 600
                  mountingColor: isDark
                      ? const Color(0xFF90CAF9) // Blue 200
                      : const Color(0xFF1565C0), // Blue 800
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
