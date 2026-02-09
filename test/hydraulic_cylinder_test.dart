import 'dart:math' as math;

import '../lib/exceptions/hydraulic_exceptions.dart';
import '../lib/models/hydraulic_cylinder.dart';
import '../lib/models/mounting_type.dart';

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

  // -----------------------------------------------------------------------
  // 1. Geometrik Özellikler
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // 2. Kuvvet Hesaplamaları
  // -----------------------------------------------------------------------
  print('\n--- Kuvvet Hesaplamaları ---');

  // F_push = P × A_piston × η = 20 × 5026.55 × 0.95 ≈ 95,504.4 N
  final expectedPushForce = 20.0 * expectedPistonArea * 0.95;
  expect(
    (cylinder.calculatePushForce() - expectedPushForce).abs() < 0.1,
    'İtme kuvveti doğru (≈ ${expectedPushForce.toStringAsFixed(1)} N)',
  );

  // F_pull = P × A_annular × η = 20 × 3436.12 × 0.95 ≈ 65,286.2 N
  final expectedPullForce = 20.0 * expectedAnnularArea * 0.95;
  expect(
    (cylinder.calculatePullForce() - expectedPullForce).abs() < 0.1,
    'Çekme kuvveti doğru (≈ ${expectedPullForce.toStringAsFixed(1)} N)',
  );

  expect(
    cylinder.calculatePullForce() < cylinder.calculatePushForce(),
    'Çekme kuvveti her zaman itme kuvvetinden küçük olmalı',
  );

  // -----------------------------------------------------------------------
  // 3. Et Kalınlığı (Lamé)
  // -----------------------------------------------------------------------
  print('\n--- Et Kalınlığı (Lamé) ---');

  final wallThickness = cylinder.calculateWallThickness();
  expect(
    wallThickness > 0,
    'Et kalınlığı pozitif olmalı (${wallThickness.toStringAsFixed(2)} mm)',
  );

  // Manuel doğrulama:
  // σ_izin = 355 / 2.5 = 142 MPa
  // R_i = 40 mm
  // R_o = 40 × √((142 + 20) / (142 - 20)) = 40 × √(162/122) = 40 × 1.1526 ≈ 46.10
  // t = 46.10 - 40 = 6.10 mm
  final allowableStress = 355.0 / 2.5;
  final expectedRo =
      40.0 * math.sqrt((allowableStress + 20.0) / (allowableStress - 20.0));
  final expectedThickness = expectedRo - 40.0;
  expect(
    (wallThickness - expectedThickness).abs() < 0.01,
    'Et kalınlığı Lamé formülüne uygun (≈ ${expectedThickness.toStringAsFixed(2)} mm)',
  );

  // -----------------------------------------------------------------------
  // 4. Burkulma Analizi (Euler)
  // -----------------------------------------------------------------------
  print('\n--- Burkulma Analizi (Euler) ---');

  // Pin-Pin (n = 1.0) konfigürasyonu
  final bucklingPinPin = cylinder.checkBuckling(MountingType.pinPin);
  expect(
    bucklingPinPin.criticalLoad > 0,
    'Kritik burkulma yükü pozitif olmalı',
  );

  // Manuel doğrulama:
  // I = π/64 × 45⁴ ≈ 201,289.1 mm⁴
  // L = 1200 mm (açık boy)
  // P_cr = 1.0 × π² × 210000 × 201,289.1 / 1200² ≈ 289,680 N
  final expectedI = math.pi / 64 * math.pow(45.0, 4);
  final expectedPcr =
      1.0 * math.pi * math.pi * 210000.0 * expectedI / (1200.0 * 1200.0);
  expect(
    (bucklingPinPin.criticalLoad - expectedPcr).abs() / expectedPcr < 0.001,
    'Pin-Pin kritik yük doğru (≈ ${expectedPcr.toStringAsFixed(0)} N)',
  );

  expect(
    bucklingPinPin.appliedLoad == cylinder.calculatePushForce(),
    'Uygulanan yük = itme kuvveti olmalı',
  );

  // Fixed-Free (n = 0.25) - en kritik durum
  final bucklingFixedFree = cylinder.checkBuckling(MountingType.fixedFree);
  expect(
    bucklingFixedFree.criticalLoad < bucklingPinPin.criticalLoad,
    'Fixed-Free kritik yük, Pin-Pin\'den küçük olmalı',
  );

  // Fixed-Fixed (n = 4.0) - en güvenli durum
  final bucklingFixedFixed = cylinder.checkBuckling(MountingType.fixedFixed);
  expect(
    bucklingFixedFixed.criticalLoad > bucklingPinPin.criticalLoad,
    'Fixed-Fixed kritik yük, Pin-Pin\'den büyük olmalı',
  );

  // Sıralama: fixedFree < pinPin < fixedPin < fixedFixed
  final bucklingFixedPin = cylinder.checkBuckling(MountingType.fixedPin);
  expect(
    bucklingFixedFree.criticalLoad < bucklingPinPin.criticalLoad &&
        bucklingPinPin.criticalLoad < bucklingFixedPin.criticalLoad &&
        bucklingFixedPin.criticalLoad < bucklingFixedFixed.criticalLoad,
    'Kritik yük sıralaması: fixedFree < pinPin < fixedPin < fixedFixed',
  );

  // -----------------------------------------------------------------------
  // 5. Validasyon / Exception Testleri
  // -----------------------------------------------------------------------
  print('\n--- Validasyon / Exception Testleri ---');

  expectThrows<InvalidDimensionException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 40.0,
      rodDiameter: 50.0, // Rod > Bore → HATA
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Rod çapı > Boru çapı → InvalidDimensionException',
  );

  expectThrows<InvalidDimensionException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 50.0,
      rodDiameter: 50.0, // Rod == Bore → HATA
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Rod çapı == Boru çapı → InvalidDimensionException',
  );

  expectThrows<InvalidPressureException>(
    () => HydraulicCylinder(
      pressure: -10.0, // Negatif basınç → HATA
      boreDiameter: 80.0,
      rodDiameter: 45.0,
      stroke: 500.0,
      closedLength: 700.0,
    ),
    'Negatif basınç → InvalidPressureException',
  );

  expectThrows<InvalidPressureException>(
    () => HydraulicCylinder(
      pressure: 0.0, // Sıfır basınç → HATA
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
      boreDiameter: -80.0, // Negatif çap → HATA
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
      closedLength: 300.0, // Kapalı boy < strok → HATA
    ),
    'Kapalı boy < strok → InvalidStrokeException',
  );

  expectThrows<InvalidStrokeException>(
    () => HydraulicCylinder(
      pressure: 20.0,
      boreDiameter: 80.0,
      rodDiameter: 45.0,
      stroke: -100.0, // Negatif strok → HATA
      closedLength: 700.0,
    ),
    'Negatif strok → InvalidStrokeException',
  );

  // Basınç çok yüksek → Lamé formülü uygulanamaz
  final highPressureCylinder = HydraulicCylinder(
    pressure: 200.0, // 2000 bar - çok yüksek
    boreDiameter: 80.0,
    rodDiameter: 45.0,
    stroke: 500.0,
    closedLength: 700.0,
  );
  expectThrows<InvalidPressureException>(
    () => highPressureCylinder.calculateWallThickness(),
    'Çok yüksek basınçta Lamé → InvalidPressureException',
  );

  // -----------------------------------------------------------------------
  // Sonuç
  // -----------------------------------------------------------------------
  print('\n========================================');
  print('Toplam: ${passed + failed} test');
  print('Geçen: $passed');
  print('Kalan: $failed');
  print('========================================');

  if (failed > 0) {
    throw Exception('$failed test başarısız oldu!');
  }
}
