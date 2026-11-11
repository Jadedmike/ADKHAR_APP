import '../entities/prayer_calculation_method.dart';
import '../entities/prayer_madhab.dart';

/// The five obligatory daily prayers (used for next-prayer logic and notifications).
enum ObligatoryPrayer {
  fajr('fajr', 'الفجر'),
  dhuhr('dhuhr', 'الظهر'),
  asr('asr', 'العصر'),
  maghrib('maghrib', 'المغرب'),
  isha('isha', 'العشاء');

  final String storageKey;
  final String arabicName;

  const ObligatoryPrayer(this.storageKey, this.arabicName);

  static ObligatoryPrayer? tryFromStorageKey(Object? key) {
    if (key is! String) return null;
    for (final prayer in values) {
      if (prayer.storageKey == key) return prayer;
    }
    return null;
  }
}

/// All six daily prayer-related events displayed in the Prayer Times screen.
enum PrayerEventType {
  fajr('الفجر', ObligatoryPrayer.fajr),
  sunrise('الشروق', null),
  dhuhr('الظهر', ObligatoryPrayer.dhuhr),
  asr('العصر', ObligatoryPrayer.asr),
  maghrib('المغرب', ObligatoryPrayer.maghrib),
  isha('العشاء', ObligatoryPrayer.isha);

  final String arabicName;
  final ObligatoryPrayer? obligatoryPrayer;

  const PrayerEventType(this.arabicName, this.obligatoryPrayer);

  bool get isObligatory => obligatoryPrayer != null;
}

/// A single calculated prayer event in local device time.
class PrayerEvent {
  final PrayerEventType type;
  final DateTime time;

  const PrayerEvent({required this.type, required this.time});

  String get arabicName => type.arabicName;
  bool get isObligatory => type.isObligatory;
  ObligatoryPrayer? get obligatoryPrayer => type.obligatoryPrayer;
}

/// Complete calculated prayer schedule for a local calendar day plus tomorrow's Fajr.
class DailyPrayerTimes {
  final DateTime localDate;
  final PrayerCalculationMethod method;
  final PrayerMadhab madhab;
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final DateTime tomorrowFajr;

  const DailyPrayerTimes({
    required this.localDate,
    required this.method,
    required this.madhab,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.tomorrowFajr,
  });

  /// All six events in chronological daily order.
  List<PrayerEvent> get events => [
    PrayerEvent(type: PrayerEventType.fajr, time: fajr),
    PrayerEvent(type: PrayerEventType.sunrise, time: sunrise),
    PrayerEvent(type: PrayerEventType.dhuhr, time: dhuhr),
    PrayerEvent(type: PrayerEventType.asr, time: asr),
    PrayerEvent(type: PrayerEventType.maghrib, time: maghrib),
    PrayerEvent(type: PrayerEventType.isha, time: isha),
  ];

  /// Only the five obligatory prayers in chronological order (never Sunrise).
  List<PrayerEvent> get obligatoryEvents => [
    PrayerEvent(type: PrayerEventType.fajr, time: fajr),
    PrayerEvent(type: PrayerEventType.dhuhr, time: dhuhr),
    PrayerEvent(type: PrayerEventType.asr, time: asr),
    PrayerEvent(type: PrayerEventType.maghrib, time: maghrib),
    PrayerEvent(type: PrayerEventType.isha, time: isha),
  ];

  /// Returns the local [DateTime] for an obligatory prayer.
  DateTime timeForObligatory(ObligatoryPrayer prayer) {
    switch (prayer) {
      case ObligatoryPrayer.fajr:
        return fajr;
      case ObligatoryPrayer.dhuhr:
        return dhuhr;
      case ObligatoryPrayer.asr:
        return asr;
      case ObligatoryPrayer.maghrib:
        return maghrib;
      case ObligatoryPrayer.isha:
        return isha;
    }
  }
}

/// Result of resolving the next obligatory prayer relative to a given local timestamp.
class NextObligatoryPrayerInfo {
  final ObligatoryPrayer prayer;
  final DateTime time;
  final bool isTomorrow;
  final Duration remaining;

  const NextObligatoryPrayerInfo({
    required this.prayer,
    required this.time,
    required this.isTomorrow,
    required this.remaining,
  });

  String get arabicName => prayer.arabicName;
}

