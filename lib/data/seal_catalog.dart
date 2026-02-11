/// Sızdırmazlık katalog katmanı.
///
/// Bu dosya, keçe ölçülerinin çaplara göre otomatik seçimi için
/// basit bir statik veri kaynağı ve seçim motoru içerir.

enum SealType { piston, rod, wiper, oRing }

class SealProfile {
  final String code;
  final double width;
  final double height;

  const SealProfile({
    required this.code,
    required this.width,
    required this.height,
  });
}

class _RangeProfile {
  final double min;
  final double? max;
  final SealProfile profile;

  const _RangeProfile({
    required this.min,
    required this.max,
    required this.profile,
  });

  bool includes(double diameter) {
    final maxValue = max;
    if (maxValue == null) {
      return diameter >= min;
    }

    return diameter >= min && diameter < maxValue;
  }
}

class SealRepository {
  // K19 Compact Piston keçesi - örnek aralıklar (mm)
  static const List<_RangeProfile> _pistonSealRanges = [
    _RangeProfile(
      min: 40,
      max: 80,
      profile: SealProfile(code: 'K19', width: 18.0, height: 7.0),
    ),
    _RangeProfile(
      min: 80,
      max: 125,
      profile: SealProfile(code: 'K19', width: 22.5, height: 8.5),
    ),
    _RangeProfile(
      min: 125,
      max: null,
      profile: SealProfile(code: 'K19', width: 26.5, height: 10.0),
    ),
  ];

  // K33 Nutring - rod keçesi için örnek aralıklar (mm)
  // Et kalınlığı (H) yaklaşık 5 mm - 12 mm bandında ilerler.
  static const List<_RangeProfile> _rodSealRanges = [
    _RangeProfile(
      min: 16,
      max: 25,
      profile: SealProfile(code: 'K33', width: 8.0, height: 5.0),
    ),
    _RangeProfile(
      min: 25,
      max: 40,
      profile: SealProfile(code: 'K33', width: 10.0, height: 6.0),
    ),
    _RangeProfile(
      min: 40,
      max: 56,
      profile: SealProfile(code: 'K33', width: 12.0, height: 8.0),
    ),
    _RangeProfile(
      min: 56,
      max: 80,
      profile: SealProfile(code: 'K33', width: 14.0, height: 10.0),
    ),
    _RangeProfile(
      min: 80,
      max: null,
      profile: SealProfile(code: 'K33', width: 16.0, height: 12.0),
    ),
  ];

  // Toz keçesi (wiper) - örnek aralıklar (mm)
  static const List<_RangeProfile> _wiperRanges = [
    _RangeProfile(
      min: 16,
      max: 25,
      profile: SealProfile(code: 'K17', width: 6.0, height: 4.0),
    ),
    _RangeProfile(
      min: 25,
      max: 40,
      profile: SealProfile(code: 'K17', width: 7.0, height: 5.0),
    ),
    _RangeProfile(
      min: 40,
      max: 56,
      profile: SealProfile(code: 'K17', width: 9.0, height: 6.0),
    ),
    _RangeProfile(
      min: 56,
      max: 80,
      profile: SealProfile(code: 'K17', width: 10.0, height: 7.0),
    ),
    _RangeProfile(
      min: 80,
      max: null,
      profile: SealProfile(code: 'K17', width: 12.0, height: 8.0),
    ),
  ];

  static SealProfile getPistonSeal(double boreDiameter) {
    _validateDiameter(boreDiameter, parameterName: 'boreDiameter');
    return _selectByDiameter(
      diameter: boreDiameter,
      ranges: _pistonSealRanges,
      fallback: const SealProfile(code: 'K19', width: 18.0, height: 7.0),
    );
  }

  static SealProfile getRodSeal(double rodDiameter) {
    _validateDiameter(rodDiameter, parameterName: 'rodDiameter');
    return _selectByDiameter(
      diameter: rodDiameter,
      ranges: _rodSealRanges,
      fallback: const SealProfile(code: 'K33', width: 8.0, height: 5.0),
    );
  }

  static SealProfile getWiper(double rodDiameter) {
    _validateDiameter(rodDiameter, parameterName: 'rodDiameter');
    return _selectByDiameter(
      diameter: rodDiameter,
      ranges: _wiperRanges,
      fallback: const SealProfile(code: 'K17', width: 6.0, height: 4.0),
    );
  }

  static SealProfile _selectByDiameter({
    required double diameter,
    required List<_RangeProfile> ranges,
    required SealProfile fallback,
  }) {
    for (final range in ranges) {
      if (range.includes(diameter)) {
        return range.profile;
      }
    }

    return fallback;
  }

  static void _validateDiameter(double value, {required String parameterName}) {
    if (value <= 0) {
      throw ArgumentError.value(
        value,
        parameterName,
        'Çap sıfırdan büyük olmalıdır.',
      );
    }
  }
}
