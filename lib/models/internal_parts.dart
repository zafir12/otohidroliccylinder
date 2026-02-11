import '../data/seal_catalog.dart';
import '../exceptions/hydraulic_exceptions.dart';

/// ============================================================================
/// CylinderPiston - Piston İç Bileşeni
/// ============================================================================
///
/// Piston kalınlığı, rod çapına bağlı olarak otomatik atanabilir:
///   width = 0.6 × rodDiameter
class CylinderPiston {
  final double width;
  final String material;
  final int sealGrooveCount;

  /// K19 compact piston keçesi için önerilen kanal ölçüleri.
  final double? compactSealWidth;
  final double? compactSealHeight;

  CylinderPiston({
    required double rodDiameter,
    double? width,
    this.material = 'C45',
    this.sealGrooveCount = 2,
    this.compactSealWidth,
    this.compactSealHeight,
  }) : width = width ?? (0.6 * rodDiameter) {
    if (rodDiameter <= 0) {
      throw const InvalidDimensionException(
        'Rod çapı sıfır veya negatif olamaz.',
        parameterName: 'rodDiameter',
      );
    }

    if (this.width <= 0) {
      throw const InvalidDimensionException(
        'Piston genişliği sıfır veya negatif olamaz.',
        parameterName: 'width',
      );
    }

    if (sealGrooveCount < 0) {
      throw const InvalidDimensionException(
        'Sızdırmazlık kanal sayısı negatif olamaz.',
        parameterName: 'sealGrooveCount',
      );
    }
  }

  factory CylinderPiston.fromJson(Map<String, dynamic> json, {required double rodDiameter}) {
    return CylinderPiston(
      rodDiameter: rodDiameter,
      width: (json['width'] as num?)?.toDouble(),
      material: (json['material'] as String?) ?? 'C45',
      sealGrooveCount: (json['sealGrooveCount'] as num?)?.toInt() ?? 2,
      compactSealWidth: (json['compactSealWidth'] as num?)?.toDouble(),
      compactSealHeight: (json['compactSealHeight'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'material': material,
        'sealGrooveCount': sealGrooveCount,
        'compactSealWidth': compactSealWidth,
        'compactSealHeight': compactSealHeight,
      };
}

/// ============================================================================
/// CylinderHead - Kep/Gland İç Bileşeni
/// ============================================================================
///
/// Mühendislik kuralı: guideLength >= rodDiameter
class CylinderHead {
  final double totalLength;
  final double guideLength;
  final String material;

  CylinderHead({
    required this.totalLength,
    required this.guideLength,
    this.material = 'St52',
    required double rodDiameter,
  }) {
    if (totalLength <= 0) {
      throw const InvalidDimensionException(
        'Kep toplam boyu sıfır veya negatif olamaz.',
        parameterName: 'totalLength',
      );
    }

    if (guideLength <= 0) {
      throw const InvalidDimensionException(
        'Yataklama boyu sıfır veya negatif olamaz.',
        parameterName: 'guideLength',
      );
    }

    if (guideLength > totalLength) {
      throw const InvalidDimensionException(
        'Yataklama boyu toplam boydan büyük olamaz.',
        parameterName: 'guideLength',
      );
    }

    if (guideLength < rodDiameter) {
      throw InvalidDimensionException(
        'Yataklama boyu ($guideLength mm), rod çapından ($rodDiameter mm) küçük olamaz.',
        parameterName: 'guideLength',
      );
    }
  }

  factory CylinderHead.fromJson(Map<String, dynamic> json, {required double rodDiameter}) {
    return CylinderHead(
      totalLength: (json['totalLength'] as num).toDouble(),
      guideLength: (json['guideLength'] as num).toDouble(),
      material: (json['material'] as String?) ?? 'St52',
      rodDiameter: rodDiameter,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalLength': totalLength,
        'guideLength': guideLength,
        'material': material,
      };
}

/// ============================================================================
/// CylinderBase - Arka Kapak İç Bileşeni
/// ============================================================================
class CylinderBase {
  final double thickness;
  final String portSize;

  CylinderBase({
    required this.thickness,
    this.portSize = 'G 1/2',
  }) {
    if (thickness <= 0) {
      throw const InvalidDimensionException(
        'Taban et kalınlığı sıfır veya negatif olamaz.',
        parameterName: 'thickness',
      );
    }
  }

  factory CylinderBase.fromJson(Map<String, dynamic> json) => CylinderBase(
        thickness: (json['thickness'] as num).toDouble(),
        portSize: (json['portSize'] as String?) ?? 'G 1/2',
      );

  Map<String, dynamic> toJson() => {
        'thickness': thickness,
        'portSize': portSize,
      };
}

/// ---------------------------------------------------------------------------
/// Entegrasyon Örneği (Phase 2.8)
/// ---------------------------------------------------------------------------
///
/// Kullanıcı sadece çap girerek piston keçe kanalı ölçülerini otomatik
/// doldurabilir:
///
/// ```dart
/// final boreDiameter = 100.0;
/// final rodDiameter = 56.0;
/// final pistonSeal = SealRepository.getPistonSeal(boreDiameter);
///
/// final piston = CylinderPiston(
///   rodDiameter: rodDiameter,
///   compactSealWidth: pistonSeal.width,
///   compactSealHeight: pistonSeal.height,
/// );
///
/// // Örn:
/// // piston.compactSealWidth = SealRepository.getPistonSeal(boreDiameter).width;
/// ```
