import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../exceptions/hydraulic_exceptions.dart';
import '../models/hydraulic_cylinder.dart';
import '../models/mounting_type.dart';
import '../models/mounting_types/front_flange.dart';
import '../models/mounting_types/rear_clevis.dart';
import '../models/mounting_types/spherical_bearing.dart';
import '../models/mounting_types/trunnion.dart';
import '../widgets/results_sheet.dart';

/// ============================================================================
/// CylinderDesignScreen - Hidrolik Silindir Tasarım Ekranı
/// ============================================================================
///
/// Ana tasarım formu. Kullanıcıdan silindir parametrelerini ve bağlantı
/// tipini alarak hesaplamaları tetikler.
///
/// Polimorfik MountingType yapısı sayesinde, dropdown'dan seçilen bağlantı
/// tipine göre form alanları dinamik olarak değişir.
class CylinderDesignScreen extends StatefulWidget {
  const CylinderDesignScreen({super.key});

  @override
  State<CylinderDesignScreen> createState() => _CylinderDesignScreenState();
}

class _CylinderDesignScreenState extends State<CylinderDesignScreen> {
  final _formKey = GlobalKey<FormState>();

  // ---------------------------------------------------------------------------
  // Silindir temel parametre controller'ları
  // ---------------------------------------------------------------------------
  final _pressureCtrl = TextEditingController(text: '20');
  final _boreCtrl = TextEditingController(text: '80');
  final _rodCtrl = TextEditingController(text: '45');
  final _strokeCtrl = TextEditingController(text: '500');
  final _closedLengthCtrl = TextEditingController(text: '700');

  // ---------------------------------------------------------------------------
  // Bağlantı tipi state
  // ---------------------------------------------------------------------------
  MountingCategory _selectedCategory = MountingCategory.frontFlange;

  /// Seçili bağlantı tipinin form alanları için controller'lar.
  /// Key = FormFieldDescriptor.key, Value = TextEditingController
  /// Dropdown her değiştiğinde yeniden oluşturulur.
  Map<String, TextEditingController> _mountingControllers = {};

  @override
  void initState() {
    super.initState();
    _rebuildMountingControllers();
  }

  @override
  void dispose() {
    _pressureCtrl.dispose();
    _boreCtrl.dispose();
    _rodCtrl.dispose();
    _strokeCtrl.dispose();
    _closedLengthCtrl.dispose();
    for (final ctrl in _mountingControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// Seçilen bağlantı tipine göre mounting controller'larını yeniden oluşturur.
  void _rebuildMountingControllers() {
    for (final ctrl in _mountingControllers.values) {
      ctrl.dispose();
    }

    final mounting = MountingType.fromCategory(_selectedCategory);
    _mountingControllers = {
      for (final field in mounting.formFields) field.key: TextEditingController(),
    };
  }

  // ---------------------------------------------------------------------------
  // Hesaplama
  // ---------------------------------------------------------------------------
  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    try {
      // 1. Silindir oluştur
      final cylinder = HydraulicCylinder(
        pressure: double.parse(_pressureCtrl.text),
        boreDiameter: double.parse(_boreCtrl.text),
        rodDiameter: double.parse(_rodCtrl.text),
        stroke: double.parse(_strokeCtrl.text),
        closedLength: double.parse(_closedLengthCtrl.text),
      );

      // 2. Bağlantı tipini oluştur (form verilerinden)
      final mounting = _buildMountingFromForm();

      // 3. Bağlantı validasyonu
      mounting.validate();

      // 4. Hesaplamalar
      final pushForce = cylinder.calculatePushForce();
      final pullForce = cylinder.calculatePullForce();
      final wallThickness = cylinder.calculateWallThickness();
      final buckling = cylinder.checkBuckling(mounting);

      // 5. Sonuçları göster
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => ResultsSheet(
          pushForce: pushForce,
          pullForce: pullForce,
          wallThickness: wallThickness,
          buckling: buckling,
          cylinder: cylinder,
          mountingType: mounting,
        ),
      );
    } on HydraulicCylinderException catch (e) {
      _showError(e.message);
    }
  }

  /// Formdan okunan değerlerle uygun MountingType alt sınıfı oluşturur.
  MountingType _buildMountingFromForm() {
    double _val(String key) =>
        double.tryParse(_mountingControllers[key]?.text ?? '') ?? 0;
    int _intVal(String key) =>
        int.tryParse(_mountingControllers[key]?.text ?? '') ?? 0;

    switch (_selectedCategory) {
      case MountingCategory.frontFlange:
        return FrontFlange(
          flangeDiameter: _val('flangeDiameter'),
          boltCircleDiameter: _val('boltCircleDiameter'),
          boltCount: _intVal('boltCount'),
        );
      case MountingCategory.rearClevis:
        return RearClevis(
          pinDiameter: _val('pinDiameter'),
          clevisWidth: _val('clevisWidth'),
          axisDistance: _val('axisDistance'),
        );
      case MountingCategory.trunnion:
        return Trunnion(
          headDistance: _val('headDistance'),
          trunnionDiameter: _val('trunnionDiameter'),
        );
      case MountingCategory.sphericalBearing:
        return SphericalBearing(
          sphereDiameter: _val('sphereDiameter'),
          boreDiameter: _val('boreDiameter'),
        );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidrolik Silindir Tasarım'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // ── Silindir Parametreleri ──────────────────────────────────
            _SectionHeader(
              icon: Icons.straighten,
              title: 'Silindir Parametreleri',
              color: colors.primary,
            ),
            const SizedBox(height: 12),

            // Basınç
            _NumericField(
              controller: _pressureCtrl,
              label: 'Çalışma Basıncı (P)',
              suffix: 'MPa',
              hint: '1 MPa = 10 bar',
              min: 0.1,
              max: 100,
            ),
            const SizedBox(height: 12),

            // Boru Çapı & Rod Çapı yan yana
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    controller: _boreCtrl,
                    label: 'Boru Çapı (D)',
                    suffix: 'mm',
                    hint: 'Piston iç çapı',
                    min: 10,
                    max: 500,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumericField(
                    controller: _rodCtrl,
                    label: 'Rod Çapı (d)',
                    suffix: 'mm',
                    hint: 'Piston kolu çapı',
                    min: 5,
                    max: 400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Strok & Kapalı Boy yan yana
            Row(
              children: [
                Expanded(
                  child: _NumericField(
                    controller: _strokeCtrl,
                    label: 'Strok (L)',
                    suffix: 'mm',
                    hint: 'Hareket mesafesi',
                    min: 10,
                    max: 10000,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NumericField(
                    controller: _closedLengthCtrl,
                    label: 'Kapalı Boy',
                    suffix: 'mm',
                    hint: 'Söküm arası mesafe',
                    min: 20,
                    max: 15000,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Bağlantı Tipi ──────────────────────────────────────────
            _SectionHeader(
              icon: Icons.settings,
              title: 'Ön Bağlantı Tipi',
              color: colors.secondary,
            ),
            const SizedBox(height: 12),

            // Dropdown
            DropdownButtonFormField<MountingCategory>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Bağlantı Tipi Seçin',
                prefixIcon: Icon(
                  _iconForCategory(_selectedCategory),
                  color: colors.secondary,
                ),
              ),
              items: MountingCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.label),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat == null) return;
                setState(() {
                  _selectedCategory = cat;
                  _rebuildMountingControllers();
                });
              },
            ),

            const SizedBox(height: 16),

            // Dinamik bağlantı parametreleri
            // Polimorfik formFields listesinden otomatik oluşturulur
            _buildMountingFields(colors),
          ],
        ),
      ),

      // ── Hesapla Butonu ─────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _calculate,
        icon: const Icon(Icons.calculate),
        label: const Text('Hesapla'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ---------------------------------------------------------------------------
  // Dinamik Bağlantı Alanları - Polimorfizmin UI'a yansıması
  // ---------------------------------------------------------------------------
  Widget _buildMountingFields(ColorScheme colors) {
    final mounting = MountingType.fromCategory(_selectedCategory);
    final fields = mounting.formFields;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Card(
        key: ValueKey(_selectedCategory),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bağlantı tipi başlığı & Euler bilgisi
              Row(
                children: [
                  Icon(
                    _iconForCategory(_selectedCategory),
                    size: 20,
                    color: colors.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      mounting.description,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Euler katsayı bilgisi
              Text(
                'Euler: n = ${mounting.endFixityCoefficient}, '
                'K = ${mounting.effectiveLengthFactor}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),

              const Divider(height: 24),

              // Form alanları - formFields listesinden dinamik oluşturuluyor
              ...fields.map((field) {
                final controller = _mountingControllers[field.key];
                if (controller == null) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NumericField(
                    controller: controller,
                    label: field.label,
                    suffix: field.unit,
                    hint: field.hint,
                    min: field.min,
                    max: field.max,
                    isInteger: field.isInteger,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Her bağlantı tipi kategorisi için ikon.
  IconData _iconForCategory(MountingCategory cat) {
    switch (cat) {
      case MountingCategory.frontFlange:
        return Icons.circle_outlined;
      case MountingCategory.rearClevis:
        return Icons.link;
      case MountingCategory.trunnion:
        return Icons.pivot_table_chart;
      case MountingCategory.sphericalBearing:
        return Icons.sports_baseball;
    }
  }
}

// =============================================================================
// _SectionHeader - Bölüm Başlığı
// =============================================================================
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

// =============================================================================
// _NumericField - Sayısal Giriş Alanı
// =============================================================================
class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final String? hint;
  final double min;
  final double max;
  final bool isInteger;

  const _NumericField({
    required this.controller,
    required this.label,
    required this.suffix,
    this.hint,
    required this.min,
    required this.max,
    this.isInteger = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: !isInteger,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isInteger ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: hint,
        helperMaxLines: 2,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Zorunlu alan';
        final v = double.tryParse(value);
        if (v == null) return 'Geçerli bir sayı girin';
        if (v < min) return 'Min: $min $suffix';
        if (v > max) return 'Max: $max $suffix';
        return null;
      },
    );
  }
}
