import 'package:flutter/material.dart';

import '../models/hydraulic_cylinder.dart';
import '../models/mounting_type.dart';
import 'cylinder_drawing.dart';

/// ============================================================================
/// ResultsSheet - Hesap Sonuçları Alt Sayfası
/// ============================================================================
///
/// "Hesapla" butonuna basıldığında açılan DraggableScrollableSheet.
/// Tüm mühendislik hesap sonuçlarını kartlar halinde gösterir.
class ResultsSheet extends StatelessWidget {
  final double pushForce;
  final double pullForce;
  final double wallThickness;
  final BucklingResult buckling;
  final HydraulicCylinder cylinder;
  final MountingType mountingType;

  const ResultsSheet({
    super.key,
    required this.pushForce,
    required this.pullForce,
    required this.wallThickness,
    required this.buckling,
    required this.cylinder,
    required this.mountingType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Başlık
              Text(
                'Hesap Sonuclari',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${cylinder.boreDiameter.toStringAsFixed(0)}/'
                '${cylinder.rodDiameter.toStringAsFixed(0)} - '
                '${cylinder.stroke.toStringAsFixed(0)} mm  |  '
                '${cylinder.pressure.toStringAsFixed(0)} MPa',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // ── Teknik Resim ───────────────────────────────
              CylinderDrawing(
                cylinder: cylinder,
                mountingType: mountingType,
                height: 220,
              ),

              const SizedBox(height: 12),

              // ── Kuvvet Kartı ───────────────────────────────
              _ResultCard(
                icon: Icons.arrow_forward,
                title: 'Kuvvet Hesabi',
                color: colors.primary,
                children: [
                  _ResultRow(
                    label: 'Itme Kuvveti (Push)',
                    value: '${_formatForce(pushForce)} N',
                    sub: '${(_formatForce(pushForce / 1000))} kN',
                  ),
                  _ResultRow(
                    label: 'Cekme Kuvveti (Pull)',
                    value: '${_formatForce(pullForce)} N',
                    sub: '${_formatForce(pullForce / 1000)} kN',
                  ),
                  _ResultRow(
                    label: 'Kuvvet Orani',
                    value: '${(pullForce / pushForce * 100).toStringAsFixed(1)}%',
                    sub: 'F_pull / F_push',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Geometri Kartı ─────────────────────────────
              _ResultCard(
                icon: Icons.straighten,
                title: 'Geometri',
                color: colors.tertiary,
                children: [
                  _ResultRow(
                    label: 'Piston Alani',
                    value: '${cylinder.pistonArea.toStringAsFixed(1)} mm\u00B2',
                  ),
                  _ResultRow(
                    label: 'Halka Alan',
                    value: '${cylinder.annularArea.toStringAsFixed(1)} mm\u00B2',
                  ),
                  _ResultRow(
                    label: 'Acik Boy',
                    value: '${cylinder.openLength.toStringAsFixed(0)} mm',
                  ),
                  _ResultRow(
                    label: 'Min. Et Kalinligi (Lame)',
                    value: '${wallThickness.toStringAsFixed(2)} mm',
                    sub: 'SF = ${HydraulicCylinder.safetyFactor}',
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Burkulma Kartı ─────────────────────────────
              _ResultCard(
                icon: buckling.isSafe ? Icons.check_circle : Icons.warning,
                title: 'Burkulma Analizi (Euler)',
                color: buckling.isSafe ? Colors.green : colors.error,
                children: [
                  _ResultRow(
                    label: 'Baglanti Tipi',
                    value: buckling.mountingType.description,
                  ),
                  _ResultRow(
                    label: 'Kritik Burkulma Yuku',
                    value: '${_formatForce(buckling.criticalLoad)} N',
                    sub: '${_formatForce(buckling.criticalLoad / 1000)} kN',
                  ),
                  _ResultRow(
                    label: 'Uygulanan Yuk',
                    value: '${_formatForce(buckling.appliedLoad)} N',
                  ),
                  _ResultRow(
                    label: 'Etkili Boy',
                    value: '${buckling.effectiveLength.toStringAsFixed(1)} mm',
                  ),
                  const Divider(height: 16),
                  _BucklingSafetyIndicator(
                    factor: buckling.bucklingFactor,
                    isSafe: buckling.isSafe,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatForce(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    }
    return value.toStringAsFixed(0);
  }
}

// =============================================================================
// _ResultCard - Sonuç Kartı
// =============================================================================
class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _ResultCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// _ResultRow - Sonuç Satırı
// =============================================================================
class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _ResultRow({
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (sub != null)
                Text(
                  sub!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// _BucklingSafetyIndicator - Burkulma Emniyet Göstergesi
// =============================================================================
class _BucklingSafetyIndicator extends StatelessWidget {
  final double factor;
  final bool isSafe;

  const _BucklingSafetyIndicator({
    required this.factor,
    required this.isSafe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSafe ? Colors.green : theme.colorScheme.error;

    // Emniyet faktörünü 0-5 arasında normalize et (progress bar için)
    final progress = (factor / 5.0).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Emniyet Orani',
              style: theme.textTheme.titleSmall,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isSafe ? 'GUVENLI' : 'GUVENLI DEGIL',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              factor.toStringAsFixed(2),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '5.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
