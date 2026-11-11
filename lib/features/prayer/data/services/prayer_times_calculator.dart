import 'package:adhan/adhan.dart' as adhan;
import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_calculation_method.dart';
import '../../domain/entities/prayer_madhab.dart';
import '../../domain/entities/prayer_settings.dart';
import '../../domain/entities/saved_prayer_location.dart';
import 'country_method_resolver.dart';

/// Thrown when prayer calculation receives invalid WGS84 coordinates.
class InvalidPrayerCoordinatesException implements ArgumentError {
  @override
  final dynamic invalidValue;

  @override
  final String? name;

  @override
  final String message;

  @override
  StackTrace? get stackTrace => StackTrace.current;

  InvalidPrayerCoordinatesException(
    this.message, {
    this.name,
    this.invalidValue,
  });

  @override
  String toString() => 'InvalidPrayerCoordinatesException: $message';
}

/// Calculates Islamic prayer times using the `adhan` package and device-local calendar dates.
///
/// Timezone note:
/// Because offline saved coordinates and reverse geocoding do not carry an IANA
/// timezone identifier, `adhan` projects calculated UTC instants into the
/// device's local timezone (`.toLocal()`). No fixed UTC offsets or manual hour
/// shifts are applied.
class PrayerTimesCalculator {
  const PrayerTimesCalculator();

  static const PrayerTimesCalculator instance = PrayerTimesCalculator();

  /// Calculates the 6 daily prayer events for [localDate] plus tomorrow's Fajr.
  ///
  /// Uses [CountryMethodResolver.resolveEffective] so manual selection overrides
  /// automatic country resolution and unknown countries fall back to MWL.
  DailyPrayerTimes calculate({
    required double latitude,
    required double longitude,
    required PrayerSettings settings,
    String? isoCountryCode,
    DateTime? localDate,
    adhan.HighLatitudeRule? highLatitudeRuleOverride,
  }) {
    if (!isValidWgs84Coordinates(latitude, longitude)) {
      throw InvalidPrayerCoordinatesException(
        'Invalid WGS84 coordinates: ($latitude, $longitude).',
        invalidValue: '$latitude,$longitude',
      );
    }

    final DateTime baseLocal = (localDate ?? DateTime.now()).toLocal();
    final DateTime calendarToday = DateTime(
      baseLocal.year,
      baseLocal.month,
      baseLocal.day,
    );
    // Calendar date arithmetic avoids 24-hour DST drift when advancing to tomorrow.
    final DateTime calendarTomorrow = DateTime(
      calendarToday.year,
      calendarToday.month,
      calendarToday.day + 1,
    );

    final method = CountryMethodResolver.resolveEffective(
      settings,
      isoCountryCode: isoCountryCode,
    );

    final adhan.CalculationParameters params = _buildParameters(
      method: method,
      madhab: settings.madhab,
      latitude: latitude,
      highLatitudeRuleOverride: highLatitudeRuleOverride,
    );

    final coordinates = adhan.Coordinates(latitude, longitude);

    final todayTimes = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents(
        calendarToday.year,
        calendarToday.month,
        calendarToday.day,
      ),
      params,
    );

    final tomorrowTimes = adhan.PrayerTimes(
      coordinates,
      adhan.DateComponents(
        calendarTomorrow.year,
        calendarTomorrow.month,
        calendarTomorrow.day,
      ),
      params,
    );

    return DailyPrayerTimes(
      localDate: calendarToday,
      method: method,
      madhab: settings.madhab,
      fajr: todayTimes.fajr,
      sunrise: todayTimes.sunrise,
      dhuhr: todayTimes.dhuhr,
      asr: todayTimes.asr,
      maghrib: todayTimes.maghrib,
      isha: todayTimes.isha,
      tomorrowFajr: tomorrowTimes.fajr,
    );
  }

  /// Resolves the next obligatory prayer relative to [now].
  ///
  /// Sunrise is explicitly excluded from obligatory next-prayer selection.
  /// After Isha, rolls over to tomorrow's Fajr.
  NextObligatoryPrayerInfo resolveNextObligatoryPrayer(
    DailyPrayerTimes today,
    DateTime now,
  ) {
    final localNow = now.toLocal();
    for (final event in today.obligatoryEvents) {
      if (event.time.isAfter(localNow)) {
        return NextObligatoryPrayerInfo(
          prayer: event.obligatoryPrayer!,
          time: event.time,
          isTomorrow: false,
          remaining: event.time.difference(localNow),
        );
      }
    }

    final remaining = today.tomorrowFajr.isAfter(localNow)
        ? today.tomorrowFajr.difference(localNow)
        : Duration.zero;

    return NextObligatoryPrayerInfo(
      prayer: ObligatoryPrayer.fajr,
      time: today.tomorrowFajr,
      isTomorrow: true,
      remaining: remaining,
    );
  }

  adhan.CalculationParameters _buildParameters({
    required PrayerCalculationMethod method,
    required PrayerMadhab madhab,
    required double latitude,
    adhan.HighLatitudeRule? highLatitudeRuleOverride,
  }) {
    final params = method.adhanMethod.getParameters();
    params.madhab = madhab.adhanMadhab;
    if (highLatitudeRuleOverride != null) {
      params.highLatitudeRule = highLatitudeRuleOverride;
    } else if (latitude.abs() >= 48.0) {
      params.highLatitudeRule = adhan.HighLatitudeRule.seventh_of_the_night;
    }
    return params;
  }
}

