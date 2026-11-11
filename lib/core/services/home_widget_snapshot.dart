import 'dart:convert';
import '../../features/prayer/domain/entities/daily_prayer_times.dart';

/// Thrown when a widget snapshot fails schema or invariant validation.
class WidgetSnapshotValidationException implements Exception {
  final String message;

  const WidgetSnapshotValidationException(this.message);

  @override
  String toString() => 'WidgetSnapshotValidationException: $message';
}

/// Compact text entry used for daily Dhikr, Dua, Ayah, and Quote items.
class WidgetTextItem {
  final String text;
  final String source;
  final String categoryTitle;

  const WidgetTextItem({
    required this.text,
    required this.source,
    required this.categoryTitle,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'source': source,
      'categoryTitle': categoryTitle,
    };
  }

  static WidgetTextItem? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final text = raw['text'];
    final source = raw['source'];
    final categoryTitle = raw['categoryTitle'];
    if (text is! String || source is! String || categoryTitle is! String) {
      return null;
    }
    return WidgetTextItem(
      text: text,
      source: source,
      categoryTitle: categoryTitle,
    );
  }
}

/// Compact Adhkar entry extracted from existing morning/evening JSON assets.
class WidgetPeriodDhikrItem {
  final String id;
  final int order;
  final String text;
  final String source;
  final int count;
  final String countDescription;

  const WidgetPeriodDhikrItem({
    required this.id,
    required this.order,
    required this.text,
    required this.source,
    required this.count,
    required this.countDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'text': text,
      'source': source,
      'count': count,
      'countDescription': countDescription,
    };
  }

  static WidgetPeriodDhikrItem? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final order = raw['order'];
    final text = raw['text'];
    final source = raw['source'];
    final count = raw['count'];
    final countDescription = raw['countDescription'];
    if (id is! String ||
        order is! int ||
        text is! String ||
        source is! String ||
        count is! int ||
        countDescription is! String) {
      return null;
    }
    return WidgetPeriodDhikrItem(
      id: id,
      order: order,
      text: text,
      source: source,
      count: count,
      countDescription: countDescription,
    );
  }
}

/// Pre-selected daily Adhkar content for a specific local calendar date.
class WidgetDailyAdhkarDay {
  final String localDate;
  final WidgetTextItem dhikr;
  final WidgetTextItem dua;
  final WidgetTextItem ayah;
  final WidgetTextItem quote;

  const WidgetDailyAdhkarDay({
    required this.localDate,
    required this.dhikr,
    required this.dua,
    required this.ayah,
    required this.quote,
  });

  Map<String, dynamic> toJson() {
    return {
      'localDate': localDate,
      'dhikr': dhikr.toJson(),
      'dua': dua.toJson(),
      'ayah': ayah.toJson(),
      'quote': quote.toJson(),
    };
  }

  static WidgetDailyAdhkarDay? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final localDate = raw['localDate'];
    final dhikr = WidgetTextItem.tryFromJson(raw['dhikr']);
    final dua = WidgetTextItem.tryFromJson(raw['dua']);
    final ayah = WidgetTextItem.tryFromJson(raw['ayah']);
    final quote = WidgetTextItem.tryFromJson(raw['quote']);
    if (localDate is! String ||
        dhikr == null ||
        dua == null ||
        ayah == null ||
        quote == null) {
      return null;
    }
    return WidgetDailyAdhkarDay(
      localDate: localDate,
      dhikr: dhikr,
      dua: dua,
      ayah: ayah,
      quote: quote,
    );
  }
}

/// Morning and evening display cutoffs in local minutes since midnight.
class WidgetAdhkarCutoffs {
  final int morningStartMinutes;
  final int eveningStartMinutes;
  final String morningStartFormatted;
  final String eveningStartFormatted;
  final bool morningReminderEnabled;
  final bool eveningReminderEnabled;

  const WidgetAdhkarCutoffs({
    required this.morningStartMinutes,
    required this.eveningStartMinutes,
    required this.morningStartFormatted,
    required this.eveningStartFormatted,
    required this.morningReminderEnabled,
    required this.eveningReminderEnabled,
  });

  /// Resolves `'morning'` or `'evening'` for [localTime] using configured cutoffs.
  String resolvePeriod(DateTime localTime) {
    final minuteOfDay = (localTime.hour * 60) + localTime.minute;
    if (morningStartMinutes < eveningStartMinutes) {
      return (minuteOfDay >= morningStartMinutes &&
              minuteOfDay < eveningStartMinutes)
          ? 'morning'
          : 'evening';
    }
    if (morningStartMinutes > eveningStartMinutes) {
      return (minuteOfDay >= morningStartMinutes ||
              minuteOfDay < eveningStartMinutes)
          ? 'morning'
          : 'evening';
    }
    return 'morning';
  }

  Map<String, dynamic> toJson() {
    return {
      'morningStartMinutes': morningStartMinutes,
      'eveningStartMinutes': eveningStartMinutes,
      'morningStartFormatted': morningStartFormatted,
      'eveningStartFormatted': eveningStartFormatted,
      'morningReminderEnabled': morningReminderEnabled,
      'eveningReminderEnabled': eveningReminderEnabled,
    };
  }

  static WidgetAdhkarCutoffs? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final morningStartMinutes = raw['morningStartMinutes'];
    final eveningStartMinutes = raw['eveningStartMinutes'];
    final morningStartFormatted = raw['morningStartFormatted'];
    final eveningStartFormatted = raw['eveningStartFormatted'];
    final morningReminderEnabled = raw['morningReminderEnabled'];
    final eveningReminderEnabled = raw['eveningReminderEnabled'];
    if (morningStartMinutes is! int ||
        eveningStartMinutes is! int ||
        morningStartFormatted is! String ||
        eveningStartFormatted is! String ||
        morningReminderEnabled is! bool ||
        eveningReminderEnabled is! bool) {
      return null;
    }
    return WidgetAdhkarCutoffs(
      morningStartMinutes: morningStartMinutes,
      eveningStartMinutes: eveningStartMinutes,
      morningStartFormatted: morningStartFormatted,
      eveningStartFormatted: eveningStartFormatted,
      morningReminderEnabled: morningReminderEnabled,
      eveningReminderEnabled: eveningReminderEnabled,
    );
  }
}

/// Safe location metadata exposed to native widgets (never contains raw coordinates).
class WidgetLocationInfo {
  final bool hasSavedLocation;
  final String? locationFingerprint;
  final String? displayName;
  final String? isoCountryCode;
  final String? calculationMethodKey;
  final String? calculationMethodLabel;
  final String? madhabKey;
  final String? madhabLabel;
  final String missingLocationPrompt;

  const WidgetLocationInfo({
    required this.hasSavedLocation,
    this.locationFingerprint,
    this.displayName,
    this.isoCountryCode,
    this.calculationMethodKey,
    this.calculationMethodLabel,
    this.madhabKey,
    this.madhabLabel,
    this.missingLocationPrompt = WidgetSnapshot.missingLocationArabicPrompt,
  });

  Map<String, dynamic> toJson() {
    return {
      'hasSavedLocation': hasSavedLocation,
      'locationFingerprint': locationFingerprint,
      'displayName': displayName,
      'isoCountryCode': isoCountryCode,
      'calculationMethodKey': calculationMethodKey,
      'calculationMethodLabel': calculationMethodLabel,
      'madhabKey': madhabKey,
      'madhabLabel': madhabLabel,
      'missingLocationPrompt': missingLocationPrompt,
    };
  }

  static WidgetLocationInfo? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final hasSavedLocation = raw['hasSavedLocation'];
    final missingLocationPrompt = raw['missingLocationPrompt'];
    if (hasSavedLocation is! bool || missingLocationPrompt is! String) {
      return null;
    }
    return WidgetLocationInfo(
      hasSavedLocation: hasSavedLocation,
      locationFingerprint: raw['locationFingerprint'] as String?,
      displayName: raw['displayName'] as String?,
      isoCountryCode: raw['isoCountryCode'] as String?,
      calculationMethodKey: raw['calculationMethodKey'] as String?,
      calculationMethodLabel: raw['calculationMethodLabel'] as String?,
      madhabKey: raw['madhabKey'] as String?,
      madhabLabel: raw['madhabLabel'] as String?,
      missingLocationPrompt: missingLocationPrompt,
    );
  }
}

/// Pre-calculated prayer schedule for one local calendar date using UTC epoch ms.
class WidgetPrayerDaySchedule {
  final String localDate;
  final int fajrUtcEpochMs;
  final int sunriseUtcEpochMs;
  final int dhuhrUtcEpochMs;
  final int asrUtcEpochMs;
  final int maghribUtcEpochMs;
  final int ishaUtcEpochMs;
  final int tomorrowFajrUtcEpochMs;

  const WidgetPrayerDaySchedule({
    required this.localDate,
    required this.fajrUtcEpochMs,
    required this.sunriseUtcEpochMs,
    required this.dhuhrUtcEpochMs,
    required this.asrUtcEpochMs,
    required this.maghribUtcEpochMs,
    required this.ishaUtcEpochMs,
    required this.tomorrowFajrUtcEpochMs,
  });

  factory WidgetPrayerDaySchedule.fromDailyPrayerTimes(
    DailyPrayerTimes times,
    String localDate,
  ) {
    return WidgetPrayerDaySchedule(
      localDate: localDate,
      fajrUtcEpochMs: times.fajr.toUtc().millisecondsSinceEpoch,
      sunriseUtcEpochMs: times.sunrise.toUtc().millisecondsSinceEpoch,
      dhuhrUtcEpochMs: times.dhuhr.toUtc().millisecondsSinceEpoch,
      asrUtcEpochMs: times.asr.toUtc().millisecondsSinceEpoch,
      maghribUtcEpochMs: times.maghrib.toUtc().millisecondsSinceEpoch,
      ishaUtcEpochMs: times.isha.toUtc().millisecondsSinceEpoch,
      tomorrowFajrUtcEpochMs: times.tomorrowFajr.toUtc().millisecondsSinceEpoch,
    );
  }

  List<({ObligatoryPrayer prayer, int utcEpochMs})> get obligatoryEvents => [
    (prayer: ObligatoryPrayer.fajr, utcEpochMs: fajrUtcEpochMs),
    (prayer: ObligatoryPrayer.dhuhr, utcEpochMs: dhuhrUtcEpochMs),
    (prayer: ObligatoryPrayer.asr, utcEpochMs: asrUtcEpochMs),
    (prayer: ObligatoryPrayer.maghrib, utcEpochMs: maghribUtcEpochMs),
    (prayer: ObligatoryPrayer.isha, utcEpochMs: ishaUtcEpochMs),
  ];

  bool get hasStrictlyIncreasingTimes =>
      fajrUtcEpochMs > 0 &&
      fajrUtcEpochMs < sunriseUtcEpochMs &&
      sunriseUtcEpochMs < dhuhrUtcEpochMs &&
      dhuhrUtcEpochMs < asrUtcEpochMs &&
      asrUtcEpochMs < maghribUtcEpochMs &&
      maghribUtcEpochMs < ishaUtcEpochMs &&
      ishaUtcEpochMs < tomorrowFajrUtcEpochMs;

  Map<String, dynamic> toJson() {
    return {
      'localDate': localDate,
      'fajrUtcEpochMs': fajrUtcEpochMs,
      'sunriseUtcEpochMs': sunriseUtcEpochMs,
      'dhuhrUtcEpochMs': dhuhrUtcEpochMs,
      'asrUtcEpochMs': asrUtcEpochMs,
      'maghribUtcEpochMs': maghribUtcEpochMs,
      'ishaUtcEpochMs': ishaUtcEpochMs,
      'tomorrowFajrUtcEpochMs': tomorrowFajrUtcEpochMs,
    };
  }

  static WidgetPrayerDaySchedule? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final localDate = raw['localDate'];
    final fajr = raw['fajrUtcEpochMs'];
    final sunrise = raw['sunriseUtcEpochMs'];
    final dhuhr = raw['dhuhrUtcEpochMs'];
    final asr = raw['asrUtcEpochMs'];
    final maghrib = raw['maghribUtcEpochMs'];
    final isha = raw['ishaUtcEpochMs'];
    final tomorrowFajr = raw['tomorrowFajrUtcEpochMs'];
    if (localDate is! String ||
        fajr is! int ||
        sunrise is! int ||
        dhuhr is! int ||
        asr is! int ||
        maghrib is! int ||
        isha is! int ||
        tomorrowFajr is! int) {
      return null;
    }
    return WidgetPrayerDaySchedule(
      localDate: localDate,
      fajrUtcEpochMs: fajr,
      sunriseUtcEpochMs: sunrise,
      dhuhrUtcEpochMs: dhuhr,
      asrUtcEpochMs: asr,
      maghribUtcEpochMs: maghrib,
      ishaUtcEpochMs: isha,
      tomorrowFajrUtcEpochMs: tomorrowFajr,
    );
  }
}

/// Resolved next obligatory prayer computed strictly from pre-calculated timestamps.
class WidgetNextPrayerResolution {
  final ObligatoryPrayer prayer;
  final int targetUtcEpochMs;
  final bool isTomorrow;
  final WidgetPrayerDaySchedule activeSchedule;

  const WidgetNextPrayerResolution({
    required this.prayer,
    required this.targetUtcEpochMs,
    required this.isTomorrow,
    required this.activeSchedule,
  });

  String get arabicName => prayer.arabicName;
}

/// Versioned shared widget snapshot shared between Flutter and native widget hosts.
class WidgetSnapshot {
  static const int currentSchemaVersion = 1;
  static const int horizonDays = 7;

  /// Maximum age allowed when preserving an earlier valid prayer snapshot
  /// across transient calculation failures, provided it also covers today.
  static const Duration maxPreservedSnapshotAge = Duration(hours: 24);

  /// Maximum tolerated backward clock skew when validating snapshot age.
  static const Duration maxClockSkew = Duration(minutes: 5);

  static const String missingLocationArabicPrompt =
      'افتح التطبيق لتحديد الموقع';
  static const String prayerUnavailableArabicPrompt =
      'تعذر حساب مواقيت الصلاة حالياً';
  static const Set<String> validThemePreferences = {'light', 'dark', 'system'};
  static final RegExp _fingerprintPattern = RegExp(r'^[0-9a-f]{32}$');

  final int schemaVersion;
  final int generatedAtUtcEpochMs;
  final bool hasSavedLocation;
  final bool prayerDataAvailable;
  final String prayerUnavailablePrompt;
  final String themePreference;
  final String themeModeLabel;
  final WidgetLocationInfo location;
  final WidgetAdhkarCutoffs cutoffs;
  final List<WidgetDailyAdhkarDay> dailyAdhkarDays;
  final List<WidgetPeriodDhikrItem> morningAdhkar;
  final List<WidgetPeriodDhikrItem> eveningAdhkar;
  final List<WidgetPrayerDaySchedule> prayerDays;

  const WidgetSnapshot({
    this.schemaVersion = currentSchemaVersion,
    required this.generatedAtUtcEpochMs,
    required this.hasSavedLocation,
    required this.prayerDataAvailable,
    this.prayerUnavailablePrompt = prayerUnavailableArabicPrompt,
    required this.themePreference,
    required this.themeModeLabel,
    required this.location,
    required this.cutoffs,
    required this.dailyAdhkarDays,
    required this.morningAdhkar,
    required this.eveningAdhkar,
    required this.prayerDays,
  });

  /// Computes a stable, opaque, non-reversible 128-bit hex location identity
  /// without exposing or logging raw coordinates.
  static String computeLocationFingerprint({
    required double latitude,
    required double longitude,
    String? isoCountryCode,
  }) {
    final normalizedIso = (isoCountryCode ?? '').trim().toUpperCase();
    final canonical =
        'v1|${latitude.toStringAsFixed(6)}|${longitude.toStringAsFixed(6)}|$normalizedIso';
    final bytes = utf8.encode(canonical);

    const seeds = <int>[0x811C9DC5, 0x9E3779B9, 0xA5A5A5A5, 0x3C6EF372];
    const primes = <int>[0x01000193, 0x85EBCA6B, 0xC2B2AE35, 0x27D4EB2F];

    final buffer = StringBuffer();
    for (int lane = 0; lane < seeds.length; lane++) {
      int hash = seeds[lane];
      final prime = primes[lane];
      for (int i = 0; i < bytes.length; i++) {
        hash ^= (bytes[i] + lane * 31) & 0xFF;
        hash = (hash * prime) & 0xFFFFFFFF;
        hash ^= (hash >> 13);
      }
      // Final Murmur-style avalanche pass per 32-bit lane.
      hash ^= (hash >> 16);
      hash = (hash * 0x85EBCA6B) & 0xFFFFFFFF;
      hash ^= (hash >> 13);
      buffer.write(hash.toRadixString(16).padLeft(8, '0'));
    }
    return buffer.toString();
  }

  /// Formats a local calendar date as `YYYY-MM-DD`.
  static String formatLocalDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Resolves the daily Adhkar entry matching [localDate] (if in horizon).
  WidgetDailyAdhkarDay? dailyAdhkarForDate(DateTime localDate) {
    final targetKey = formatLocalDate(localDate);
    for (final day in dailyAdhkarDays) {
      if (day.localDate == targetKey) {
        return day;
      }
    }
    return null;
  }

  /// Resolves the active prayer schedule matching [localDate] (if in horizon).
  WidgetPrayerDaySchedule? prayerDayForDate(DateTime localDate) {
    final targetKey = formatLocalDate(localDate);
    for (final day in prayerDays) {
      if (day.localDate == targetKey) {
        return day;
      }
    }
    return null;
  }

  /// Checks whether this snapshot covers [localDate] across required horizons.
  bool coversLocalDate(DateTime localDate) {
    if (dailyAdhkarForDate(localDate) == null) {
      return false;
    }
    if (prayerDataAvailable && prayerDayForDate(localDate) == null) {
      return false;
    }
    return true;
  }

  /// Checks whether [generatedAtUtcEpochMs] is within [maxPreservedSnapshotAge]
  /// relative to [referenceNow].
  bool isFreshAt(DateTime referenceNow) {
    final nowUtcMs = referenceNow.toUtc().millisecondsSinceEpoch;
    final ageMs = nowUtcMs - generatedAtUtcEpochMs;
    return ageMs >= -maxClockSkew.inMilliseconds &&
        ageMs <= maxPreservedSnapshotAge.inMilliseconds;
  }

  /// Rebuilds safe non-prayer presentation fields while keeping existing
  /// validated prayer schedules, location identity, and `generatedAtUtcEpochMs`.
  WidgetSnapshot copyWithRefreshedNonPrayerFields({
    required String themePreference,
    required String themeModeLabel,
    required WidgetAdhkarCutoffs cutoffs,
    required List<WidgetDailyAdhkarDay> dailyAdhkarDays,
    required List<WidgetPeriodDhikrItem> morningAdhkar,
    required List<WidgetPeriodDhikrItem> eveningAdhkar,
  }) {
    return WidgetSnapshot(
      schemaVersion: schemaVersion,
      generatedAtUtcEpochMs: generatedAtUtcEpochMs,
      hasSavedLocation: hasSavedLocation,
      prayerDataAvailable: prayerDataAvailable,
      prayerUnavailablePrompt: prayerUnavailablePrompt,
      themePreference: themePreference,
      themeModeLabel: themeModeLabel,
      location: location,
      cutoffs: cutoffs,
      dailyAdhkarDays: dailyAdhkarDays,
      morningAdhkar: morningAdhkar,
      eveningAdhkar: eveningAdhkar,
      prayerDays: prayerDays,
    );
  }

  /// Resolves the next obligatory prayer at [now] without GPS or recalculation.
  ///
  /// Excludes Sunrise, handles timezone-shifted schedules across the 7-day
  /// horizon, and rolls over after Isha to the following day's Fajr.
  WidgetNextPrayerResolution? resolveNextObligatoryPrayer(DateTime now) {
    if (!hasSavedLocation || !prayerDataAvailable || prayerDays.isEmpty) {
      return null;
    }

    final localNow = now.toLocal();
    final nowUtcMs = now.toUtc().millisecondsSinceEpoch;
    final todayKey = formatLocalDate(localNow);
    final currentDaySchedule = prayerDayForDate(localNow);

    for (final schedule in prayerDays) {
      for (final event in schedule.obligatoryEvents) {
        if (event.utcEpochMs > nowUtcMs) {
          return WidgetNextPrayerResolution(
            prayer: event.prayer,
            targetUtcEpochMs: event.utcEpochMs,
            isTomorrow: schedule.localDate != todayKey,
            activeSchedule: currentDaySchedule ?? schedule,
          );
        }
      }
    }

    final lastSchedule = prayerDays.last;
    if (lastSchedule.tomorrowFajrUtcEpochMs > nowUtcMs) {
      return WidgetNextPrayerResolution(
        prayer: ObligatoryPrayer.fajr,
        targetUtcEpochMs: lastSchedule.tomorrowFajrUtcEpochMs,
        isTomorrow: true,
        activeSchedule: currentDaySchedule ?? lastSchedule,
      );
    }

    return null;
  }

  /// Validates schema version, data integrity, and missing-location invariants.
  void validate() {
    if (schemaVersion != currentSchemaVersion) {
      throw WidgetSnapshotValidationException(
        'Unsupported schemaVersion: $schemaVersion.',
      );
    }
    if (generatedAtUtcEpochMs <= 0) {
      throw const WidgetSnapshotValidationException(
        'generatedAtUtcEpochMs must be positive.',
      );
    }
    if (hasSavedLocation != location.hasSavedLocation) {
      throw const WidgetSnapshotValidationException(
        'Top-level hasSavedLocation must match location.hasSavedLocation.',
      );
    }
    if (prayerDataAvailable && !hasSavedLocation) {
      throw const WidgetSnapshotValidationException(
        'prayerDataAvailable cannot be true when hasSavedLocation is false.',
      );
    }
    if (prayerUnavailablePrompt.trim().isEmpty) {
      throw const WidgetSnapshotValidationException(
        'prayerUnavailablePrompt must not be empty.',
      );
    }
    if (!validThemePreferences.contains(themePreference) ||
        themeModeLabel.trim().isEmpty) {
      throw WidgetSnapshotValidationException(
        'Invalid themePreference: $themePreference.',
      );
    }
    if (cutoffs.morningStartMinutes < 0 ||
        cutoffs.morningStartMinutes >= 1440 ||
        cutoffs.eveningStartMinutes < 0 ||
        cutoffs.eveningStartMinutes >= 1440) {
      throw const WidgetSnapshotValidationException(
        'Morning/evening cutoff minutes must be within 0..1439.',
      );
    }
    if (dailyAdhkarDays.length != horizonDays) {
      throw WidgetSnapshotValidationException(
        'dailyAdhkarDays must contain exactly $horizonDays days.',
      );
    }

    final datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    DateTime? previousDailyDate;
    for (final day in dailyAdhkarDays) {
      if (!datePattern.hasMatch(day.localDate)) {
        throw WidgetSnapshotValidationException(
          'Invalid dailyAdhkarDays localDate: ${day.localDate}.',
        );
      }
      final parsedDate = DateTime.parse(day.localDate);
      if (previousDailyDate != null) {
        final expectedDate = DateTime(
          previousDailyDate.year,
          previousDailyDate.month,
          previousDailyDate.day + 1,
        );
        if (parsedDate != expectedDate) {
          throw WidgetSnapshotValidationException(
            'dailyAdhkarDays dates must be strictly consecutive: ${day.localDate}.',
          );
        }
      }
      previousDailyDate = parsedDate;

      if (day.dhikr.text.trim().isEmpty ||
          day.dua.text.trim().isEmpty ||
          day.ayah.text.trim().isEmpty ||
          day.quote.text.trim().isEmpty) {
        throw const WidgetSnapshotValidationException(
          'Daily Adhkar text items must be non-empty.',
        );
      }
    }

    for (final item in [...morningAdhkar, ...eveningAdhkar]) {
      if (item.text.trim().isEmpty || item.count < 1) {
        throw const WidgetSnapshotValidationException(
          'Morning/evening Adhkar items must contain non-empty text and count >= 1.',
        );
      }
    }

    if (location.missingLocationPrompt.trim().isEmpty) {
      throw const WidgetSnapshotValidationException(
        'missingLocationPrompt must not be empty.',
      );
    }

    if (!hasSavedLocation) {
      if (prayerDays.isNotEmpty) {
        throw const WidgetSnapshotValidationException(
          'prayerDays must be empty when hasSavedLocation is false.',
        );
      }
      if (location.locationFingerprint != null ||
          (location.displayName != null &&
              location.displayName!.trim().isNotEmpty)) {
        throw const WidgetSnapshotValidationException(
          'Location identity metadata must not be set when hasSavedLocation is false.',
        );
      }
      return;
    }

    final fingerprint = location.locationFingerprint;
    if (fingerprint == null || !_fingerprintPattern.hasMatch(fingerprint)) {
      throw const WidgetSnapshotValidationException(
        'Valid opaque locationFingerprint must be present when hasSavedLocation is true.',
      );
    }
    if (location.displayName == null || location.displayName!.trim().isEmpty) {
      throw const WidgetSnapshotValidationException(
        'displayName must be present when hasSavedLocation is true.',
      );
    }
    if (location.calculationMethodKey == null ||
        location.calculationMethodKey!.trim().isEmpty ||
        location.calculationMethodLabel == null ||
        location.calculationMethodLabel!.trim().isEmpty ||
        location.madhabKey == null ||
        location.madhabKey!.trim().isEmpty ||
        location.madhabLabel == null ||
        location.madhabLabel!.trim().isEmpty) {
      throw const WidgetSnapshotValidationException(
        'Calculation method and madhab identity metadata must be present when hasSavedLocation is true.',
      );
    }

    if (!prayerDataAvailable) {
      if (prayerDays.isNotEmpty) {
        throw const WidgetSnapshotValidationException(
          'prayerDays must be empty when prayerDataAvailable is false.',
        );
      }
      return;
    }

    if (prayerDays.length != horizonDays) {
      throw WidgetSnapshotValidationException(
        'prayerDays must contain exactly $horizonDays days when prayerDataAvailable is true.',
      );
    }

    DateTime? previousPrayerDate;
    for (final day in prayerDays) {
      if (!datePattern.hasMatch(day.localDate)) {
        throw WidgetSnapshotValidationException(
          'Invalid prayerDays localDate: ${day.localDate}.',
        );
      }
      final parsedDate = DateTime.parse(day.localDate);
      if (previousPrayerDate != null) {
        final expectedDate = DateTime(
          previousPrayerDate.year,
          previousPrayerDate.month,
          previousPrayerDate.day + 1,
        );
        if (parsedDate != expectedDate) {
          throw WidgetSnapshotValidationException(
            'prayerDays dates must be strictly consecutive: ${day.localDate}.',
          );
        }
      }
      previousPrayerDate = parsedDate;

      if (!day.hasStrictlyIncreasingTimes) {
        throw WidgetSnapshotValidationException(
          'Prayer timestamps for ${day.localDate} are invalid or out of chronological order.',
        );
      }
    }
  }

  /// Serializes this snapshot to JSON.
  ///
  /// When [includeGeneratedAt] is `false`, produces a stable semantic payload
  /// suitable for duplicate-write detection across unchanged refreshes.
  Map<String, dynamic> toJson({bool includeGeneratedAt = true}) {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      if (includeGeneratedAt) 'generatedAtUtcEpochMs': generatedAtUtcEpochMs,
      'hasSavedLocation': hasSavedLocation,
      'prayerDataAvailable': prayerDataAvailable,
      'prayerUnavailablePrompt': prayerUnavailablePrompt,
      'themePreference': themePreference,
      'themeModeLabel': themeModeLabel,
      'location': location.toJson(),
      'cutoffs': cutoffs.toJson(),
      'dailyAdhkarDays': dailyAdhkarDays.map((e) => e.toJson()).toList(),
      'morningAdhkar': morningAdhkar.map((e) => e.toJson()).toList(),
      'eveningAdhkar': eveningAdhkar.map((e) => e.toJson()).toList(),
      'prayerDays': prayerDays.map((e) => e.toJson()).toList(),
    };
  }

  /// Validates invariants and encodes this snapshot as JSON.
  String toEncodedJson() {
    validate();
    return jsonEncode(toJson(includeGeneratedAt: true));
  }

  /// Encodes the deterministic semantic payload excluding timestamp jitter.
  String toSemanticSignatureJson() {
    return jsonEncode(toJson(includeGeneratedAt: false));
  }

  /// Parses and validates an encoded snapshot JSON string, returning `null`
  /// if malformed, unsupported in schemaVersion, or invariant-invalid.
  static WidgetSnapshot? tryFromEncodedJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final schemaVersion = decoded['schemaVersion'];
      final generatedAt = decoded['generatedAtUtcEpochMs'];
      final hasSavedLocation = decoded['hasSavedLocation'];
      final prayerDataAvailable = decoded['prayerDataAvailable'];
      final prayerUnavailablePrompt = decoded['prayerUnavailablePrompt'];
      final themePreference = decoded['themePreference'];
      final themeModeLabel = decoded['themeModeLabel'];
      final location = WidgetLocationInfo.tryFromJson(decoded['location']);
      final cutoffs = WidgetAdhkarCutoffs.tryFromJson(decoded['cutoffs']);
      final rawDaily = decoded['dailyAdhkarDays'];
      final rawMorning = decoded['morningAdhkar'];
      final rawEvening = decoded['eveningAdhkar'];
      final rawPrayers = decoded['prayerDays'];

      if (schemaVersion is! int ||
          schemaVersion != currentSchemaVersion ||
          generatedAt is! int ||
          hasSavedLocation is! bool ||
          prayerDataAvailable is! bool ||
          prayerUnavailablePrompt is! String ||
          themePreference is! String ||
          themeModeLabel is! String ||
          location == null ||
          cutoffs == null ||
          rawDaily is! List ||
          rawMorning is! List ||
          rawEvening is! List ||
          rawPrayers is! List) {
        return null;
      }

      final dailyAdhkarDays = <WidgetDailyAdhkarDay>[];
      for (final item in rawDaily) {
        final parsed = WidgetDailyAdhkarDay.tryFromJson(item);
        if (parsed == null) return null;
        dailyAdhkarDays.add(parsed);
      }

      final morningAdhkar = <WidgetPeriodDhikrItem>[];
      for (final item in rawMorning) {
        final parsed = WidgetPeriodDhikrItem.tryFromJson(item);
        if (parsed == null) return null;
        morningAdhkar.add(parsed);
      }

      final eveningAdhkar = <WidgetPeriodDhikrItem>[];
      for (final item in rawEvening) {
        final parsed = WidgetPeriodDhikrItem.tryFromJson(item);
        if (parsed == null) return null;
        eveningAdhkar.add(parsed);
      }

      final prayerDays = <WidgetPrayerDaySchedule>[];
      for (final item in rawPrayers) {
        final parsed = WidgetPrayerDaySchedule.tryFromJson(item);
        if (parsed == null) return null;
        prayerDays.add(parsed);
      }

      final snapshot = WidgetSnapshot(
        schemaVersion: schemaVersion,
        generatedAtUtcEpochMs: generatedAt,
        hasSavedLocation: hasSavedLocation,
        prayerDataAvailable: prayerDataAvailable,
        prayerUnavailablePrompt: prayerUnavailablePrompt,
        themePreference: themePreference,
        themeModeLabel: themeModeLabel,
        location: location,
        cutoffs: cutoffs,
        dailyAdhkarDays: dailyAdhkarDays,
        morningAdhkar: morningAdhkar,
        eveningAdhkar: eveningAdhkar,
        prayerDays: prayerDays,
      );
      snapshot.validate();
      return snapshot;
    } catch (_) {
      return null;
    }
  }
}
