/// Hidrolik Silindir Bağlantı Tipleri ve Euler Burkulma Katsayıları
///
/// Euler burkulma teorisinde, sütun/çubuk uç koşulları etkili burkulma
/// boyunu belirler. Etkili boy: L_eff = L / sqrt(n)
/// Burada n, "end-fixity coefficient" olarak bilinir.
///
/// Referans: Shigley's Mechanical Engineering Design, Euler Column Theory

/// Silindir bağlantı tiplerini ve karşılık gelen Euler
/// burkulma katsayılarını tanımlayan enum.
enum MountingType {
  /// Her iki uç mafsal (pin-pin / pivoted-pivoted)
  /// Etkili boy katsayısı K = 1.0  →  n = 1.0
  /// En yaygın endüstriyel montaj tipi.
  pinPin(
    description: 'Mafsal - Mafsal (Pin-Pin)',
    endFixityCoefficient: 1.0,
    effectiveLengthFactor: 1.0,
  ),

  /// Bir uç ankastre (kaynak/flanş), diğer uç mafsal
  /// Etkili boy katsayısı K = 0.707  →  n = 2.0
  fixedPin(
    description: 'Ankastre - Mafsal (Fixed-Pin)',
    endFixityCoefficient: 2.0,
    effectiveLengthFactor: 0.707,
  ),

  /// Her iki uç ankastre (fixed-fixed)
  /// Etkili boy katsayısı K = 0.5  →  n = 4.0
  /// En rijit bağlantı; pratikte tam ankastre zor sağlanır.
  fixedFixed(
    description: 'Ankastre - Ankastre (Fixed-Fixed)',
    endFixityCoefficient: 4.0,
    effectiveLengthFactor: 0.5,
  ),

  /// Bir uç ankastre, diğer uç tamamen serbest (cantilever)
  /// Etkili boy katsayısı K = 2.0  →  n = 0.25
  /// En kritik durum; burkulma yükü en düşüktür.
  fixedFree(
    description: 'Ankastre - Serbest (Fixed-Free)',
    endFixityCoefficient: 0.25,
    effectiveLengthFactor: 2.0,
  );

  const MountingType({
    required this.description,
    required this.endFixityCoefficient,
    required this.effectiveLengthFactor,
  });

  /// Türkçe açıklama
  final String description;

  /// Euler "end-fixity coefficient" (n)
  /// P_cr = n * π² * E * I / L²
  final double endFixityCoefficient;

  /// Etkili boy çarpanı (K)
  /// L_eff = K * L
  /// Not: n = 1 / K²
  final double effectiveLengthFactor;
}
