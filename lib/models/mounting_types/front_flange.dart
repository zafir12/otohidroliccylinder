import 'dart:math' as math;

import '../../exceptions/hydraulic_exceptions.dart';
import '../mounting_type.dart';

/// ============================================================================
/// FrontFlange - Ön Flanş Bağlantı Tipi
/// ============================================================================
///
/// Silindirin ön kapağına (head-end) cıvata ile bağlanan flanş tipi montaj.
/// Rijit bir bağlantı sağlar → Euler uç koşulu: "Ankastre" (Fixed).
///
/// Tipik kullanım: Pres makineleri, enjeksiyon kalıpları, sabit tesisatlar.
///
///        ┌──────────────────┐
///   ─────┤    SİLİNDİR      ├──── Rod →
///        └──────────────────┘
///        ▲
///        │
///   ┌────┴────┐
///   │  FLANŞ  │  ← Cıvata delikleri dairesel dizilimde
///   │  ○  ○   │
///   │ ○    ○  │     Delik Eksen Çapı (BCD)
///   │  ○  ○   │
///   └─────────┘
///        ▲
///   ─────┴───── Makine Şasesi
///
/// Euler Katsayısı:
///   Flanş bağlantısı rijit kabul edilir (ankastre).
///   Rod ucu genellikle mafsal (pin) ile yüke bağlanır.
///   → Fixed-Pin konfigürasyonu: n = 2.0, K = 0.707
///
/// Parametreler:
///   - flangeDiameter (D_f): Flanşın dış çapı [mm]
///   - boltCircleDiameter (BCD): Cıvata delik merkezlerinin çapı [mm]
///   - boltCount: Cıvata delik sayısı [adet]
///
/// Tasarım kuralları:
///   - D_f > BCD (flanş çapı, delik çapından büyük olmalı)
///   - BCD > 0
///   - boltCount ≥ 3 (statik denge için minimum 3 cıvata)
///   - boltCount genellikle çift sayıdır (4, 6, 8)
/// ============================================================================
class FrontFlange extends MountingType {
  /// Flanşın dış çapı [mm]
  /// ISO 6020-2 standart serileri: 80, 100, 125, 160, 200, 250...
  final double flangeDiameter;

  /// Cıvata Delik Eksen Çapı (Bolt Circle Diameter - BCD) [mm]
  /// Cıvataların merkezlerinin oluşturduğu dairenin çapı.
  /// Pratikte: BCD ≈ D_f × 0.75 – 0.85
  final double boltCircleDiameter;

  /// Cıvata delik sayısı [adet]
  /// Minimum 3, tipik olarak 4 veya 6.
  /// Eşit açısal aralıkla yerleştirilir: açı = 360° / boltCount
  final int boltCount;

  const FrontFlange({
    required this.flangeDiameter,
    required this.boltCircleDiameter,
    required this.boltCount,
  });

  /// Boş (varsayılan) FrontFlange. Factory method tarafından kullanılır.
  /// UI form alanları doldurulmadan önce placeholder olarak oluşturulur.
  factory FrontFlange.empty() => const FrontFlange(
        flangeDiameter: 0,
        boltCircleDiameter: 0,
        boltCount: 0,
      );

  /// JSON'dan FrontFlange oluşturur.
  factory FrontFlange.fromJson(Map<String, dynamic> json) => FrontFlange(
        flangeDiameter: (json['flangeDiameter'] as num).toDouble(),
        boltCircleDiameter: (json['boltCircleDiameter'] as num).toDouble(),
        boltCount: json['boltCount'] as int,
      );

  // --- Euler Katsayıları ---
  // Flanş = Ankastre (Fixed), Rod ucu = Mafsal (Pin)
  // → Fixed-Pin: n = 2.0

  @override
  MountingCategory get category => MountingCategory.frontFlange;

  @override
  String get description => 'Ön Flanş (Front Flange) – Ankastre bağlantı';

  @override
  double get endFixityCoefficient => 2.0;

  @override
  double get effectiveLengthFactor => 0.707;

  @override
  List<FormFieldDescriptor> get formFields => const [
        FormFieldDescriptor(
          key: 'flangeDiameter',
          label: 'Flanş Çapı (D_f)',
          unit: 'mm',
          min: 40,
          max: 1000,
          hint: 'ISO 6020-2 standart serisi: 80, 100, 125, 160, 200...',
        ),
        FormFieldDescriptor(
          key: 'boltCircleDiameter',
          label: 'Delik Eksen Çapı (BCD)',
          unit: 'mm',
          min: 30,
          max: 900,
          hint: 'Cıvata merkezlerinin oluşturduğu daire çapı',
        ),
        FormFieldDescriptor(
          key: 'boltCount',
          label: 'Delik Sayısı',
          unit: 'adet',
          min: 3,
          max: 24,
          hint: 'Minimum 3, tipik: 4 veya 6',
          isInteger: true,
        ),
      ];

  @override
  bool validate() {
    if (flangeDiameter <= 0) {
      throw const MountingValidationException(
        'Flanş çapı sıfır veya negatif olamaz.',
        parameterName: 'flangeDiameter',
      );
    }

    if (boltCircleDiameter <= 0) {
      throw const MountingValidationException(
        'Delik eksen çapı (BCD) sıfır veya negatif olamaz.',
        parameterName: 'boltCircleDiameter',
      );
    }

    // Flanş çapı, delik eksen çapından büyük olmalı.
    // Aksi halde cıvata delikleri flanş dışına taşar.
    if (boltCircleDiameter >= flangeDiameter) {
      throw MountingValidationException(
        'Delik eksen çapı (BCD=$boltCircleDiameter mm) flanş çapından '
        '(D_f=$flangeDiameter mm) küçük olmalıdır.',
        parameterName: 'boltCircleDiameter',
      );
    }

    // Minimum 3 cıvata gerekli (2 cıvata statik dengesizlik yaratır).
    if (boltCount < 3) {
      throw MountingValidationException(
        'Delik sayısı en az 3 olmalıdır (mevcut: $boltCount). '
        'Statik denge için minimum 3 cıvata gereklidir.',
        parameterName: 'boltCount',
      );
    }

    // Cıvatalar arası minimum mesafe kontrolü
    // Cıvatalar arası ark uzunluğu: π × BCD / boltCount
    // Minimum cıvata aralığı ≈ 15 mm (M10 cıvata + anahtar boşluğu)
    final double boltSpacing = math.pi * boltCircleDiameter / boltCount;
    if (boltSpacing < 15.0) {
      throw MountingValidationException(
        'Cıvatalar arası mesafe çok küçük (${boltSpacing.toStringAsFixed(1)} mm). '
        'Minimum 15 mm aralık gereklidir. Delik sayısını azaltın veya BCD\'yi artırın.',
        parameterName: 'boltCount',
      );
    }

    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
        'category': category.name,
        'flangeDiameter': flangeDiameter,
        'boltCircleDiameter': boltCircleDiameter,
        'boltCount': boltCount,
      };
}
