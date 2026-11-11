import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/features/prayer/data/services/prayer_times_calculator.dart';
import 'package:adhkar/features/prayer/domain/entities/daily_prayer_times.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_calculation_method.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_madhab.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_settings.dart';

void main() {
  const calculator = PrayerTimesCalculator();

  group('PrayerTimesCalculator', () {
    test('calculates all six events in strict chronological order for Istanbul', () {
      final result = calculator.calculate(
        latitude: 41.0082,
        longitude: 28.9784,
        settings: PrayerSettings.defaults(),
        isoCountryCode: 'TR',
        localDate: DateTime(2026, 6, 15),
      );

      expect(result.method, PrayerCalculationMethod.turkey);
      expect(result.events.length, 6);
      expect(
        result.events.map((e) => e.type).toList(),
        [
          PrayerEventType.fajr,
          PrayerEventType.sunrise,
          PrayerEventType.dhuhr,
          PrayerEventType.asr,
          PrayerEventType.maghrib,
          PrayerEventType.isha,
        ],
      );

      for (int i = 1; i < result.events.length; i++) {
        expect(
          result.events[i].time.isAfter(result.events[i - 1].time),
          isTrue,
          reason: '${result.events[i].type} must be after ${result.events[i - 1].type}',
        );
      }

      expect(result.tomorrowFajr.isAfter(result.isha), isTrue);
    });

    test('Hanafi Asr is strictly later than Shafi Asr', () {
      final shafiTimes = calculator.calculate(
        latitude: 24.7136,
        longitude: 46.6753,
        settings: const PrayerSettings(madhab: PrayerMadhab.shafi),
        isoCountryCode: 'SA',
        localDate: DateTime(2026, 4, 10),
      );
      final hanafiTimes = calculator.calculate(
        latitude: 24.7136,
        longitude: 46.6753,
        settings: const PrayerSettings(madhab: PrayerMadhab.hanafi),
        isoCountryCode: 'SA',
        localDate: DateTime(2026, 4, 10),
      );

      expect(shafiTimes.method, PrayerCalculationMethod.ummAlQura);
      expect(hanafiTimes.asr.isAfter(shafiTimes.asr), isTrue);
    });

    test('rejects invalid coordinates (NaN, Infinity, out-of-range)', () {
      for (final pair in const [
        (double.nan, 28.0),
        (41.0, double.infinity),
        (90.1, 28.0),
        (-90.1, 28.0),
        (41.0, 180.1),
        (41.0, -180.1),
      ]) {
        expect(
          () => calculator.calculate(
            latitude: pair.$1,
            longitude: pair.$2,
            settings: PrayerSettings.defaults(),
            localDate: DateTime(2026, 5, 1),
          ),
          throwsA(isA<InvalidPrayerCoordinatesException>()),
        );
      }
    });

    test('next obligatory prayer excludes Sunrise and rolls over to tomorrow Fajr after Isha', () {
      final times = calculator.calculate(
        latitude: 30.0444,
        longitude: 31.2357,
        settings: PrayerSettings.defaults(),
        isoCountryCode: 'EG',
        localDate: DateTime(2026, 3, 20),
      );

      expect(times.method, PrayerCalculationMethod.egyptian);

      // Between Fajr and Sunrise: next obligatory prayer MUST be Dhuhr, NEVER Sunrise.
      final afterFajrBeforeSunrise = times.fajr.add(const Duration(minutes: 5));
      expect(afterFajrBeforeSunrise.isBefore(times.sunrise), isTrue);

      final nextFromMorning = calculator.resolveNextObligatoryPrayer(
        times,
        afterFajrBeforeSunrise,
      );
      expect(nextFromMorning.prayer, ObligatoryPrayer.dhuhr);
      expect(nextFromMorning.isTomorrow, isFalse);

      // After Isha: next obligatory prayer MUST be tomorrow's Fajr.
      final afterIsha = times.isha.add(const Duration(minutes: 10));
      final nextAfterIsha = calculator.resolveNextObligatoryPrayer(
        times,
        afterIsha,
      );
      expect(nextAfterIsha.prayer, ObligatoryPrayer.fajr);
      expect(nextAfterIsha.isTomorrow, isTrue);
      expect(nextAfterIsha.time, equals(times.tomorrowFajr));
    });

    test('handles calendar date transitions across year-end cleanly', () {
      final dec31 = calculator.calculate(
        latitude: 21.4225,
        longitude: 39.8262,
        settings: PrayerSettings.defaults(),
        isoCountryCode: 'SA',
        localDate: DateTime(2026, 12, 31),
      );
      final jan1 = calculator.calculate(
        latitude: 21.4225,
        longitude: 39.8262,
        settings: PrayerSettings.defaults(),
        isoCountryCode: 'SA',
        localDate: DateTime(2027, 1, 1),
      );

      expect(dec31.tomorrowFajr, equals(jan1.fajr));
    });

    test('handles high-latitude locations safely in summer solstice', () {
      final reykjavik = calculator.calculate(
        latitude: 64.1466,
        longitude: -21.9426,
        settings: PrayerSettings.defaults(),
        isoCountryCode: 'IS',
        localDate: DateTime(2026, 6, 21),
      );

      expect(reykjavik.method, PrayerCalculationMethod.muslimWorldLeague);
      for (int i = 1; i < reykjavik.events.length; i++) {
        expect(
          reykjavik.events[i].time.isAfter(reykjavik.events[i - 1].time) ||
              reykjavik.events[i].time.isAtSameMomentAs(
                reykjavik.events[i - 1].time,
              ),
          isTrue,
        );
      }
    });
  });
}

