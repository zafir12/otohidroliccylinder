import 'package:flutter/material.dart';

import '../models/hydraulic_cylinder.dart';
import '../models/mounting_type.dart';
import '../models/mounting_types/rear_clevis.dart';
import 'painters/assembly_painter.dart';

/// ============================================================================
/// CylinderPreviewWidget - Slider'lı Montaj Önizleme
/// ============================================================================
///
/// currentExtension slider ile güncellenir ve piston hareketi
/// [CylinderAssemblyPainter] üzerinden anlık olarak görselleştirilir.
class CylinderPreviewWidget extends StatefulWidget {
  final HydraulicCylinder cylinder;
  final MountingType? rearMounting;
  final MountingType? frontMounting;
  final double height;

  const CylinderPreviewWidget({
    super.key,
    required this.cylinder,
    this.rearMounting,
    this.frontMounting,
    this.height = 280,
  });

  @override
  State<CylinderPreviewWidget> createState() => _CylinderPreviewWidgetState();
}

class _CylinderPreviewWidgetState extends State<CylinderPreviewWidget> {
  double _currentExtension = 0;

  @override
  void didUpdateWidget(covariant CylinderPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cylinder.stroke != widget.cylinder.stroke &&
        _currentExtension > widget.cylinder.stroke) {
      _currentExtension = widget.cylinder.stroke;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Silindir Montaj Önizleme',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: widget.height,
              child: CustomPaint(
                painter: CylinderAssemblyPainter(
                  cylinder: widget.cylinder,
                  currentExtension: _currentExtension,
                  rearMounting: widget.rearMounting ??
                      const RearClevis(
                        pinDiameter: 18,
                        clevisWidth: 26,
                        axisDistance: 20,
                      ),
                  frontMounting: widget.frontMounting,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uzama: ${_currentExtension.toStringAsFixed(1)} / '
              '${widget.cylinder.stroke.toStringAsFixed(1)} mm',
              style: theme.textTheme.bodyMedium,
            ),
            Slider(
              min: 0,
              max: widget.cylinder.stroke,
              value: _currentExtension.clamp(0.0, widget.cylinder.stroke).toDouble(),
              onChanged: (value) {
                setState(() => _currentExtension = value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
