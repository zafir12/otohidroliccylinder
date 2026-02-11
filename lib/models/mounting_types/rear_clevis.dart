import '../../exceptions/hydraulic_exceptions.dart';
import '../mounting_type.dart';

/// ============================================================================
/// RearClevis - Arka Çatal (Klevis) Bağlantı Tipi
/// ============================================================================
///
/// Silindir gövdesinin arka ucuna (cap-end) kaynak veya vidalı bağlanan
/// çatal (U-şekilli) tip montaj. Pim ile yüke bağlanır → Mafsal (Pin).
///
/// Tipik kullanım: Mobil hidrolik (iş makineleri, tarım ekipmanları),
///                 açısal hareket gerektiren uygulamalar.
///
///   Yük bağlantı noktası
///        │
///        ▼
///   ┌────┬────┐
///   │    │    │  ← Çatal kolları (genişlik = w)
///   │   (●)   │  ← Pim deliği (d_pin)
///   │    │    │
///   └────┴────┘
///        │
///   ─────┴───── Silindir Gövdesi
///
///   ← Eksen uzaklığı (a) →
///   Pim merkezi ile silindir ekseni arası mesafe
///
/// Euler Katsayısı:
///   Çatal bağlantı = Mafsal (Pin). Rod ucu da genellikle mafsal.
///   → Pin-Pin konfigürasyonu: n = 1.0, K = 1.0
///
/// Parametreler:
///   - pinDiameter (d_pin): Bağlantı pim çapı [mm]
///   - clevisWidth (w): Çatal iç genişliği [mm]
///   - axisDistance (a): Pim ekseninden silindir eksenine uzaklık [mm]
///
/// Tasarım kuralları:
///   - d_pin > 0
///   - w > 0, çatal genişliği bağlanan parçayı alabilecek kadar olmalı
///   - a > 0
///   - Pim kesme gerilmesi kontrolü: τ = F / (2 × π/4 × d_pin²) ≤ τ_izin
/// ============================================================================
class RearClevis extends MountingType {
  /// Bağlantı pim çapı [mm]
  /// Pim malzemesi genellikle CK45 veya 42CrMo4 (ısıl işlemli).
  /// ISO 8132'ye göre standart pim çapları: 16, 20, 25, 30, 40, 50, 63...
  final double pinDiameter;

  /// Çatal iç genişliği [mm]
  /// İki çatal kolu arasındaki boşluk.
  /// Bağlanan eleman (göz/kulak) bu genişliğin içine oturmalıdır.
  final double clevisWidth;

  /// Pim ekseni – silindir ekseni arası mesafe [mm]
  /// Moment kolu hesaplarında kullanılır.
  /// Kısa mesafe tercih edilir (eğilme momenti azalır).
  final double axisDistance;

  const RearClevis({
    required this.pinDiameter,
    required this.clevisWidth,
    required this.axisDistance,
  });

  /// Boş (varsayılan) RearClevis. Factory method tarafından kullanılır.
  factory RearClevis.empty() => const RearClevis(
        pinDiameter: 0,
        clevisWidth: 0,
        axisDistance: 0,
      );

  /// JSON'dan RearClevis oluşturur.
  factory RearClevis.fromJson(Map<String, dynamic> json) => RearClevis(
        pinDiameter: (json['pinDiameter'] as num).toDouble(),
        clevisWidth: (json['clevisWidth'] as num).toDouble(),
        axisDistance: (json['axisDistance'] as num).toDouble(),
      );

  // --- Euler Katsayıları ---
  // Çatal = Mafsal (Pin), Rod ucu = Mafsal (Pin)
  // → Pin-Pin: n = 1.0

  @override
  MountingCategory get category => MountingCategory.rearClevis;

  @override
  String get description => 'Arka Çatal (Rear Clevis) – Mafsal bağlantı';

  @override
  double get endFixityCoefficient => 1.0;

  @override
  double get effectiveLengthFactor => 1.0;

  @override
  List<FormFieldDescriptor> get formFields => const [
        FormFieldDescriptor(
          key: 'pinDiameter',
          label: 'Pim Çapı (d_pin)',
          unit: 'mm',
          min: 8,
          max: 200,
          hint: 'ISO 8132 standart serisi: 16, 20, 25, 30, 40, 50...',
        ),
        FormFieldDescriptor(
          key: 'clevisWidth',
          label: 'Çatal Genişliği (w)',
          unit: 'mm',
          min: 10,
          max: 300,
          hint: 'İki çatal kolu arasındaki iç genişlik',
        ),
        FormFieldDescriptor(
          key: 'axisDistance',
          label: 'Eksen Uzaklığı (a)',
          unit: 'mm',
          min: 5,
          max: 500,
          hint: 'Pim merkezi – silindir ekseni arası mesafe',
        ),
      ];

  @override
  bool validate() {
    if (pinDiameter <= 0) {
      throw const MountingValidationException(
        'Pim çapı sıfır veya negatif olamaz.',
        parameterName: 'pinDiameter',
      );
    }

    if (clevisWidth <= 0) {
      throw const MountingValidationException(
        'Çatal genişliği sıfır veya negatif olamaz.',
        parameterName: 'clevisWidth',
      );
    }

    if (axisDistance <= 0) {
      throw const MountingValidationException(
        'Eksen uzaklığı sıfır veya negatif olamaz.',
        parameterName: 'axisDistance',
      );
    }

    // Çatal genişliği, pim çapından büyük olmalı.
    // Aksi halde pim çatalın içinden geçemez.
    if (clevisWidth <= pinDiameter) {
      throw MountingValidationException(
        'Çatal genişliği (w=$clevisWidth mm) pim çapından '
        '(d_pin=$pinDiameter mm) büyük olmalıdır.',
        parameterName: 'clevisWidth',
      );
    }

    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
        'category': category.name,
        'pinDiameter': pinDiameter,
        'clevisWidth': clevisWidth,
        'axisDistance': axisDistance,
      };
}
