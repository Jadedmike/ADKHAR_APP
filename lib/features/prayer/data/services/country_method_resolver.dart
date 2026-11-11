import '../../domain/entities/prayer_calculation_method.dart';
import '../../domain/entities/prayer_settings.dart';

/// Resolves the prayer calculation method from an ISO-3166-1 alpha-2 country code.
///
/// Never infers the country from device language or raw coordinates.
/// Unknown, unsupported, or missing country codes fall back to [PrayerCalculationMethod.muslimWorldLeague].
class CountryMethodResolver {
  CountryMethodResolver._();

  static const Map<String, PrayerCalculationMethod> _countryToMethod = {
    'SA': PrayerCalculationMethod.ummAlQura,
    'AE': PrayerCalculationMethod.dubai,
    'KW': PrayerCalculationMethod.kuwait,
    'QA': PrayerCalculationMethod.qatar,
    'EG': PrayerCalculationMethod.egyptian,
    'PK': PrayerCalculationMethod.karachi,
    'TR': PrayerCalculationMethod.turkey,
    'IR': PrayerCalculationMethod.tehran,
    'SG': PrayerCalculationMethod.singapore,
    'MY': PrayerCalculationMethod.singapore,
    'ID': PrayerCalculationMethod.singapore,
    'BN': PrayerCalculationMethod.singapore,
  };

  /// Returns the calculation method mapped to [isoCountryCode], or MWL fallback.
  static PrayerCalculationMethod resolve(String? isoCountryCode) {
    if (isoCountryCode == null) {
      return PrayerCalculationMethod.muslimWorldLeague;
    }
    final normalized = isoCountryCode.trim().toUpperCase();
    if (normalized.length != 2) {
      return PrayerCalculationMethod.muslimWorldLeague;
    }
    return _countryToMethod[normalized] ??
        PrayerCalculationMethod.muslimWorldLeague;
  }

  /// Resolves the effective calculation method taking [PrayerSettings.calculationMode] into account.
  /// Manual selection always overrides automatic country resolution.
  static PrayerCalculationMethod resolveEffective(
    PrayerSettings settings, {
    String? isoCountryCode,
  }) {
    if (settings.calculationMode == PrayerCalculationMode.manual) {
      return settings.manualMethod;
    }
    return resolve(isoCountryCode);
  }
}
