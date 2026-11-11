import 'package:adhan/adhan.dart' as adhan;

/// Supported prayer time calculation methods (12 official methods).
enum PrayerCalculationMethod {
  muslimWorldLeague(
    storageKey: 'muslim_world_league',
    arabicName: 'رابطة العالم الإسلامي',
    adhanMethod: adhan.CalculationMethod.muslim_world_league,
  ),
  egyptian(
    storageKey: 'egyptian',
    arabicName: 'الهيئة المصرية العامة للمساحة',
    adhanMethod: adhan.CalculationMethod.egyptian,
  ),
  karachi(
    storageKey: 'karachi',
    arabicName: 'جامعة العلوم الإسلامية - كراتشي',
    adhanMethod: adhan.CalculationMethod.karachi,
  ),
  ummAlQura(
    storageKey: 'umm_al_qura',
    arabicName: 'أم القرى',
    adhanMethod: adhan.CalculationMethod.umm_al_qura,
  ),
  dubai(
    storageKey: 'dubai',
    arabicName: 'دبي',
    adhanMethod: adhan.CalculationMethod.dubai,
  ),
  moonSightingCommittee(
    storageKey: 'moon_sighting_committee',
    arabicName: 'لجنة تحري الهلال',
    adhanMethod: adhan.CalculationMethod.moon_sighting_committee,
  ),
  northAmerica(
    storageKey: 'north_america',
    arabicName: 'أمريكا الشمالية (ISNA)',
    adhanMethod: adhan.CalculationMethod.north_america,
  ),
  kuwait(
    storageKey: 'kuwait',
    arabicName: 'الكويت',
    adhanMethod: adhan.CalculationMethod.kuwait,
  ),
  qatar(
    storageKey: 'qatar',
    arabicName: 'قطر',
    adhanMethod: adhan.CalculationMethod.qatar,
  ),
  singapore(
    storageKey: 'singapore',
    arabicName: 'سنغافورة',
    adhanMethod: adhan.CalculationMethod.singapore,
  ),
  turkey(
    storageKey: 'turkey',
    arabicName: 'تركيا (رئاسة الشؤون الدينية)',
    adhanMethod: adhan.CalculationMethod.turkey,
  ),
  tehran(
    storageKey: 'tehran',
    arabicName: 'طهران',
    adhanMethod: adhan.CalculationMethod.tehran,
  );

  final String storageKey;
  final String arabicName;
  final adhan.CalculationMethod adhanMethod;

  const PrayerCalculationMethod({
    required this.storageKey,
    required this.arabicName,
    required this.adhanMethod,
  });

  /// Parses a persisted storage key into [PrayerCalculationMethod], or returns null if unknown.
  static PrayerCalculationMethod? tryFromStorageKey(Object? key) {
    if (key is! String) return null;
    for (final method in values) {
      if (method.storageKey == key) return method;
    }
    return null;
  }
}

