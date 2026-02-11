import 'package:flutter_test/flutter_test.dart';
import 'package:otohidroliccylinder/data/seal_catalog.dart';

void main() {
  group('SealRepository', () {
    test('piston keçesi bore çapına göre doğru seçilir', () {
      expect(SealRepository.getPistonSeal(63).width, 18.0);
      expect(SealRepository.getPistonSeal(100).width, 22.5);
      expect(SealRepository.getPistonSeal(140).width, 26.5);
    });

    test('rod keçesi et kalınlığı 5-12 mm aralığında değişir', () {
      expect(SealRepository.getRodSeal(20).height, 5.0);
      expect(SealRepository.getRodSeal(50).height, 8.0);
      expect(SealRepository.getRodSeal(90).height, 12.0);
    });

    test('wiper keçesi rod çapına göre seçilir', () {
      final wiper = SealRepository.getWiper(45);
      expect(wiper.code, 'K17');
      expect(wiper.width, 9.0);
    });

    test('negatif/0 çap için hata verir', () {
      expect(() => SealRepository.getPistonSeal(0), throwsArgumentError);
      expect(() => SealRepository.getRodSeal(-1), throwsArgumentError);
      expect(() => SealRepository.getWiper(0), throwsArgumentError);
    });
  });
}
