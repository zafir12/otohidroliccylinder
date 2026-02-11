import '../exceptions/hydraulic_exceptions.dart';
import 'mounting_types/front_flange.dart';
import 'mounting_types/rear_clevis.dart';
import 'mounting_types/spherical_bearing.dart';
import 'mounting_types/trunnion.dart';

/// ============================================================================
/// MountingType - Bağlantı Tipi Abstract Sınıfı (Polimorfik Yapı)
/// ============================================================================
///
/// Hidrolik silindirlerde bağlantı elemanı seçimi, hem mekanik tasarımı
/// hem de burkulma analizini doğrudan etkiler. Her bağlantı tipi:
///
///   1. Farklı geometrik parametreler gerektirir (çap, genişlik, delik vb.)
///   2. Farklı bir Euler burkulma uç koşulu (boundary condition) tanımlar
///   3. Farklı bir UI formu oluşturulmasını gerektirir
///
/// Bu abstract class, "Strategy Pattern" + "Factory Pattern" birleşimi ile
/// tüm bağlantı tiplerini tek bir polimorfik arayüzde toplar.
///
/// Referanslar:
///   - ISO 6020-1/2: Hydraulic Cylinder Mounting Dimensions
///   - ISO 8132: Hydraulic Cylinder Rod End Types
///   - Shigley's: Euler Column End Conditions
/// ============================================================================
abstract class MountingType {
  const MountingType();

  // ---------------------------------------------------------------------------
  // Kimlik & Açıklama (Identity)
  // ---------------------------------------------------------------------------

  /// Bağlantı tipi kategori tanımlayıcısı.
  /// Factory method ve serialization için kullanılır.
  MountingCategory get category;

  /// Kullanıcıya gösterilecek Türkçe açıklama.
  /// Örn: "Ön Flanş (Front Flange)"
  String get description;

  // ---------------------------------------------------------------------------
  // Euler Burkulma Katsayıları (Buckling Coefficients)
  // ---------------------------------------------------------------------------

  /// Euler "end-fixity coefficient" (n)
  ///
  /// Kritik burkulma yükü formülünde doğrudan çarpan olarak kullanılır:
  ///   P_cr = n × π² × E × I / L²
  ///
  /// Bağlantı tipine göre uç koşulunu temsil eder:
  ///   - Ankastre-Mafsal (Fixed-Pin):   n = 2.0
  ///   - Mafsal-Mafsal (Pin-Pin):       n = 1.0
  ///   - Ankastre-Serbest (Fixed-Free): n = 0.25
  double get endFixityCoefficient;

  /// Etkili boy çarpanı (K)
  ///
  /// Etkili burkulma boyu: L_eff = K × L
  /// İlişki: n = 1 / K²
  double get effectiveLengthFactor;

  // ---------------------------------------------------------------------------
  // UI Form Alan Tanımlayıcıları (Form Field Descriptors)
  // ---------------------------------------------------------------------------

  /// Bu bağlantı tipinin UI formunda gösterilecek alanlarını döndürür.
  ///
  /// Flutter UI katmanı bu listeyi kullanarak dinamik olarak
  /// TextFormField widget'ları oluşturabilir:
  ///
  /// ```dart
  /// // UI tarafında kullanım örneği:
  /// final mounting = MountingType.fromCategory(MountingCategory.frontFlange);
  /// for (final field in mounting.formFields) {
  ///   TextFormField(
  ///     decoration: InputDecoration(
  ///       labelText: field.label,
  ///       suffixText: field.unit,
  ///       hintText: 'Min: ${field.min} – Max: ${field.max}',
  ///     ),
  ///   );
  /// }
  /// ```
  List<FormFieldDescriptor> get formFields;

  // ---------------------------------------------------------------------------
  // Validasyon (Validation)
  // ---------------------------------------------------------------------------

  /// Bağlantı elemanı parametrelerinin mühendislik kurallarına uygunluğunu
  /// kontrol eder.
  ///
  /// Her alt sınıf kendi geometrik kısıtlarını denetler.
  /// Geçersiz parametrelerde [MountingValidationException] fırlatılır.
  ///
  /// Döndürülen değer:
  ///   - `true`: Tüm parametreler geçerli
  ///   - Exception: Geçersiz parametre tespit edildi
  bool validate();

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Bağlantı elemanı verilerini JSON Map'e dönüştürür.
  ///
  /// Proje kaydetme / yükleme ve API iletişimi için kullanılır.
  /// Her alt sınıf kendi parametrelerini ekler.
  Map<String, dynamic> toJson();

  // ---------------------------------------------------------------------------
  // Factory Method (Creational Pattern)
  // ---------------------------------------------------------------------------

  /// Verilen [MountingCategory]'ye göre varsayılan parametrelerle
  /// ilgili alt sınıf örneğini oluşturur.
  ///
  /// UI tarafında kullanıcı bir bağlantı tipi seçtiğinde:
  /// ```dart
  /// onChanged: (MountingCategory? selected) {
  ///   final mounting = MountingType.fromCategory(selected!);
  ///   // mounting.formFields ile formu güncelle
  /// }
  /// ```
  factory MountingType.fromCategory(MountingCategory category) {
    switch (category) {
      case MountingCategory.frontFlange:
        return FrontFlange.empty();
      case MountingCategory.rearClevis:
        return RearClevis.empty();
      case MountingCategory.trunnion:
        return Trunnion.empty();
      case MountingCategory.sphericalBearing:
        return SphericalBearing.empty();
    }
  }

  /// JSON Map'ten uygun alt sınıf örneği oluşturur.
  ///
  /// Proje dosyasından yükleme senaryosu:
  /// ```dart
  /// final json = jsonDecode(savedProject);
  /// final mounting = MountingType.fromJson(json['frontMounting']);
  /// ```
  factory MountingType.fromJson(Map<String, dynamic> json) {
    final categoryStr = json['category'] as String;
    final category = MountingCategory.values.firstWhere(
      (c) => c.name == categoryStr,
      orElse: () => throw MountingValidationException(
        'Bilinmeyen bağlantı tipi: $categoryStr',
        parameterName: 'category',
      ),
    );

    switch (category) {
      case MountingCategory.frontFlange:
        return FrontFlange.fromJson(json);
      case MountingCategory.rearClevis:
        return RearClevis.fromJson(json);
      case MountingCategory.trunnion:
        return Trunnion.fromJson(json);
      case MountingCategory.sphericalBearing:
        return SphericalBearing.fromJson(json);
    }
  }

  @override
  String toString() => '$category: $description';
}

/// ============================================================================
/// MountingCategory - Bağlantı Tipi Tanımlayıcı Enum
/// ============================================================================
///
/// Factory method ve serialization için kullanılan basit tanımlayıcı.
/// Polimorfik davranışı taşımaz; sadece "hangi tip?" sorusuna cevap verir.
enum MountingCategory {
  frontFlange('Ön Flanş'),
  rearClevis('Arka Çatal'),
  trunnion('Orta Eklem'),
  sphericalBearing('Oynak Başlık');

  const MountingCategory(this.label);

  /// UI'da Dropdown menüsünde gösterilecek Türkçe etiket.
  final String label;
}

/// ============================================================================
/// FormFieldDescriptor - UI Form Alanı Tanımlayıcı
/// ============================================================================
///
/// Bağlantı tipinin gerektirdiği her bir parametre için UI'da
/// nasıl bir form alanı oluşturulacağını tanımlar.
///
/// Bu sınıf "Presentation Layer"a ait değildir; Business Logic'in
/// UI'a "ben şu alanları bekliyorum" demesidir (Metadata Pattern).
///
/// Flutter UI'da kullanım örneği:
/// ```dart
/// Widget buildMountingForm(MountingType mounting) {
///   return Column(
///     children: mounting.formFields.map((field) {
///       return TextFormField(
///         decoration: InputDecoration(
///           labelText: field.label,
///           suffixText: field.unit,
///           helperText: field.hint,
///         ),
///         keyboardType: field.isInteger
///             ? TextInputType.number
///             : TextInputType.numberWithOptions(decimal: true),
///         validator: (value) {
///           final v = double.tryParse(value ?? '');
///           if (v == null) return 'Geçerli bir sayı girin';
///           if (v < field.min) return 'Minimum: ${field.min} ${field.unit}';
///           if (v > field.max) return 'Maksimum: ${field.max} ${field.unit}';
///           return null;
///         },
///       );
///     }).toList(),
///   );
/// }
/// ```
class FormFieldDescriptor {
  /// Parametre anahtarı (JSON key ve programatik erişim için)
  /// Örn: 'flangeDiameter', 'pinDiameter'
  final String key;

  /// Kullanıcıya gösterilecek Türkçe etiket
  /// Örn: 'Flanş Çapı', 'Pim Çapı'
  final String label;

  /// Birim göstergesi
  /// Örn: 'mm', 'adet'
  final String unit;

  /// Alt sınır (fiziksel minimum)
  final double min;

  /// Üst sınır (fiziksel/pratik maksimum)
  final double max;

  /// Form alanı için ipucu metni
  final String? hint;

  /// Tam sayı mı yoksa ondalıklı mı? (UI klavye tipi için)
  final bool isInteger;

  const FormFieldDescriptor({
    required this.key,
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    this.hint,
    this.isInteger = false,
  });
}
