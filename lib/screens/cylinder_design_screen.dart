import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../exceptions/hydraulic_exceptions.dart';
import '../models/hydraulic_cylinder.dart';
import '../models/internal_parts.dart';
import '../models/mounting_type.dart';
import '../services/pdf_generator_service.dart';
import '../widgets/painters/assembly_painter.dart';
import '../widgets/results_sheet.dart';

/// ============================================================================
/// CylinderDesignScreen - Faz 5 Simülasyon & Mühendislik Güvenlik Arayüzü
/// ============================================================================
///
/// 1) Görsel simülasyon katmanı (Assembly painter + slider)
/// 2) Girdi katmanı (form + ön/arka bağlantı tipi)
/// 3) Canlı mühendislik denetçisi (real-time uyarı kartları)
class CylinderDesignScreen extends StatefulWidget {
  const CylinderDesignScreen({super.key});

  @override
  State<CylinderDesignScreen> createState() => _CylinderDesignScreenState();
}

class _CylinderDesignScreenState extends State<CylinderDesignScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form kontrolcüleri
  final _pressureBarCtrl = TextEditingController(text: '200');
  final _boreCtrl = TextEditingController(text: '80');
  final _rodCtrl = TextEditingController(text: '45');
  final _strokeCtrl = TextEditingController(text: '500');

  // Simülasyon: 0.0 kapalı, 1.0 tam açık
  double _simulationValue = 0.0;

  // Ön/Arka montaj seçimi
  MountingCategory _frontMountingCategory = MountingCategory.frontFlange;
  MountingCategory _rearMountingCategory = MountingCategory.rearClevis;

  @override
  void initState() {
    super.initState();
    _pressureBarCtrl.addListener(_onInputChanged);
    _boreCtrl.addListener(_onInputChanged);
    _rodCtrl.addListener(_onInputChanged);
    _strokeCtrl.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _pressureBarCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    _boreCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    _rodCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    _strokeCtrl
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  double? _parse(TextEditingController c) => double.tryParse(c.text.trim());

  /// Örnek/varsayılan montaj nesnesi (euler katsayıları için yeterli).
  MountingType _mountingFromCategory(MountingCategory category) {
    return MountingType.fromCategory(category);
  }

  /// Form verilerinden güvenli bir silindir nesnesi üretir.
  HydraulicCylinder? _buildPreviewCylinder() {
    final pressureBar = _parse(_pressureBarCtrl);
    final bore = _parse(_boreCtrl);
    final rod = _parse(_rodCtrl);
    final stroke = _parse(_strokeCtrl);

    if (pressureBar == null || bore == null || rod == null || stroke == null) {
      return null;
    }

    final pressureMpa = pressureBar / 10.0;

    // Kapalı boy alanı UI'da olmadığı için emniyetli türetim
    final pistonWidth = rod * 0.6;
    final headLength = math.max(rod * 1.2, 25);
    final baseThickness = math.max(bore * 0.12, 12);
    final extraMargin = HydraulicCylinder.defaultExtraMargin;

    final minClosed = pistonWidth + headLength + baseThickness + stroke + extraMargin;
    final derivedClosedLength = minClosed + 20; // ekstra montaj emniyeti

    try {
      return HydraulicCylinder(
        pressure: pressureMpa,
        boreDiameter: bore,
        rodDiameter: rod,
        stroke: stroke,
        closedLength: derivedClosedLength,
        piston: CylinderPiston(rodDiameter: rod, width: pistonWidth),
        head: CylinderHead(
          totalLength: headLength,
          guideLength: rod,
          rodDiameter: rod,
        ),
        base: CylinderBase(thickness: baseThickness),
      );
    } on HydraulicCylinderException {
      return null;
    }
  }

  /// Build içinde çağrılır. Uyarıları metin listesi olarak döndürür.
  List<String> _validateDesign({
    required HydraulicCylinder? cylinder,
    required MountingType frontMounting,
  }) {
    final issues = <String>[];

    // Ham değerler üzerinden fiziksel imkansızlık kontrolü
    final bore = _parse(_boreCtrl);
    final rod = _parse(_rodCtrl);
    final stroke = _parse(_strokeCtrl);

    if (bore != null && rod != null && rod >= bore) {
      issues.add('KRİTİK UYARI: Rod çapı, boru çapından büyük/eşit olamaz.');
    }

    if (cylinder == null) {
      issues.add('KRİTİK UYARI: Geçerli parametre seti oluşturulamadı.');
      return issues;
    }

    // Kural 1 - Burkulma
    try {
      final buckling = cylinder.checkBuckling(frontMounting);
      if (buckling.bucklingFactor < HydraulicCylinder.safetyFactor) {
        issues.add(
          'KRİTİK UYARI: Mil burkulma riski! '
          'Emniyet katsayısı ${buckling.bucklingFactor.toStringAsFixed(2)} < 2.5. '
          'Rod çapını büyütün veya stroku azaltın.',
        );
      }
    } on HydraulicCylinderException {
      issues.add('KRİTİK UYARI: Burkulma analizi hesaplanamadı.');
    }

    // Kural 2 - Et kalınlığı (nominal varsayım: t_nominal = D * 0.10)
    try {
      final requiredWall = cylinder.calculateWallThickness();
      final nominalWall = cylinder.boreDiameter * 0.10;
      if (requiredWall > nominalWall) {
        issues.add(
          'KRİTİK UYARI: Boru et kalınlığı yetersiz olabilir. '
          'Gereken min: ${requiredWall.toStringAsFixed(2)} mm, '
          'nominal varsayım: ${nominalWall.toStringAsFixed(2)} mm.',
        );
      }
    } on HydraulicCylinderException {
      issues.add('KRİTİK UYARI: Basınç-et kalınlığı kontrolü başarısız.');
    }

    // Kural 3 - Uzun strok / stop tube önerisi
    if (stroke != null && stroke > 1000) {
      final ratio = cylinder.rodDiameter / cylinder.boreDiameter;
      if (ratio < 0.55) {
        issues.add(
          'UZUN STROK UYARISI: Stop borusu (spacer) kullanılması önerilir '
          '(Stroke > 1000 mm ve Rod/Boru oranı düşük).',
        );
      }
    }

    return issues;
  }

  void _calculateAndShowResults() {
    if (!_formKey.currentState!.validate()) return;

    final cylinder = _buildPreviewCylinder();
    if (cylinder == null) {
      _showError('Geçerli silindir parametreleri üretilemedi.');
      return;
    }

    final frontMounting = _mountingFromCategory(_frontMountingCategory);

    // Güvenlik kapısı
    final issues = _validateDesign(
      cylinder: cylinder,
      frontMounting: frontMounting,
    );
    if (issues.isNotEmpty) {
      _showError('Kritik uyarılar giderilmeden hesaplama/PDF işlemi başlatılamaz.');
      return;
    }

    try {
      final pushForce = cylinder.calculatePushForce();
      final pullForce = cylinder.calculatePullForce();
      final wallThickness = cylinder.calculateWallThickness();
      final buckling = cylinder.checkBuckling(frontMounting);

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
          mountingType: frontMounting,
        ),
      );
    } on HydraulicCylinderException catch (e) {
      _showError(e.message);
    }
  }



  Future<void> _generateAndSharePdf() async {
    if (!_formKey.currentState!.validate()) return;

    final cylinder = _buildPreviewCylinder();
    if (cylinder == null) {
      _showError('PDF için geçerli silindir parametreleri üretilemedi.');
      return;
    }

    final frontMounting = _mountingFromCategory(_frontMountingCategory);
    final rearMounting = _mountingFromCategory(_rearMountingCategory);

    final issues = _validateDesign(
      cylinder: cylinder,
      frontMounting: frontMounting,
    );
    if (issues.isNotEmpty) {
      _showError('Kritik uyarılar varken PDF oluşturulamaz.');
      return;
    }

    try {
      final pdfBytes = await PdfGeneratorService.generateTechnicalSheet(
        cylinder: cylinder,
        frontMounting: frontMounting,
        rearMounting: rearMounting,
        projectName: 'Silindir Tasarım Raporu',
        revision: 'A',
      );

      await PdfGeneratorService.sharePdf(
        bytes: pdfBytes,
        fileName: 'silindir_raporu.pdf',
      );
    } catch (_) {
      _showError('PDF oluşturma/paylaşma sırasında hata oluştu.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final previewCylinder = _buildPreviewCylinder();
    final frontMounting = _mountingFromCategory(_frontMountingCategory);
    final rearMounting = _mountingFromCategory(_rearMountingCategory);

    final issues = _validateDesign(
      cylinder: previewCylinder,
      frontMounting: frontMounting,
    );

    final canCalculate = issues.isEmpty && previewCylinder != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Silindir Tasarım & Simülasyon'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // 1) GÖRSEL SİMÜLASYON KATMANI
            _SectionHeader(
              icon: Icons.animation,
              title: 'Görsel Simülasyon',
              color: colors.primary,
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 250,
                      child: previewCylinder == null
                          ? Center(
                              child: Text(
                                'Önizleme için geçerli giriş verisi bekleniyor.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            )
                          : CustomPaint(
                              painter: CylinderAssemblyPainter(
                                cylinder: previewCylinder,
                                currentExtension:
                                    _simulationValue * previewCylinder.stroke,
                                rearMounting: rearMounting,
                                frontMounting: frontMounting,
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Simülasyon: %${(_simulationValue * 100).toStringAsFixed(0)} '
                      '(0: Kapalı, 100: Tam Açık)',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Slider(
                      min: 0,
                      max: 1,
                      value: _simulationValue,
                      onChanged: (value) => setState(() => _simulationValue = value),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // 2) GİRDİ KATMANI
            _SectionHeader(
              icon: Icons.tune,
              title: 'Girdi Parametreleri',
              color: colors.secondary,
            ),
            const SizedBox(height: 10),
            _NumericField(
              controller: _pressureBarCtrl,
              label: 'Basınç',
              suffix: 'bar',
              min: 1,
              max: 700,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _NumericField(
              controller: _boreCtrl,
              label: 'Boru İç Çapı',
              suffix: 'mm',
              min: 10,
              max: 600,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _NumericField(
              controller: _rodCtrl,
              label: 'Rod Çapı',
              suffix: 'mm',
              min: 5,
              max: 400,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _NumericField(
              controller: _strokeCtrl,
              label: 'Strok',
              suffix: 'mm',
              min: 10,
              max: 12000,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MountingCategory>(
                    value: _rearMountingCategory,
                    decoration: const InputDecoration(
                      labelText: 'Arka Bağlantı',
                    ),
                    items: MountingCategory.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _rearMountingCategory = value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<MountingCategory>(
                    value: _frontMountingCategory,
                    decoration: const InputDecoration(
                      labelText: 'Ön Bağlantı',
                    ),
                    items: MountingCategory.values
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.label)))
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _frontMountingCategory = value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // 3) CANLI MÜHENDİSLİK DENETÇİSİ
            _SectionHeader(
              icon: Icons.health_and_safety,
              title: 'Canlı Mühendislik Denetçisi',
              color: issues.isEmpty ? Colors.green : colors.error,
            ),
            const SizedBox(height: 10),
            if (issues.isEmpty)
              Card(
                elevation: 0,
                color: Colors.green.withOpacity(0.08),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Tüm temel güvenlik kontrolleri geçti.'),
                ),
              )
            else
              ...issues.map(
                (issue) => Card(
                  elevation: 0,
                  color: colors.errorContainer.withOpacity(0.8),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded, color: colors.error),
                    title: Text(
                      issue,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: canCalculate ? _calculateAndShowResults : null,
              icon: const Icon(Icons.calculate),
              label: const Text('Hesapla (Sonuçlar)'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canCalculate ? _generateAndSharePdf : null,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF İndir / Paylaş'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

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
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final double min;
  final double max;
  final ValueChanged<String>? onChanged;

  const _NumericField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.min,
    required this.max,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
      onChanged: onChanged,
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
