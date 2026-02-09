/// Hidrolik Silindir Tasarım Uygulaması - Özel İstisna Sınıfları
///
/// Bu dosya, hidrolik silindir parametrelerinin mühendislik kurallarına
/// uygunluğunu denetleyen özel exception sınıflarını içerir.

/// Tüm hidrolik silindir hatalarının türediği temel istisna sınıfı.
class HydraulicCylinderException implements Exception {
  final String message;
  final String? parameterName;

  const HydraulicCylinderException(this.message, {this.parameterName});

  @override
  String toString() =>
      'HydraulicCylinderException: $message'
      '${parameterName != null ? ' [Parametre: $parameterName]' : ''}';
}

/// Geometrik boyut hatası.
/// Rod çapının boru iç çapından büyük olması gibi durumlar için.
class InvalidDimensionException extends HydraulicCylinderException {
  const InvalidDimensionException(super.message, {super.parameterName});

  @override
  String toString() =>
      'InvalidDimensionException: $message'
      '${parameterName != null ? ' [Parametre: $parameterName]' : ''}';
}

/// Basınç değeri hatası.
/// Negatif veya sıfır basınç gibi fiziksel olarak anlamsız değerler için.
class InvalidPressureException extends HydraulicCylinderException {
  const InvalidPressureException(super.message, {super.parameterName});

  @override
  String toString() =>
      'InvalidPressureException: $message'
      '${parameterName != null ? ' [Parametre: $parameterName]' : ''}';
}

/// Strok / boy hatası.
/// Negatif strok veya kapalı boyun stroktan kısa olması gibi durumlar için.
class InvalidStrokeException extends HydraulicCylinderException {
  const InvalidStrokeException(super.message, {super.parameterName});

  @override
  String toString() =>
      'InvalidStrokeException: $message'
      '${parameterName != null ? ' [Parametre: $parameterName]' : ''}';
}

/// Burkulma analizi hatası.
/// Geçersiz bağlantı tipi veya malzeme parametresi için.
class BucklingAnalysisException extends HydraulicCylinderException {
  const BucklingAnalysisException(super.message, {super.parameterName});

  @override
  String toString() =>
      'BucklingAnalysisException: $message'
      '${parameterName != null ? ' [Parametre: $parameterName]' : ''}';
}

/// Bağlantı elemanı validasyon hatası.
/// Flanş çapı, pim çapı gibi bağlantı parametrelerinin geçersizliği için.
class MountingValidationException extends HydraulicCylinderException {
  const MountingValidationException(super.message, {super.parameterName});

  @override
  String toString() =>
      'MountingValidationException: $message'
      '${parameterName != null ? ' [Parametre: $parameterName]' : ''}';
}
