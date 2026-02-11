import 'dart:math' as math;

import '../exceptions/hydraulic_exceptions.dart';
import 'internal_parts.dart';
import 'mounting_type.dart';

/// ============================================================================
/// HydraulicCylinder - Hidrolik Silindir Tasarım Sınıfı
/// ============================================================================
///
/// Bu sınıf, çift etkili (double-acting) bir hidrolik silindirin temel
/// mühendislik hesaplamalarını gerçekleştirir:
///
///   • İtme kuvveti (Push Force)  - Piston tarafı basınç uygulama
///   • Çekme kuvveti (Pull Force) - Rod tarafı basınç uygulama
///   • Et kalınlığı (Wall Thickness) - Lamé denklemi ile
///   • Burkulma analizi (Euler Buckling) - Rod stabilitesi kontrolü
///
/// Birim sistemi: SI (mm, MPa, N, mm⁴)
///   - Basınç: MPa (= N/mm²)
///   - Uzunluk / Çap: mm
///   - Kuvvet: Newton (N)
///   - Elastisite modülü: MPa
///
/// Referanslar:
///   - Lamé Equations: Boresi, Schmidt, Sidebottom - Advanced Mechanics of Materials
///   - Euler Buckling: Shigley's Mechanical Engineering Design
///   - ISO 6020/6022: Hydraulic Cylinder Standards
/// ============================================================================
class HydraulicCylinder {
  // ---------------------------------------------------------------------------
  // Sabitler (Constants)
  // ---------------------------------------------------------------------------

  /// Mekanik verim (η) - Sürtünme kayıplarını hesaba katar.
  /// Standart sızdırmazlık elemanları için %95 kabul edilir.
  /// ISO 6020-2'ye göre tipik değer aralığı: 0.90 – 0.97
  static const double mechanicalEfficiency = 0.95;

  /// Emniyet katsayısı (Safety Factor) - Lamé et kalınlığı hesabında kullanılır.
  /// Hidrolik silindirler için genel pratik: 2.0 – 4.0 arası.
  /// Dinamik yükleme ve darbe faktörü dahil 2.5 alınmıştır.
  static const double safetyFactor = 2.5;

  /// Çelik boru malzemesi elastisite modülü (E)
  /// St52 (S355JR) çelik: E ≈ 210,000 MPa = 210 GPa
  /// Rod malzemesi olarak da aynı değer kullanılır (krom kaplı CK45).
  static const double elasticModulus = 210000.0; // MPa

  /// Çelik boru malzemesi akma dayanımı (σ_y)
  /// St52 (S355JR) için minimum akma: 355 MPa
  /// Lamé formülünde izin verilen gerilme = σ_y / safetyFactor
  static const double yieldStrength = 355.0; // MPa

  /// Kapalı boy hesabında kullanılan emniyet payı [mm]
  static const double defaultExtraMargin = 7.5;

  // ---------------------------------------------------------------------------
  // Özellikler (Properties)
  // ---------------------------------------------------------------------------

  /// Çalışma basıncı (Working Pressure) [MPa]
  /// Tipik endüstriyel aralık: 16 – 32 MPa (160 – 320 bar)
  final double pressure;

  /// Boru iç çapı (Bore Diameter / Piston Diameter) [mm]
  /// Silindirin iç çapı; piston bu çapta hareket eder.
  /// ISO 3320 standart serileri: 25, 32, 40, 50, 63, 80, 100, 125...
  final double boreDiameter;

  /// Rod (piston kolu) çapı [mm]
  /// Genellikle boru çapının 0.5 – 0.7 katı seçilir.
  /// ISO 3320 standart serileri: 14, 18, 22, 28, 36, 45, 56, 70...
  final double rodDiameter;

  /// Strok (Stroke Length) [mm]
  /// Pistonun hareket mesafesi. Burkulma analizi için kritik parametre.
  final double stroke;

  /// Kapalı boy (Closed/Retracted Length) [mm]
  /// Silindir tamamen kapalıyken, pin merkezleri arası mesafe.
  /// Kural: closedLength > stroke olmalıdır (montaj mesafesi gerekir).
  final double closedLength;

  /// Piston iç bileşeni
  final CylinderPiston piston;

  /// Ön kep/gland iç bileşeni
  final CylinderHead head;

  /// Arka kapak iç bileşeni
  final CylinderBase base;

  /// Kapalı boy hesabındaki ek emniyet payı [mm]
  final double extraMargin;

  // ---------------------------------------------------------------------------
  // Constructor & Validation
  // ---------------------------------------------------------------------------

  /// Yeni bir HydraulicCylinder nesnesi oluşturur.
  ///
  /// Tüm parametreler fiziksel geçerlilik kontrolünden geçirilir.
  /// Geçersiz değerler için ilgili [HydraulicCylinderException] alt sınıfı fırlatılır.
  HydraulicCylinder({
    required this.pressure,
    required this.boreDiameter,
    required this.rodDiameter,
    required this.stroke,
    required this.closedLength,
    CylinderPiston? piston,
    CylinderHead? head,
    CylinderBase? base,
    this.extraMargin = defaultExtraMargin,
  })  : piston = piston ?? CylinderPiston(rodDiameter: rodDiameter),
        head = head ??
            CylinderHead(
              totalLength: math.max(rodDiameter * 1.2, 25),
              guideLength: rodDiameter,
              rodDiameter: rodDiameter,
            ),
        base = base ??
            CylinderBase(
              thickness: math.max(boreDiameter * 0.12, 12),
            ) {
    _validateInputs();
  }

  /// JSON verisinden HydraulicCylinder oluşturur.
  factory HydraulicCylinder.fromJson(Map<String, dynamic> json) {
    final rodDiameter = (json['rodDiameter'] as num).toDouble();
    final boreDiameter = (json['boreDiameter'] as num).toDouble();

    return HydraulicCylinder(
      pressure: (json['pressure'] as num).toDouble(),
      boreDiameter: boreDiameter,
      rodDiameter: rodDiameter,
      stroke: (json['stroke'] as num).toDouble(),
      closedLength: (json['closedLength'] as num).toDouble(),
      extraMargin:
          (json['extraMargin'] as num?)?.toDouble() ?? defaultExtraMargin,
      piston: json['piston'] is Map
          ? CylinderPiston.fromJson(
              Map<String, dynamic>.from(json['piston'] as Map),
              rodDiameter: rodDiameter,
            )
          : CylinderPiston(rodDiameter: rodDiameter),
      head: json['head'] is Map
          ? CylinderHead.fromJson(
              Map<String, dynamic>.from(json['head'] as Map),
              rodDiameter: rodDiameter,
            )
          : CylinderHead(
              totalLength: math.max(rodDiameter * 1.2, 25),
              guideLength: rodDiameter,
              rodDiameter: rodDiameter,
            ),
      base: json['base'] is Map
          ? CylinderBase.fromJson(Map<String, dynamic>.from(json['base'] as Map))
          : CylinderBase(thickness: math.max(boreDiameter * 0.12, 12)),
    );
  }

  /// Tüm giriş parametrelerinin mühendislik kurallarına uygunluğunu kontrol eder.
  void _validateInputs() {
    // --- Basınç Kontrolleri ---
    if (pressure <= 0) {
      throw const InvalidPressureException(
        'Çalışma basıncı sıfır veya negatif olamaz.',
        parameterName: 'pressure',
      );
    }

    // --- Çap Kontrolleri ---
    if (boreDiameter <= 0) {
      throw const InvalidDimensionException(
        'Boru iç çapı (D) sıfır veya negatif olamaz.',
        parameterName: 'boreDiameter',
      );
    }

    if (rodDiameter <= 0) {
      throw const InvalidDimensionException(
        'Rod çapı (d) sıfır veya negatif olamaz.',
        parameterName: 'rodDiameter',
      );
    }

    // Rod çapı, boru çapına eşit veya büyük olamaz.
    // Eşitlik durumunda halka alan sıfır olur → çekme kuvveti üretilemez.
    if (rodDiameter >= boreDiameter) {
      throw InvalidDimensionException(
        'Rod çapı (d=$rodDiameter mm) boru iç çapından (D=$boreDiameter mm) '
        'küçük olmalıdır. Mevcut durumda piston alanı oluşturulamaz.',
        parameterName: 'rodDiameter',
      );
    }

    // --- Strok & Boy Kontrolleri ---
    if (stroke <= 0) {
      throw const InvalidStrokeException(
        'Strok değeri sıfır veya negatif olamaz.',
        parameterName: 'stroke',
      );
    }

    if (closedLength <= 0) {
      throw const InvalidStrokeException(
        'Kapalı boy sıfır veya negatif olamaz.',
        parameterName: 'closedLength',
      );
    }

    // Kapalı boy, stroktan büyük olmalıdır.
    // Çünkü kapalı boyda: gövde boyu + bağlantı elemanları > strok
    if (closedLength <= stroke) {
      throw InvalidStrokeException(
        'Kapalı boy ($closedLength mm) stroktan ($stroke mm) büyük olmalıdır. '
        'Silindir yapısal olarak en az strok kadar gövde boyuna sahip olamaz.',
        parameterName: 'closedLength',
      );
    }

    if (extraMargin < 0) {
      throw const InvalidStrokeException(
        'Ek emniyet payı negatif olamaz.',
        parameterName: 'extraMargin',
      );
    }

    final minClosedLength = calculateMinClosedLength();
    if (closedLength < minClosedLength) {
      throw InvalidStrokeException(
        'Kapalı boy ($closedLength mm), minimum hesaplanan değerden '
        '(${minClosedLength.toStringAsFixed(1)} mm) küçük olamaz.',
        parameterName: 'closedLength',
      );
    }
  }
  // ---------------------------------------------------------------------------
  // Türetilmiş Geometrik Özellikler (Derived Geometric Properties)
  // ---------------------------------------------------------------------------

  /// Piston alanı (Bore Area / Full Piston Area) [mm²]
  ///
  ///   A_piston = π/4 × D²
  ///
  /// İtme kuvveti hesabında kullanılır (rod tarafı değil, kapak tarafı).
  double get pistonArea => math.pi / 4 * boreDiameter * boreDiameter;

  /// Halka alan (Annular Area / Rod-Side Area) [mm²]
  ///
  ///   A_annular = π/4 × (D² - d²)
  ///
  /// Çekme kuvveti hesabında kullanılır.
  /// Rod'un kapladığı alan çıkarılır çünkü basınç bu alana etki edemez.
  double get annularArea =>
      math.pi / 4 * (boreDiameter * boreDiameter - rodDiameter * rodDiameter);

  /// Rod kesit alanı [mm²]
  ///
  ///   A_rod = π/4 × d²
  double get rodArea => math.pi / 4 * rodDiameter * rodDiameter;

  /// Rod atalet momenti (Moment of Inertia) [mm⁴]
  ///
  ///   I = π/64 × d⁴
  ///
  /// Euler burkulma analizinde kullanılır.
  /// Dairesel kesit için minimum atalet momenti.
  double get rodMomentOfInertia =>
      math.pi / 64 * math.pow(rodDiameter, 4);

  /// Açık boy (Extended/Open Length) [mm]
  ///
  ///   L_open = L_closed + stroke
  double get openLength => closedLength + stroke;

  /// Boru çapı / Rod çapı oranı (Bore-to-Rod Ratio)
  ///
  /// Tipik değerler:
  ///   - Düşük basınç (≤ 10 MPa): D/d ≈ 1.25 – 1.4
  ///   - Orta basınç (10-25 MPa): D/d ≈ 1.4 – 2.0
  ///   - Yüksek basınç (> 25 MPa): D/d ≈ 2.0 – 2.5
  double get boreToRodRatio => boreDiameter / rodDiameter;

  // ---------------------------------------------------------------------------
  // Kuvvet Hesaplamaları (Force Calculations)
  // ---------------------------------------------------------------------------

  /// İtme Kuvveti (Push Force / Extension Force) [N]
  ///
  /// Silindirin ileri hareketinde (rod'un dışarı çıkması) üretilen kuvvet.
  /// Basınç, pistonun tam alanına etki eder.
  ///
  /// Formül:
  ///   F_push = P × A_piston × η
  ///   F_push = P × (π/4 × D²) × η
  ///
  /// Burada:
  ///   P = Çalışma basıncı [MPa = N/mm²]
  ///   D = Boru iç çapı [mm]
  ///   η = Mekanik verim (0.95)
  ///
  /// Verim düşüşü kaynakları:
  ///   - Piston sızdırmazlık sürtünmesi (~2%)
  ///   - Rod keçe sürtünmesi (~1.5%)
  ///   - Yağ sıkışabilirliği (~1.5%)
  double calculatePushForce() {
    return pressure * pistonArea * mechanicalEfficiency;
  }

  /// Çekme Kuvveti (Pull Force / Retraction Force) [N]
  ///
  /// Silindirin geri hareketinde (rod'un içeri girmesi) üretilen kuvvet.
  /// Basınç, halka alana (piston alanı - rod alanı) etki eder.
  ///
  /// Formül:
  ///   F_pull = P × A_annular × η
  ///   F_pull = P × π/4 × (D² - d²) × η
  ///
  /// Not: Çekme kuvveti her zaman itme kuvvetinden küçüktür (d > 0 olduğu için).
  /// Kuvvet oranı: F_pull / F_push = (D² - d²) / D² = 1 - (d/D)²
  double calculatePullForce() {
    return pressure * annularArea * mechanicalEfficiency;
  }

  // ---------------------------------------------------------------------------
  // Et Kalınlığı Hesabı - Lamé Denklemi (Wall Thickness - Lamé Equation)
  // ---------------------------------------------------------------------------

  /// Gereken Minimum Et Kalınlığı [mm]
  ///
  /// Kalın cidarlı silindir teorisi (Lamé Equations) kullanılır.
  /// Silindir duvarındaki çevresel (hoop) gerilme dağılımı radyal olarak
  /// değişkendir ve iç yüzeyde maksimumdur.
  ///
  /// Lamé formülü (iç basınç altında, dış basınç = 0):
  ///
  ///   σ_hoop_max = P × (R_o² + R_i²) / (R_o² - R_i²)
  ///
  /// İzin verilen gerilme:
  ///   σ_izin = σ_akma / SF
  ///
  /// Minimum dış yarıçap (R_o) çözümü:
  ///
  ///   R_o = R_i × √((σ_izin + P) / (σ_izin - P))
  ///
  /// Minimum et kalınlığı:
  ///   t_min = R_o - R_i
  ///
  /// Kısıt: σ_izin > P olmalıdır, aksi halde kalın cidarlı tasarım
  /// tek başına yeterli değildir (çok katlı / otofrette gerekir).
  ///
  /// Döndürülen değer emniyet katsayısı (SF = 2.5) dahil minimum et
  /// kalınlığıdır. Üretim toleransları için ek pay eklenmelidir.
  double calculateWallThickness() {
    final double allowableStress = yieldStrength / safetyFactor;

    // σ_izin > P kontrolü
    // Eğer çalışma basıncı izin verilen gerilmeyi aşıyorsa,
    // tek cidarlı silindir ile tasarım mümkün değildir.
    if (allowableStress <= pressure) {
      throw InvalidPressureException(
        'Çalışma basıncı ($pressure MPa) izin verilen gerilmeyi '
        '(${allowableStress.toStringAsFixed(1)} MPa) aşıyor. '
        'Emniyet katsayısı $safetyFactor ile tek cidarlı tasarım mümkün değil.',
        parameterName: 'pressure',
      );
    }

    // İç yarıçap
    final double innerRadius = boreDiameter / 2.0;

    // Lamé formülü ile minimum dış yarıçap
    //   R_o = R_i × √((σ_izin + P) / (σ_izin - P))
    final double outerRadius =
        innerRadius * math.sqrt((allowableStress + pressure) / (allowableStress - pressure));

    // Minimum et kalınlığı
    final double wallThickness = outerRadius - innerRadius;

    return wallThickness;
  }

  // ---------------------------------------------------------------------------
  // Burkulma Analizi - Euler Sütun Teorisi (Euler Column Buckling)
  // ---------------------------------------------------------------------------

  /// Euler Burkulma Analizi
  ///
  /// Hidrolik silindirlerde rod, eksenel basınç yükü altında çalışır.
  /// Uzun ve ince rodlarda burkulma (座屈/buckling) riski vardır.
  ///
  /// Euler Kritik Burkulma Yükü:
  ///
  ///   P_cr = n × π² × E × I / L²
  ///
  /// Burada:
  ///   n   = End-fixity coefficient (bağlantı tipine bağlı)
  ///   E   = Elastisite modülü [MPa]
  ///   I   = Rod atalet momenti [mm⁴]  →  π/64 × d⁴
  ///   L   = Burkulma boyu [mm] (tam açık boy alınır - en kritik durum)
  ///
  /// Alternatif formül (etkili boy ile):
  ///   P_cr = π² × E × I / L_eff²
  ///   L_eff = K × L  (K = etkili boy çarpanı)
  ///
  /// Güvenlik kontrolü:
  ///   F_push < P_cr / SF  →  Güvenli
  ///
  /// [mountingType]: Silindir bağlantı tipi (MountingType enum)
  ///
  /// Döndürülen [BucklingResult]:
  ///   - criticalLoad: Euler kritik burkulma yükü [N]
  ///   - appliedLoad: Uygulanan itme kuvveti [N]
  ///   - bucklingFactor: Emniyet oranı (P_cr / F_push)
  ///   - isSafe: bucklingFactor >= safetyFactor ise true
  BucklingResult checkBuckling(MountingType mountingType) {
    // Burkulma boyu olarak tam açık boy alınır.
    // Bu en kritik durumdur çünkü rod maksimum uzunlukta dışarıdadır.
    final double bucklingLength = openLength;

    // Euler kritik burkulma yükü
    //   P_cr = n × π² × E × I / L²
    final double criticalLoad = mountingType.endFixityCoefficient *
        math.pi *
        math.pi *
        elasticModulus *
        rodMomentOfInertia /
        (bucklingLength * bucklingLength);

    // Uygulanan yük = maksimum itme kuvveti
    final double appliedLoad = calculatePushForce();

    // Emniyet oranı (Buckling Safety Factor)
    // appliedLoad sıfır olamaz çünkü pressure > 0 ve boreDiameter > 0 (validation'da kontrol edildi)
    final double bucklingFactor = criticalLoad / appliedLoad;

    // Güvenlik değerlendirmesi
    // Emniyet katsayısının üzerindeyse güvenli kabul edilir.
    final bool isSafe = bucklingFactor >= safetyFactor;

    return BucklingResult(
      criticalLoad: criticalLoad,
      appliedLoad: appliedLoad,
      bucklingFactor: bucklingFactor,
      isSafe: isSafe,
      mountingType: mountingType,
      effectiveLength: mountingType.effectiveLengthFactor * bucklingLength,
    );
  }



  /// Toplam metal ağırlık hesabı [kg]
  ///
  /// Varsayımlar:
  /// - Malzeme: Çelik (ρ = 7.85 g/cm³ = 7850 kg/m³)
  /// - Parçalar: Boru gövdesi + rod + piston + head + base
  /// - Basitleştirilmiş geometri (silindirik/halka hacimler)
  double calculateTotalWeight() {
    const steelDensityKgPerM3 = 7850.0;

    // --- Geometrik yardımcı dönüşümler ---
    double mm3ToM3(double mm3) => mm3 * 1e-9;

    // Gövde et kalınlığı hesaplı (minimum) + üretim payı
    final wall = calculateWallThickness() + 1.0;
    final outerBoreDiameter = boreDiameter + 2 * wall;

    // Görsel/model varsayımı: boru boyu ~ closedLength - head - base
    final tubeLength = math.max(closedLength - head.totalLength - base.thickness, stroke);

    // 1) Boru hacmi (halka silindir)
    final tubeVolumeMm3 =
        math.pi / 4 * (outerBoreDiameter * outerBoreDiameter - boreDiameter * boreDiameter) * tubeLength;

    // 2) Rod hacmi (tam silindir)
    final rodLength = stroke + head.totalLength;
    final rodVolumeMm3 = math.pi / 4 * rodDiameter * rodDiameter * rodLength;

    // 3) Piston hacmi (dış silindir - rod deliği)
    final pistonVolumeMm3 =
        math.pi / 4 * (boreDiameter * boreDiameter - rodDiameter * rodDiameter) * piston.width;

    // 4) Head hacmi (dış silindir - rod geçiş deliği)
    final headOuterDiameter = outerBoreDiameter;
    final headVolumeMm3 =
        math.pi / 4 * (headOuterDiameter * headOuterDiameter - rodDiameter * rodDiameter) * head.totalLength;

    // 5) Base hacmi (kapak diski + rod tarafı kör, yani tam daire yaklaşımı)
    final baseOuterDiameter = outerBoreDiameter;
    final baseVolumeMm3 = math.pi / 4 * baseOuterDiameter * baseOuterDiameter * base.thickness;

    final totalVolumeM3 =
        mm3ToM3(tubeVolumeMm3 + rodVolumeMm3 + pistonVolumeMm3 + headVolumeMm3 + baseVolumeMm3);

    return totalVolumeM3 * steelDensityKgPerM3;
  }

  /// Minimum kapalı boy hesabı [mm]
  ///
  /// Formül:
  ///   L_closed,min = piston.width + head.totalLength + base.thickness + stroke + extraMargin
  double calculateMinClosedLength() {
    return piston.width + head.totalLength + base.thickness + stroke + extraMargin;
  }

  /// Silindir modelini JSON'a dönüştürür.
  Map<String, dynamic> toJson() => {
        'pressure': pressure,
        'boreDiameter': boreDiameter,
        'rodDiameter': rodDiameter,
        'stroke': stroke,
        'closedLength': closedLength,
        'extraMargin': extraMargin,
        'piston': piston.toJson(),
        'head': head.toJson(),
        'base': base.toJson(),
      };

  // ---------------------------------------------------------------------------
  // Özet Rapor (Summary)
  // ---------------------------------------------------------------------------

  @override
  String toString() {
    return 'HydraulicCylinder('
        'P: $pressure MPa, '
        'D: $boreDiameter mm, '
        'd: $rodDiameter mm, '
        'Strok: $stroke mm, '
        'Kapalı Boy: $closedLength mm, '
        'Min Kapalı Boy: ${calculateMinClosedLength().toStringAsFixed(1)} mm)';
  }
}

/// ============================================================================
/// BucklingResult - Burkulma Analizi Sonuç Sınıfı
/// ============================================================================
///
/// Euler burkulma analizinin sonuçlarını kapsüller.
class BucklingResult {
  /// Euler kritik burkulma yükü [N]
  final double criticalLoad;

  /// Uygulanan itme kuvveti [N]
  final double appliedLoad;

  /// Burkulma emniyet oranı (P_cr / F_push)
  /// Değer ne kadar büyükse, tasarım o kadar güvenlidir.
  ///   - < 1.0 : Burkulma OLACAK (kritik!)
  ///   - 1.0 – 2.5 : Risk bölgesi
  ///   - ≥ 2.5 : Güvenli bölge
  final double bucklingFactor;

  /// Güvenlik durumu
  /// true: bucklingFactor >= safetyFactor (2.5)
  final bool isSafe;

  /// Kullanılan bağlantı tipi
  final MountingType mountingType;

  /// Etkili burkulma boyu [mm]
  /// L_eff = K × L_open
  final double effectiveLength;

  const BucklingResult({
    required this.criticalLoad,
    required this.appliedLoad,
    required this.bucklingFactor,
    required this.isSafe,
    required this.mountingType,
    required this.effectiveLength,
  });

  @override
  String toString() {
    return 'BucklingResult(\n'
        '  Bağlantı Tipi: ${mountingType.description}\n'
        '  Etkili Boy: ${effectiveLength.toStringAsFixed(1)} mm\n'
        '  Kritik Yük: ${criticalLoad.toStringAsFixed(0)} N\n'
        '  Uygulanan Yük: ${appliedLoad.toStringAsFixed(0)} N\n'
        '  Emniyet Oranı: ${bucklingFactor.toStringAsFixed(2)}\n'
        '  Güvenli: ${isSafe ? "EVET ✓" : "HAYIR ✗"}\n'
        ')';
  }
}
