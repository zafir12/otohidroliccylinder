import 'dart:math' as math;

import '../lib/exceptions/hydraulic_exceptions.dart';
import '../lib/models/hydraulic_cylinder.dart';
import '../lib/models/mounting_type.dart';
import '../lib/models/mounting_types/front_flange.dart';
import '../lib/models/mounting_types/rear_clevis.dart';
import '../lib/models/mounting_types/spherical_bearing.dart';
import '../lib/models/mounting_types/trunnion.dart';

/// ============================================================================
/// Hidrolik Silindir - Birim Testleri
/// ============================================================================
///
/// Manuel test dosyası. `dart test` veya `flutter test` ile çalıştırılabilir
/// (pubspec.yaml'da test paketi eklendikten sonra).
/// Şimdilik `dart run test/hydraulic_cylinder_test.dart` ile çalıştırılabilir.

void main() {
  print('=== Hidrolik Silindir Birim Testleri ===\n');

  int passed = 0;
  int failed = 0;

  void expect(bool condition, String testName) {
    if (condition) {
      print('  ✓ PASSED: $testName');
      passed++;
    } else {
      print('  ✗ FAILED: $testName');
      failed++;
    }
  }

  void expectThrows<T>(void Function() fn, String testName) {
    try {
      fn();
      print('  ✗ FAILED: $testName (exception beklendi ama fırlatılmadı)');
      failed++;
    } on T {
      print('  ✓ PASSED: $testName');
      passed++;
    } catch (e) {
      print('  ✗ FAILED: $testName (beklenen: $T, gelen: ${e.runtimeType})');
      failed++;
    }
  }

  // --- Referans silindir ---
  // Tipik bir endüstriyel silindir: Ø80/Ø45, 20 MPa, 500 mm strok
  final cylinder = HydraulicCylinder(
    pressure: 20.0, // 200 bar
    boreDiameter: 80.0, // mm
    rodDiameter: 45.0, // mm
    stroke: 500.0, // mm
    closedLength: 700.0, // mm
  );

  // =========================================================================
  // 1. Geometrik Özellikler
  // =========================================================================
  print('\n--- Geometrik Özellikler ---');

  final expectedPistonArea = math.pi / 4 * 80.0 * 80.0; // ≈ 5026.55 mm²
  expect(
    (cylinder.pistonArea - expectedPistonArea).abs() < 0.01,
    'Piston alanı doğru hesaplanmalı (≈ ${expectedPistonArea.toStringAsFixed(2)} mm²)',
  );

  final expectedAnnularArea =
      math.pi / 4 * (80.0 * 80.0 - 45.0 * 45.0); // ≈ 3436.12 mm²
  expect(
    (cylinder.annularArea - expectedAnnularArea).abs() < 0.01,
    'Halka alan doğru hesaplanmalı (≈ ${expectedAnnularArea.toStringAsFixed(2)} mm²)',
  );

  expect(
    cylinder.openLength == 1200.0,
    'Açık boy = kapalı boy + strok = 1200 mm',
  );

  expect(
    (cylinder.boreToRodRatio - 80.0 / 45.0).abs() < 0.001,
    'Bore/Rod oranı doğru hesaplanmalı (≈ ${(80.0 / 45.0).toStringAsFixed(3)})',
  );

  // =========================================================================
  // 2. Kuvvet Hesaplamaları
  // =========================================================================
  print('\n--- Kuvvet Hesaplamaları ---');

  final expectedPushForce = 20.0 * expectedPistonArea * 0.95;
  expect(
    (cylinder.calculatePushForce() - expectedPushForce).abs() < 0.1,
    'İtme kuvveti doğru (≈ ${expectedPushForce.toStringAsFixed(1)} N)',
  );

  final expectedPullForce = 20.0 * expectedAnnularArea * 0.95;
  expect(
    (cylinder.calculatePullForce() - expectedPullForce).abs() < 0.1,
    'Çekme kuvveti doğru (≈ ${expectedPullForce.toStringAsFixed(1)} N)',
  );

  expect(
    cylinder.calculatePullForce() < cylinder.calculatePushForce(),
    'Çekme kuvveti her zaman itme kuvvetinden küçük olmalı',
  );

  // =========================================================================
  // 3. Et Kalınlığı (Lamé)
  // =========================================================================
  print('\n--- Et Kalınlığı (Lamé) ---');

  final wallThickness = cylinder.calculateWallThickness();
  expect(
    wallThickness > 0,
    'Et kalınlığı pozitif olmalı (${wallThickness.toStringAsFixed(2)} mm)',
  );

  final allowableStress = 355.0 / 2.5;
  final expectedRo =
      40.0 * math.sqrt((allowableStress + 20.0) / (allowableStress - 20.0));
  final expectedThickness = expectedRo - 40.0;
  expect(
    (wallThickness - expectedThickness).abs() < 0.01,
    'Et kalınlığı Lamé formülüne uygun (≈ ${expectedThickness.toStringAsFixed(2)} mm)',
  );

  // =========================================================================
  // 4. Burkulma Analizi - Polimorfik MountingType ile
  // =========================================================================
  print('\n--- Burkulma Analizi (Polimorfik MountingType) ---');

  // FrontFlange (n = 2.0) → Ankastre-Mafsal
  final flange = FrontFlange(
    flangeDiameter: 160.0,
    boltCircleDiameter: 130.0,
    boltCount: 6,
  );
  final bucklingFlange = cylinder.checkBuckling(flange);
  expect(
    bucklingFlange.criticalLoad > 0,
    'FrontFlange: Kritik burkulma yükü pozitif',
  );

  // RearClevis (n = 1.0) → Pin-Pin
  final clevis = RearClevis(
    pinDiameter: 30.0,
    clevisWidth: 50.0,
    axisDistance: 60.0,
  );
  final bucklingClevis = cylinder.checkBuckling(clevis);

  // Trunnion (n = 1.0) → Pin-Pin
  final trunnion = Trunnion(
    headDistance: 200.0,
    trunnionDiameter: 50.0,
  );
  final bucklingTrunnion = cylinder.checkBuckling(trunnion);

  // SphericalBearing (n = 0.25) → Fixed-Free (en kritik)
  final spherical = SphericalBearing(
    sphereDiameter: 35.0,
    boreDiameter: 20.0,
  );
  final bucklingSpherical = cylinder.checkBuckling(spherical);

  // Kritik yük sıralaması: spherical < clevis = trunnion < flange
  expect(
    bucklingSpherical.criticalLoad < bucklingClevis.criticalLoad,
    'SphericalBearing (n=0.25) kritik yük < RearClevis (n=1.0)',
  );
  expect(
    (bucklingClevis.criticalLoad - bucklingTrunnion.criticalLoad).abs() < 0.01,
    'RearClevis (n=1.0) ≈ Trunnion (n=1.0) kritik yük',
  );
  expect(
    bucklingClevis.criticalLoad < bucklingFlange.criticalLoad,
    'RearClevis (n=1.0) kritik yük < FrontFlange (n=2.0)',
  );

  // Manuel doğrulama: FrontFlange (n = 2.0)
  final expectedI = math.pi / 64 * math.pow(45.0, 4);
  final expectedPcrFlange =
      2.0 * math.pi * math.pi * 210000.0 * expectedI / (1200.0 * 1200.0);
  expect(
    (bucklingFlange.criticalLoad - expectedPcrFlange).abs() / expectedPcrFlange < 0.001,
    'FrontFlange kritik yük doğru (≈ ${expectedPcrFlange.toStringAsFixed(0)} N)',
  );

  // =========================================================================
  // 5. Polimorfizm - Factory Pattern
  // =========================================================================
  print('\n--- Factory Pattern & Polimorfizm ---');

  // MountingType.fromCategory ile her tip oluşturulabilmeli
  for (final category in MountingCategory.values) {
    final mounting = MountingType.fromCategory(category);
    expect(
      mounting.category == category,
      'fromCategory(${category.name}) doğru tip döndürmeli',
    );
    expect(
      mounting.formFields.isNotEmpty,
      '${category.name}: formFields boş olmamalı',
    );
    expect(
      mounting.endFixityCoefficient > 0,
      '${category.name}: Euler katsayısı > 0',
    );
  }

  // Her tipin farklı form alanları olmalı
  final flangeFields = MountingType.fromCategory(MountingCategory.frontFlange).formFields;
  final clevisFields = MountingType.fromCategory(MountingCategory.rearClevis).formFields;
  final trunnionFields = MountingType.fromCategory(MountingCategory.trunnion).formFields;
  final sphericalFields = MountingType.fromCategory(MountingCategory.sphericalBearing).formFields;

  expect(flangeFields.length == 3, 'FrontFlange: 3 form alanı (çap, BCD, delik sayısı)');
  expect(clevisFields.length == 3, 'RearClevis: 3 form alanı (pim, genişlik, eksen)');
  expect(trunnionFields.length == 2, 'Trunnion: 2 form alanı (XV, pim çapı)');
  expect(sphericalFields.length == 2, 'SphericalBearing: 2 form alanı (küre, delik)');

  // Form field key'leri benzersiz olmalı
  final flangeKeys = flangeFields.map((f) => f.key).toSet();
  expect(flangeKeys.length == flangeFields.length, 'FrontFlange: tüm key\'ler benzersiz');

  // =========================================================================
  // 6. Serialization (toJson / fromJson)
  // =========================================================================
  print('\n--- Serialization (toJson / fromJson) ---');

  // FrontFlange round-trip
  final flangeJson = flange.toJson();
  expect(flangeJson['category'] == 'frontFlange', 'FrontFlange toJson: category doğru');
  expect(flangeJson['flangeDiameter'] == 160.0, 'FrontFlange toJson: flangeDiameter doğru');
  expect(flangeJson['boltCount'] == 6, 'FrontFlange toJson: boltCount doğru');

  final flangeRestored = MountingType.fromJson(flangeJson) as FrontFlange;
  expect(flangeRestored.flangeDiameter == 160.0, 'FrontFlange fromJson: flangeDiameter korundu');
  expect(flangeRestored.boltCount == 6, 'FrontFlange fromJson: boltCount korundu');

  // RearClevis round-trip
  final clevisJson = clevis.toJson();
  final clevisRestored = MountingType.fromJson(clevisJson) as RearClevis;
  expect(clevisRestored.pinDiameter == 30.0, 'RearClevis fromJson: pinDiameter korundu');
  expect(clevisRestored.clevisWidth == 50.0, 'RearClevis fromJson: clevisWidth korundu');

  // Trunnion round-trip
  final trunnionJson = trunnion.toJson();
  final trunnionRestored = MountingType.fromJson(trunnionJson) as Trunnion;
  expect(trunnionRestored.headDistance == 200.0, 'Trunnion fromJson: headDistance korundu');

  // SphericalBearing round-trip
  final sphericalJson = spherical.toJson();
  final sphericalRestored = MountingType.fromJson(sphericalJson) as SphericalBearing;
  expect(sphericalRestored.sphereDiameter == 35.0, 'SphericalBearing fromJson: sphereDiameter korundu');

  // Geçersiz JSON
  expectThrows<MountingValidationException>(
    () => MountingType.fromJson({'category': 'unknownType'}),
    'Bilinmeyen kategori → MountingValidationException',
  );

  // =========================================================================
  // 7. MountingType Validasyon Testleri
  // =========================================================================
  print('\n--- MountingType Validasyon ---');

  // FrontFlange: Rod > Bore
  expectThrows<MountingValidationException>(
    () => const FrontFlange(
      flangeDiameter: 100.0,
      boltCircleDiameter: 120.0, // BCD > flanş çapı → HATA
      boltCount: 4,
    ).validate(),
    'FrontFlange: BCD > flanş çapı → MountingValidationException',
  );

  expectThrows<MountingValidationException>(
    () => const FrontFlange(
      flangeDiameter: 100.0,
      boltCircleDiameter: 80.0,
      boltCount: 2, // 2 cıvata → HATA (minimum 3)
    ).validate(),
    'FrontFlange: delik sayısı < 3 → MountingValidationException',
  );

  // FrontFlange: geçerli parametreler
  expect(
    const FrontFlange(
      flangeDiameter: 160.0,
      boltCircleDiameter: 130.0,
      boltCount: 6,
    ).validate() == true,
    'FrontFlange: geçerli parametreler → true',
  );

  // RearClevis: çatal genişliği ≤ pim çapı
  expectThrows<MountingValidationException>(
    () => const RearClevis(
      pinDiameter: 40.0,
      clevisWidth: 30.0, // w < d_pin → HATA
      axisDistance: 50.0,
    ).validate(),
    'RearClevis: çatal genişliği < pim çapı → MountingValidationException',
  );

  // RearClevis: geçerli parametreler
  expect(
    const RearClevis(
      pinDiameter: 30.0,
      clevisWidth: 50.0,
      axisDistance: 60.0,
    ).validate() == true,
    'RearClevis: geçerli parametreler → true',
  );

  // Trunnion: negatif çap
  expectThrows<MountingValidationException>(
    () => const Trunnion(
      headDistance: 200.0,
      trunnionDiameter: -10.0, // Negatif → HATA
    ).validate(),
    'Trunnion: negatif pim çapı → MountingValidationException',
  );

  // SphericalBearing: delik ≥ küre
  expectThrows<MountingValidationException>(
    () => const SphericalBearing(
      sphereDiameter: 20.0,
      boreDiameter: 25.0, // delik > küre → HATA
    ).validate(),
    'SphericalBearing: delik > küre → MountingValidationException',
  );

  // SphericalBearing: yetersiz et kalınlığı
  expectThrows<MountingValidationException>(
    () => const SphericalBearing(
      sphereDiameter: 22.0,
      boreDiameter: 20.0, // et = 1 mm < 3 mm → HATA
    ).validate(),
    'SphericalBearing: et kalınlığı < 3 mm → MountingValidationException',
  );

  // =========================================================================
  // 8. HydraulicCylinder Validasyon Testleri (mevcut)
  // =========================================================================
  print('\n--- HydraulicCylinder Validasyon ---');

  expectThrows<InvalidDimensionException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 40.0,
      rodDiameter: 50.0,
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Rod çapı > Boru çapı → InvalidDimensionException',
  );

  expectThrows<InvalidDimensionException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 50.0,
      rodDiameter: 50.0,
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Rod çapı == Boru çapı → InvalidDimensionException',
  );

  expectThrows<InvalidPressureException>(
    () => HydraulicCylinder(
      pressure: -10.0,
      boreDiameter: 80.0,
      rodDiameter: 45.0,
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Negatif basınç → InvalidPressureException',
  );

  expectThrows<InvalidPressureException>(
    () => HydraulicCylinder(
      pressure: 0.0,
      boreDiameter: 80.0,
      rodDiameter: 45.0,
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Sıfır basınç → InvalidPressureException',
  );

  expectThrows<InvalidDimensionException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: -80.0,
      rodDiameter: 45.0,
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Negatif boru çapı → InvalidDimensionException',
  );

  expectThrows<InvalidStrokeException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 80.0,
      rodDiameter: 45.0,
      stroke: 500.0,
      closedLength: 300.0,
    ),
    'Kapalı boy < strok → InvalidStrokeException',
  );

  expectThrows<InvalidStrokeException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 80.0,
      rodDiameter: 45.0,
      stroke: -100.0,
      closedLength: 700.0,
    ),
    'Negatif strok → InvalidStrokeException',
  );

  final highPressureCylinder = HydraulicCylinder(
    pressure: 200.0,
    boreDiameter: 80.0,
    rodDiameter: 45.0,
    stroke: 500.0,
    closedLength: 700.0,
  );
  expectThrows<InvalidPressureException>(
    () => highPressureCylinder.calculateWallThickness(),
    'Çok yüksek basınçta Lamé → InvalidPressureException',
  );

  // =========================================================================
  // Sonuç
  // =========================================================================
  print('\n========================================');
  print('Toplam: ${passed + failed} test');
  print('Geçen: $passed');
  print('Kalan: $failed');
  print('========================================');

  if (failed > 0) {
    throw Exception('$failed test başarısız oldu!');
  }
}
