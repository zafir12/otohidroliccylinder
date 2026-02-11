import '../../exceptions/hydraulic_exceptions.dart';
import '../mounting_type.dart';

/// ============================================================================
/// Trunnion - Orta Eklem (Trunnion) Bağlantı Tipi
/// ============================================================================
///
/// Silindir gövdesinin yan tarafına kaynaklanan iki adet çıkıntı (trunnion)
/// ile yatak yuvalarına oturarak bağlantı sağlayan montaj tipi.
/// Silindir, trunnion ekseni etrafında serbest dönebilir → Mafsal (Pin).
///
/// Tipik kullanım: Damper silindirleri, vinç bomları, gemi dümen sistemleri,
///                 açısal hareket gerektiren ağır yüklü uygulamalar.
///
///                    Kafadan mesafe (XV)
///                  ├──────────────┤
///        ┌─────────┬──────────────┬───────────┐
///   ─────┤ KAPAK   │   SİLİNDİR  │  ROD →    ├────
///        └─────────┴──────┬───────┴───────────┘
///                         │
///                    ┌────┴────┐
///                    │TRUNNION │  ← Pim Çapı (d_t)
///                    │  (●)   │
///                    └────────┘
///                         │
///                    Yatak Yuvası
///
/// Euler Katsayısı:
///   Trunnion = Mafsal (Pin), Rod ucu = Mafsal (Pin)
///   → Pin-Pin konfigürasyonu: n = 1.0, K = 1.0
///
///   Not: Trunnion pozisyonu (kafadan mesafe) burkulma boyunu etkiler.
///   XV değeri küçüldükçe efektif burkulma boyu artar (daha kritik).
///
/// Parametreler:
///   - headDistance (XV): Trunnion ekseninin silindir ön kapağından mesafesi [mm]
///   - trunnionDiameter (d_t): Trunnion pim çapı [mm]
///
/// Tasarım kuralları:
///   - XV > 0 (kapaktan en az birkaç mm içeride olmalı)
///   - d_t > 0
///   - Trunnion yatak basıncı: P_yatak = F / (d_t × L_yatak) ≤ P_izin
/// ============================================================================
class Trunnion extends MountingType {
  /// Kafadan mesafe (XV Distance) [mm]
  /// Trunnion pim ekseninin, silindir ön kapak yüzeyinden ölçülen mesafesi.
  ///
  /// Seçim kriterleri:
  ///   - XV ≈ Strok / 3 → Dengeli yük dağılımı (ideal)
  ///   - XV çok küçük → Gövde ön tarafında yüksek eğilme momenti
  ///   - XV çok büyük → Gövde arka tarafı dengesiz
  final double headDistance;

  /// Trunnion pim çapı [mm]
  /// Yatak yuvası bu çapa göre işlenir.
  /// Yüzey sertliği: 55-60 HRC (aşınma dayanımı için)
  final double trunnionDiameter;

  const Trunnion({
    required this.headDistance,
    required this.trunnionDiameter,
  });

  /// Boş (varsayılan) Trunnion. Factory method tarafından kullanılır.
  factory Trunnion.empty() => const Trunnion(
        headDistance: 0,
        trunnionDiameter: 0,
      );

  /// JSON'dan Trunnion oluşturur.
  factory Trunnion.fromJson(Map<String, dynamic> json) => Trunnion(
        headDistance: (json['headDistance'] as num).toDouble(),
        trunnionDiameter: (json['trunnionDiameter'] as num).toDouble(),
      );

  // --- Euler Katsayıları ---
  // Trunnion = Mafsal (Pin), Rod ucu = Mafsal (Pin)
  // → Pin-Pin: n = 1.0

  @override
  MountingCategory get category => MountingCategory.trunnion;

  @override
  String get description => 'Orta Eklem (Trunnion) – Mafsal bağlantı';

  @override
  double get endFixityCoefficient => 1.0;

  @override
  double get effectiveLengthFactor => 1.0;

  @override
  List<FormFieldDescriptor> get formFields => const [
        FormFieldDescriptor(
          key: 'headDistance',
          label: 'Kafadan Mesafe (XV)',
          unit: 'mm',
          min: 10,
          max: 5000,
          hint: 'Trunnion ekseni – ön kapak arası mesafe. İdeal: Strok / 3',
        ),
        FormFieldDescriptor(
          key: 'trunnionDiameter',
          label: 'Pim Çapı (d_t)',
          unit: 'mm',
          min: 15,
          max: 300,
          hint: 'Trunnion yatak çapı',
        ),
      ];

  @override
  bool validate() {
    if (headDistance <= 0) {
      throw const MountingValidationException(
        'Kafadan mesafe (XV) sıfır veya negatif olamaz.',
        parameterName: 'headDistance',
      );
    }

    if (trunnionDiameter <= 0) {
      throw const MountingValidationException(
        'Trunnion pim çapı sıfır veya negatif olamaz.',
        parameterName: 'trunnionDiameter',
      );
    }

    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
        'category': category.name,
        'headDistance': headDistance,
        'trunnionDiameter': trunnionDiameter,
      };
}
