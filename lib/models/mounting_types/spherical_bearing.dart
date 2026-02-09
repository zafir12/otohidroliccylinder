import '../../exceptions/hydraulic_exceptions.dart';
import '../mounting_type.dart';

/// ============================================================================
/// SphericalBearing - Oynak Başlık Bağlantı Tipi
/// ============================================================================
///
/// Rod ucuna vidalanan küresel (sferik) yatak bağlantısı.
/// 3 eksende serbest dönme sağlar → eksenel olmayan yüklerin
/// rod'a eğilme momenti oluşturmasını engeller.
///
/// Tipik kullanım: Açısal hizalama toleransı gereken uygulamalar,
///                 çoklu eksen hareketli mekanizmalar, titreşimli ortamlar.
///
///         Rod ucu
///           │
///      ┌────┴────┐
///      │  ┌───┐  │
///      │  │(●)│  │  ← Küre (Sphere Ø)
///      │  └───┘  │
///      └────┬────┘
///           │
///      Bağlantı deliği (bore Ø)
///           │
///      Yük elemanı
///
/// Euler Katsayısı:
///   Oynak başlık = Serbest uç (Free) → 3 eksende serbest dönme.
///   Gövde tarafı genellikle rijit (flanş/kaynak) → Ankastre (Fixed).
///   → Fixed-Free (Cantilever): n = 0.25, K = 2.0
///
///   Bu en kritik burkulma durumudur! Etkili boy, fiziksel boyun
///   2 katıdır. Uzun stroklu silindirlerde dikkatle değerlendirilmelidir.
///
/// Parametreler:
///   - sphereDiameter: Küre dış çapı [mm]
///   - boreDiameter: İç delik çapı (bağlantı pimi için) [mm]
///
/// Tasarım kuralları:
///   - sphereDiameter > boreDiameter (et kalınlığı gerekli)
///   - İkisi de > 0
///   - Et kalınlığı: t = (sphereDiameter - boreDiameter) / 2 ≥ 3 mm
/// ============================================================================
class SphericalBearing extends MountingType {
  /// Küre dış çapı [mm]
  /// Standart sferik yatak serileri: 12, 14, 16, 18, 20, 22, 25, 30, 35...
  /// DIN 648 / ISO 12240 standartlarına göre.
  final double sphereDiameter;

  /// İç delik çapı [mm]
  /// Bağlantı piminin geçeceği delik.
  /// Genellikle H7 toleransında işlenir.
  final double boreDiameter;

  const SphericalBearing({
    required this.sphereDiameter,
    required this.boreDiameter,
  });

  /// Boş (varsayılan) SphericalBearing. Factory method tarafından kullanılır.
  factory SphericalBearing.empty() => const SphericalBearing(
        sphereDiameter: 0,
        boreDiameter: 0,
      );

  /// JSON'dan SphericalBearing oluşturur.
  factory SphericalBearing.fromJson(Map<String, dynamic> json) =>
      SphericalBearing(
        sphereDiameter: (json['sphereDiameter'] as num).toDouble(),
        boreDiameter: (json['boreDiameter'] as num).toDouble(),
      );

  // --- Euler Katsayıları ---
  // Oynak başlık = Serbest (Free), Gövde tarafı = Ankastre (Fixed)
  // → Fixed-Free (Cantilever): n = 0.25
  // EN KRİTİK DURUM! Etkili boy = 2 × fiziksel boy.

  @override
  MountingCategory get category => MountingCategory.sphericalBearing;

  @override
  String get description =>
      'Oynak Başlık (Spherical Bearing) – Serbest uç bağlantı';

  @override
  double get endFixityCoefficient => 0.25;

  @override
  double get effectiveLengthFactor => 2.0;

  @override
  List<FormFieldDescriptor> get formFields => const [
        FormFieldDescriptor(
          key: 'sphereDiameter',
          label: 'Küre Çapı',
          unit: 'mm',
          min: 10,
          max: 200,
          hint: 'DIN 648 / ISO 12240 standart serisi: 12, 16, 20, 25, 30...',
        ),
        FormFieldDescriptor(
          key: 'boreDiameter',
          label: 'Delik Çapı',
          unit: 'mm',
          min: 5,
          max: 150,
          hint: 'Bağlantı pimi delik çapı (H7 tolerans)',
        ),
      ];

  @override
  bool validate() {
    if (sphereDiameter <= 0) {
      throw const MountingValidationException(
        'Küre çapı sıfır veya negatif olamaz.',
        parameterName: 'sphereDiameter',
      );
    }

    if (boreDiameter <= 0) {
      throw const MountingValidationException(
        'Delik çapı sıfır veya negatif olamaz.',
        parameterName: 'boreDiameter',
      );
    }

    // Küre çapı, delik çapından büyük olmalı.
    // Aksi halde küresel yatak et kalınlığı kalmaz → yapısal bütünlük yok.
    if (boreDiameter >= sphereDiameter) {
      throw MountingValidationException(
        'Delik çapı ($boreDiameter mm) küre çapından '
        '($sphereDiameter mm) küçük olmalıdır.',
        parameterName: 'boreDiameter',
      );
    }

    // Minimum et kalınlığı kontrolü
    // Küresel yatakta yeterli malzeme kalınlığı gerekir.
    // t = (D_küre - d_delik) / 2
    // Minimum et kalınlığı: 3 mm (yapısal dayanım için)
    final double wallThickness = (sphereDiameter - boreDiameter) / 2;
    if (wallThickness < 3.0) {
      throw MountingValidationException(
        'Küresel yatak et kalınlığı çok ince '
        '(${wallThickness.toStringAsFixed(1)} mm). Minimum 3 mm gereklidir. '
        'Küre çapını artırın veya delik çapını küçültün.',
        parameterName: 'sphereDiameter',
      );
    }

    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
        'category': category.name,
        'sphereDiameter': sphereDiameter,
        'boreDiameter': boreDiameter,
      };
}
