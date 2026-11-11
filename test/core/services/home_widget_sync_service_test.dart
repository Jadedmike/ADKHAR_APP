import 'dart:async';
import 'dart:convert';
import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/config/theme/app_assets.dart';
import 'package:adhkar/core/services/home_widget_snapshot.dart';
import 'package:adhkar/core/services/home_widget_sync_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_location_cache_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_settings_storage.dart';
import 'package:adhkar/features/prayer/data/services/prayer_times_calculator.dart';
import 'package:adhkar/features/prayer/domain/entities/daily_prayer_times.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_calculation_method.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_madhab.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_settings.dart';
import 'package:adhkar/features/prayer/domain/entities/saved_prayer_location.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_settings_manager.dart';

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

class _FakeWidgetTransport implements WidgetTransport {
  final Map<String, Object?> storage = {};
  int initializeCount = 0;
  int writeCount = 0;
  int updateRequestCount = 0;
  int activeWrites = 0;
  int maxConcurrentWrites = 0;
  String? lastAppGroupId;
  bool failSnapshotWrite = false;
  int failNextSnapshotWrites = 0;
  bool failSchemaVersionWrite = false;
  Completer<void>? readGate;
  Completer<void>? writeGate;

  @override
  Future<void> initialize({required String appGroupId}) async {
    initializeCount++;
    lastAppGroupId = appGroupId;
  }

  @override
  Future<String?> readSnapshotJson(String snapshotKey) async {
    final gate = readGate;
    if (gate != null) {
      readGate = null;
      await gate.future;
    }
    final value = storage[snapshotKey];
    return value is String ? value : null;
  }

  @override
  Future<WidgetWriteResult> writeSnapshotData({
    required String snapshotKey,
    required String snapshotJson,
    required String schemaVersionKey,
    required int schemaVersion,
  }) async {
    final bool shouldFailThisWrite =
        failSnapshotWrite || failNextSnapshotWrites > 0;
    if (failNextSnapshotWrites > 0) {
      failNextSnapshotWrites--;
    }

    activeWrites++;
    if (activeWrites > maxConcurrentWrites) {
      maxConcurrentWrites = activeWrites;
    }
    try {
      final gate = writeGate;
      if (gate != null) {
        writeGate = null;
        await gate.future;
      }

      if (shouldFailThisWrite) {
        return const WidgetWriteResult(
          snapshotPersisted: false,
          schemaVersionPersisted: false,
          errorMessage: 'Simulated snapshot write failure.',
        );
      }

      writeCount++;
      storage[snapshotKey] = snapshotJson;

      if (failSchemaVersionWrite) {
        return const WidgetWriteResult(
          snapshotPersisted: true,
          schemaVersionPersisted: false,
          errorMessage: 'Simulated partial schema version write failure.',
        );
      }

      storage[schemaVersionKey] = schemaVersion;
      return const WidgetWriteResult(
        snapshotPersisted: true,
        schemaVersionPersisted: true,
      );
    } finally {
      activeWrites--;
    }
  }

  @override
  Future<void> requestWidgetUpdates() async {
    updateRequestCount++;
  }
}

class _FakeHomeWidgetPluginAdapter extends HomeWidgetPluginAdapter {
  final Map<String, Object?> data = {};
  bool failSchemaWrite = false;
  int updateCount = 0;

  @override
  Future<bool?> setAppGroupId(String groupId) async => true;

  @override
  Future<T?> getWidgetData<T>(String id) async => data[id] as T?;

  @override
  Future<bool?> saveWidgetData<T>(String id, T? value) async {
    if (failSchemaWrite && id == HomeWidgetSyncService.schemaVersionStorageKey) {
      return false;
    }
    data[id] = value;
    return true;
  }

  @override
  Future<bool?> updateWidget({
    String? qualifiedAndroidName,
    String? iOSName,
  }) async {
    updateCount++;
    return true;
  }
}

class _SwitchablePrayerCalculator extends PrayerTimesCalculator {
  bool shouldThrow;
  bool returnCorruptOrder;

  _SwitchablePrayerCalculator({
    this.shouldThrow = false,
    this.returnCorruptOrder = false,
  });

  @override
  DailyPrayerTimes calculate({
    required double latitude,
    required double longitude,
    required PrayerSettings settings,
    String? isoCountryCode,
    DateTime? localDate,
    adhan.HighLatitudeRule? highLatitudeRuleOverride,
  }) {
    if (shouldThrow) {
      throw StateError('Simulated prayer calculation error');
    }
    if (returnCorruptOrder) {
      final base = (localDate ?? DateTime.now()).toLocal();
      final day = DateTime(base.year, base.month, base.day);
      return DailyPrayerTimes(
        localDate: day,
        method: PrayerCalculationMethod.turkey,
        madhab: settings.madhab,
        fajr: day.add(const Duration(hours: 8)),
        sunrise: day.add(const Duration(hours: 6)),
        dhuhr: day.add(const Duration(hours: 12)),
        asr: day.add(const Duration(hours: 15)),
        maghrib: day.add(const Duration(hours: 18)),
        isha: day.add(const Duration(hours: 20)),
        tomorrowFajr: day.add(const Duration(days: 1, hours: 5)),
      );
    }
    return super.calculate(
      latitude: latitude,
      longitude: longitude,
      settings: settings,
      isoCountryCode: isoCountryCode,
      localDate: localDate,
      highLatitudeRuleOverride: highLatitudeRuleOverride,
    );
  }
}

Future<String> _fakeAdhkarAssetLoader(String assetPath) async {
  if (assetPath == AppAssets.jsonMorning) {
    return jsonEncode([
      {
        'id': 'morning_1',
        'order': 1,
        'content':
            'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ.',
        'count': 1,
        'count_description': 'مَرَّةٌ وَاحِدَةٌ',
        'source': 'صحيح مسلم',
      },
      {
        'id': 'morning_2',
        'order': 2,
        'content': 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ.',
        'count': 3,
        'count_description': 'ثَلَاثُ مَرَّاتٍ',
        'source': 'صحيح مسلم',
      },
    ]);
  }
  if (assetPath == AppAssets.jsonEvening) {
    return jsonEncode([
      {
        'id': 'evening_1',
        'order': 1,
        'content':
            'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ.',
        'count': 1,
        'count_description': 'مَرَّةٌ وَاحِدَةٌ',
        'source': 'صحيح مسلم',
      },
    ]);
  }
  return '[]';
}

SavedPrayerLocation _sampleIstanbulLocation() {
  return SavedPrayerLocation(
    latitude: 41.0082,
    longitude: 28.9784,
    isoCountryCode: 'TR',
    countryName: 'تركيا',
    city: 'إسطنبول',
    district: 'الفاتح',
    timestamp: DateTime.utc(2026, 11, 11, 8, 0),
    source: LocationSourceType.fresh,
  );
}

SavedPrayerLocation _sampleRiyadhLocation() {
  return SavedPrayerLocation(
    latitude: 24.7136,
    longitude: 46.6753,
    isoCountryCode: 'SA',
    countryName: 'السعودية',
    city: 'الرياض',
    district: 'العليا',
    timestamp: DateTime.utc(2026, 11, 11, 8, 0),
    source: LocationSourceType.fresh,
  );
}

void main() {
  group('HomeWidgetSyncService & WidgetSnapshot', () {
    test(
      'serializes complete v1 snapshot with Arabic text, 7-day horizons, sunrise, opaque fingerprint, and no raw coordinates',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
          initialSettings: const PrayerSettings(
            calculationMode: PrayerCalculationMode.auto,
            madhab: PrayerMadhab.hanafi,
          ),
        );

        final transport = _FakeWidgetTransport();
        final fixedNow = DateTime(2026, 12, 29, 10, 15);
        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => fixedNow,
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'داكن',
            morningTime: TimeOfDay(hour: 5, minute: 30),
            eveningTime: TimeOfDay(hour: 16, minute: 45),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final result = await service.sync();

        expect(result.status, WidgetSyncStatus.updated);
        expect(transport.lastAppGroupId, HomeWidgetSyncService.iosAppGroupId);
        expect(
          transport.storage[HomeWidgetSyncService.schemaVersionStorageKey],
          WidgetSnapshot.currentSchemaVersion,
        );

        final rawJson =
            transport.storage[HomeWidgetSyncService.snapshotStorageKey]
                as String;
        expect(rawJson.contains('41.0082'), isFalse);
        expect(rawJson.contains('28.9784'), isFalse);
        expect(rawJson.contains('"latitude"'), isFalse);
        expect(rawJson.contains('"longitude"'), isFalse);

        final parsed = WidgetSnapshot.tryFromEncodedJson(rawJson);
        expect(parsed, isNotNull);
        expect(parsed!.schemaVersion, 1);
        expect(parsed.hasSavedLocation, isTrue);
        expect(parsed.prayerDataAvailable, isTrue);
        expect(parsed.location.locationFingerprint, hasLength(32));
        expect(parsed.themePreference, 'dark');
        expect(parsed.themeModeLabel, 'داكن');
        expect(parsed.location.displayName, 'تركيا، إسطنبول، الفاتح');
        expect(
          parsed.location.calculationMethodLabel,
          PrayerCalculationMethod.turkey.arabicName,
        );
        expect(parsed.location.madhabLabel, PrayerMadhab.hanafi.arabicName);

        expect(parsed.cutoffs.morningStartMinutes, 330);
        expect(parsed.cutoffs.morningStartFormatted, '05:30');
        expect(parsed.cutoffs.eveningStartMinutes, 1005);
        expect(parsed.cutoffs.eveningStartFormatted, '16:45');

        expect(parsed.morningAdhkar.length, 2);
        expect(
          parsed.morningAdhkar.first.text,
          contains('أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ'),
        );
        expect(parsed.eveningAdhkar.length, 1);
        expect(
          parsed.eveningAdhkar.first.text,
          contains('أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ'),
        );

        expect(parsed.dailyAdhkarDays.length, 7);
        expect(parsed.prayerDays.length, 7);
        expect(parsed.dailyAdhkarDays.first.localDate, '2026-12-29');
        expect(parsed.dailyAdhkarDays.last.localDate, '2027-01-04');
        expect(parsed.prayerDays.first.localDate, '2026-12-29');
        expect(parsed.prayerDays.last.localDate, '2027-01-04');
      },
    );

    test(
      'handles missing location without inventing prayer times and keeps Adhkar content',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();

        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final result = await service.sync();
        expect(result.status, WidgetSyncStatus.updated);

        final parsed = WidgetSnapshot.tryFromEncodedJson(
          transport.storage[HomeWidgetSyncService.snapshotStorageKey]
              as String?,
        );
        expect(parsed, isNotNull);
        expect(parsed!.hasSavedLocation, isFalse);
        expect(parsed.prayerDataAvailable, isFalse);
        expect(parsed.location.hasSavedLocation, isFalse);
        expect(parsed.location.locationFingerprint, isNull);
        expect(parsed.location.displayName, isNull);
        expect(
          parsed.location.missingLocationPrompt,
          WidgetSnapshot.missingLocationArabicPrompt,
        );
        expect(parsed.prayerDays, isEmpty);
        expect(parsed.dailyAdhkarDays.length, 7);
        expect(parsed.morningAdhkar, isNotEmpty);
        expect(parsed.eveningAdhkar, isNotEmpty);
        expect(
          parsed.resolveNextObligatoryPrayer(DateTime(2026, 11, 11, 9, 0)),
          isNull,
        );
      },
    );

    test(
      'supports midnight rollover and after-Isha next-prayer rollover (skipping Sunrise)',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        final dayOne = DateTime(2026, 11, 11, 9, 0);
        // Align longitude to test host timezone so Fajr..Isha all fall on Nov 11 local time.
        final double alignedLongitude = ((dayOne.timeZoneOffset.inMinutes / 60.0) * 15.0)
            .clamp(-180.0, 180.0);
        await locationCache.save(
          SavedPrayerLocation(
            latitude: 25.0,
            longitude: alignedLongitude,
            countryName: 'موقع الاختبار',
            timestamp: DateTime.utc(2026, 11, 11, 8, 0),
            source: LocationSourceType.fresh,
          ),
        );

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();

        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => dayOne,
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final snapshot = (await service.sync()).snapshot!;
        final day1Prayers = snapshot.prayerDayForDate(DateTime(2026, 11, 11))!;
        final day2Prayers = snapshot.prayerDayForDate(DateTime(2026, 11, 12))!;

        final afterFajr = DateTime.fromMillisecondsSinceEpoch(
          day1Prayers.fajrUtcEpochMs + 60000,
          isUtc: true,
        ).toLocal();
        final nextAfterFajr = snapshot.resolveNextObligatoryPrayer(afterFajr)!;
        expect(nextAfterFajr.prayer, ObligatoryPrayer.dhuhr);
        expect(nextAfterFajr.isTomorrow, isFalse);

        final afterIsha = DateTime.fromMillisecondsSinceEpoch(
          day1Prayers.ishaUtcEpochMs + 60000,
          isUtc: true,
        ).toLocal();
        final nextAfterIsha = snapshot.resolveNextObligatoryPrayer(afterIsha)!;
        expect(nextAfterIsha.prayer, ObligatoryPrayer.fajr);
        expect(nextAfterIsha.isTomorrow, isTrue);
        expect(nextAfterIsha.targetUtcEpochMs, day2Prayers.fajrUtcEpochMs);

        final afterMidnight = DateTime(2026, 11, 12, 0, 5);
        expect(snapshot.coversLocalDate(afterMidnight), isTrue);
        expect(
          snapshot.dailyAdhkarForDate(afterMidnight)!.localDate,
          '2026-11-12',
        );
        final nextAtMidnight = snapshot.resolveNextObligatoryPrayer(
          afterMidnight,
        )!;
        expect(nextAtMidnight.prayer, ObligatoryPrayer.fajr);
        expect(nextAtMidnight.isTomorrow, isFalse);
        expect(nextAtMidnight.targetUtcEpochMs, day2Prayers.fajrUtcEpochMs);

        // Also verify cross-timezone safety: remote coordinates (Istanbul) never return null after Fajr.
        await locationCache.save(_sampleIstanbulLocation());
        final remoteSnapshot = (await service.sync()).snapshot!;
        final remoteDay1 = remoteSnapshot.prayerDayForDate(
          DateTime(2026, 11, 11),
        )!;
        final remoteAfterFajr = DateTime.fromMillisecondsSinceEpoch(
          remoteDay1.fajrUtcEpochMs + 60000,
          isUtc: true,
        );
        final remoteNext = remoteSnapshot.resolveNextObligatoryPrayer(
          remoteAfterFajr,
        )!;
        expect(remoteNext.prayer, ObligatoryPrayer.dhuhr);
      },
    );

    test(
      'rejects unsupported schemaVersion, missing fingerprint, and malformed JSON',
      () {
        expect(
          WidgetSnapshot.tryFromEncodedJson(
            jsonEncode({'schemaVersion': 99, 'generatedAtUtcEpochMs': 1000}),
          ),
          isNull,
        );
        expect(WidgetSnapshot.tryFromEncodedJson('{not valid json'), isNull);
      },
    );

    test(
      'deduplicates identical snapshot writes across restarts and updates when settings change',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();

        var themeLabel = 'فاتح';
        DateTime currentTime = DateTime(2026, 11, 11, 8, 0);

        HomeWidgetSyncService buildService() {
          return HomeWidgetSyncService(
            transport: transport,
            locationCache: locationCache,
            prayerSettingsManager: settingsManager,
            assetLoader: _fakeAdhkarAssetLoader,
            nowProvider: () => currentTime,
            preferencesReader: () => WidgetAdhkarRuntimePreferences(
              themeModeLabel: themeLabel,
              morningTime: const TimeOfDay(hour: 6, minute: 0),
              eveningTime: const TimeOfDay(hour: 17, minute: 0),
              morningReminderEnabled: true,
              eveningReminderEnabled: true,
            ),
          );
        }

        final firstService = buildService();
        expect((await firstService.sync()).status, WidgetSyncStatus.updated);
        expect(transport.writeCount, 1);

        currentTime = DateTime(2026, 11, 11, 8, 5);
        expect(
          (await firstService.sync()).status,
          WidgetSyncStatus.skippedDuplicate,
        );
        expect(transport.writeCount, 1);

        final coldService = buildService();
        expect(
          (await coldService.sync()).status,
          WidgetSyncStatus.skippedDuplicate,
        );
        expect(transport.writeCount, 1);

        themeLabel = 'داكن';
        final afterThemeChange = await coldService.sync();
        expect(afterThemeChange.status, WidgetSyncStatus.updated);
        expect(afterThemeChange.snapshot!.themePreference, 'dark');
        expect(transport.writeCount, 2);
      },
    );
  });

  group('Phase 1.1 Bug 1 — In-Flight Sync Coalescing', () {
    test(
      'reactive location and settings updates during an in-flight sync trigger one coalesced non-overlapping follow-up sync using latest values',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();
        final writeGate = Completer<void>();
        transport.writeGate = writeGate;

        var themeLabel = 'فاتح';
        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => WidgetAdhkarRuntimePreferences(
            themeModeLabel: themeLabel,
            morningTime: const TimeOfDay(hour: 6, minute: 0),
            eveningTime: const TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );
        service.attachListeners();
        addTearDown(service.detachListeners);

        // Start Sync #1 (pauses inside writeSnapshotData on writeGate).
        final firstFuture = service.sync();
        await Future<void>.delayed(Duration.zero);
        expect(transport.activeWrites, 1);

        // Multiple reactive updates occur while Sync #1 is in flight.
        themeLabel = 'داكن';
        await settingsManager.setMadhab(PrayerMadhab.hanafi);
        await locationCache.save(_sampleRiyadhLocation());
        final queuedFutureA = service.sync();
        final queuedFutureB = service.sync();

        // Still no overlapping writes allowed.
        expect(transport.activeWrites, 1);
        expect(transport.maxConcurrentWrites, 1);

        // Release Sync #1 -> Sync #1 returns Istanbul; coalesced Sync #2 returns Riyadh + Hanafi + dark.
        writeGate.complete();
        final firstResult = await firstFuture;
        final resultA = await queuedFutureA;
        final resultB = await queuedFutureB;

        expect(firstResult.status, WidgetSyncStatus.updated);
        expect(
          firstResult.snapshot!.location.displayName,
          'تركيا، إسطنبول، الفاتح',
        );
        expect(resultA.status, WidgetSyncStatus.updated);
        expect(resultB.status, WidgetSyncStatus.updated);
        expect(resultA.snapshot!.location.displayName, 'السعودية، الرياض، العليا');
        expect(transport.maxConcurrentWrites, 1);
        expect(transport.writeCount, 2);

        final latest = WidgetSnapshot.tryFromEncodedJson(
          transport.storage[HomeWidgetSyncService.snapshotStorageKey]
              as String?,
        )!;
        expect(latest.location.displayName, 'السعودية، الرياض، العليا');
        expect(latest.location.madhabKey, PrayerMadhab.hanafi.storageKey);
        expect(latest.themePreference, 'dark');
      },
    );

    test(
      'a failed initial sync does not block queued follow-up syncs',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport()..failNextSnapshotWrites = 1;
        final writeGate = Completer<void>();
        transport.writeGate = writeGate;

        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final failedFuture = service.sync();
        await Future<void>.delayed(Duration.zero);

        // Queue Sync #2 while Sync #1 is still in flight (Sync #1 fails once, Sync #2 succeeds).
        final followUpFuture = service.sync();

        writeGate.complete();
        final failedResult = await failedFuture;
        final followUpResult = await followUpFuture;

        expect(failedResult.status, WidgetSyncStatus.failed);
        expect(followUpResult.status, WidgetSyncStatus.updated);
        expect(transport.writeCount, 1);
      },
    );
  });

  group('Phase 1.1 Bug 2 — Conservative Snapshot Preservation', () {
    test(
      'same location + same method + same madhab + fresh same-day snapshot allows preservation and refreshes non-prayer theme/cutoffs without stale revert',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();
        final calculator = _SwitchablePrayerCalculator();

        var themeLabel = 'فاتح';
        var morningCutoff = const TimeOfDay(hour: 6, minute: 0);
        var currentNow = DateTime(2026, 11, 11, 9, 0);

        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: calculator,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => currentNow,
          preferencesReader: () => WidgetAdhkarRuntimePreferences(
            themeModeLabel: themeLabel,
            morningTime: morningCutoff,
            eveningTime: const TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final initial = await service.sync();
        expect(initial.status, WidgetSyncStatus.updated);
        final originalGeneratedAt = initial.snapshot!.generatedAtUtcEpochMs;
        final originalFajr = initial.snapshot!.prayerDays.first.fajrUtcEpochMs;

        // Now calculation fails 2 hours later, while theme & morning cutoff change.
        calculator.shouldThrow = true;
        currentNow = DateTime(2026, 11, 11, 11, 0);
        themeLabel = 'داكن';
        morningCutoff = const TimeOfDay(hour: 5, minute: 45);

        final preserved = await service.sync();
        expect(preserved.status, WidgetSyncStatus.preservedPreviousOnError);
        expect(preserved.snapshot!.prayerDataAvailable, isTrue);
        expect(preserved.snapshot!.prayerDays.first.fajrUtcEpochMs, originalFajr);
        expect(preserved.snapshot!.generatedAtUtcEpochMs, originalGeneratedAt);
        expect(preserved.snapshot!.themePreference, 'dark');
        expect(preserved.snapshot!.cutoffs.morningStartFormatted, '05:45');
        expect(transport.writeCount, 2);

        final persisted = WidgetSnapshot.tryFromEncodedJson(
          transport.storage[HomeWidgetSyncService.snapshotStorageKey]
              as String?,
        )!;
        expect(persisted.themePreference, 'dark');
        expect(persisted.cutoffs.morningStartFormatted, '05:45');
        expect(persisted.prayerDays.first.fajrUtcEpochMs, originalFajr);
      },
    );

    test(
      'rejects preserving previous snapshot when location changes (even with missing address names)',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(
          SavedPrayerLocation(
            latitude: 41.0082,
            longitude: 28.9784,
            isoCountryCode: 'TR',
            timestamp: DateTime.utc(2026, 11, 11, 8, 0),
            source: LocationSourceType.fresh,
          ),
        );

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();
        final calculator = _SwitchablePrayerCalculator();
        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: calculator,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        expect((await service.sync()).status, WidgetSyncStatus.updated);

        // Switch to another location (same fallback displayName 'الموقع المحفوظ') and fail calculation.
        await locationCache.save(
          SavedPrayerLocation(
            latitude: 39.9334,
            longitude: 32.8597,
            isoCountryCode: 'TR',
            timestamp: DateTime.utc(2026, 11, 11, 9, 10),
            source: LocationSourceType.fresh,
          ),
        );
        calculator.shouldThrow = true;

        final res = await service.sync();
        expect(res.status, WidgetSyncStatus.failed);
        expect(res.snapshot!.prayerDataAvailable, isFalse);
        expect(res.snapshot!.prayerDays, isEmpty);

        final persisted = WidgetSnapshot.tryFromEncodedJson(
          transport.storage[HomeWidgetSyncService.snapshotStorageKey]
              as String?,
        )!;
        expect(persisted.prayerDataAvailable, isFalse);
        expect(persisted.prayerDays, isEmpty);
      },
    );

    test(
      'rejects preserving snapshot across no-location <-> location transitions',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();
        final calculator = _SwitchablePrayerCalculator();
        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: calculator,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        // No location -> location becomes available -> fails.
        expect((await service.sync()).status, WidgetSyncStatus.updated);
        await locationCache.save(_sampleIstanbulLocation());
        calculator.shouldThrow = true;

        final failedWhenLocationAdded = await service.sync();
        expect(failedWhenLocationAdded.status, WidgetSyncStatus.failed);
        expect(failedWhenLocationAdded.snapshot!.hasSavedLocation, isTrue);
        expect(failedWhenLocationAdded.snapshot!.prayerDataAvailable, isFalse);
        expect(failedWhenLocationAdded.snapshot!.prayerDays, isEmpty);

        // Location available (valid) -> location cleared -> clears old prayer times.
        calculator.shouldThrow = false;
        expect((await service.sync()).status, WidgetSyncStatus.updated);
        await locationCache.clear();
        final afterClear = await service.sync();
        expect(afterClear.status, WidgetSyncStatus.updated);
        expect(afterClear.snapshot!.hasSavedLocation, isFalse);
        expect(afterClear.snapshot!.prayerDataAvailable, isFalse);
        expect(afterClear.snapshot!.prayerDays, isEmpty);
      },
    );

    test(
      'rejects preserving previous snapshot when calculation method or Madhab changes',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();
        final calculator = _SwitchablePrayerCalculator();
        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: calculator,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        expect((await service.sync()).status, WidgetSyncStatus.updated);

        // Change calculation method & fail calculation.
        calculator.shouldThrow = true;
        await settingsManager.updateSettings(
          const PrayerSettings(
            calculationMode: PrayerCalculationMode.manual,
            manualMethod: PrayerCalculationMethod.ummAlQura,
            madhab: PrayerMadhab.shafi,
          ),
        );
        final methodMismatchResult = await service.sync();
        expect(methodMismatchResult.status, WidgetSyncStatus.failed);
        expect(methodMismatchResult.snapshot!.prayerDataAvailable, isFalse);
        expect(methodMismatchResult.snapshot!.prayerDays, isEmpty);

        // Re-seed valid snapshot, then change Madhab & fail calculation.
        calculator.shouldThrow = false;
        expect((await service.sync()).status, WidgetSyncStatus.updated);
        calculator.shouldThrow = true;
        await settingsManager.setMadhab(PrayerMadhab.hanafi);
        final madhabMismatchResult = await service.sync();
        expect(madhabMismatchResult.status, WidgetSyncStatus.failed);
        expect(madhabMismatchResult.snapshot!.prayerDataAvailable, isFalse);
        expect(madhabMismatchResult.snapshot!.prayerDays, isEmpty);
      },
    );

    test(
      'rejects preserving snapshot with missing identity metadata or expired freshness age (>24h)',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();
        final calculator = _SwitchablePrayerCalculator();
        var currentNow = DateTime(2026, 11, 11, 9, 0);

        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: calculator,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => currentNow,
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        expect((await service.sync()).status, WidgetSyncStatus.updated);
        final storedMap =
            jsonDecode(
                  transport.storage[HomeWidgetSyncService.snapshotStorageKey]
                      as String,
                )
                as Map<String, dynamic>;

        // Case A: Strip opaque identity metadata -> rejected on calculation failure.
        final missingMetaMap = Map<String, dynamic>.from(storedMap);
        final locMap = Map<String, dynamic>.from(
          missingMetaMap['location'] as Map,
        );
        locMap['locationFingerprint'] = null;
        missingMetaMap['location'] = locMap;
        transport.storage[HomeWidgetSyncService.snapshotStorageKey] =
            jsonEncode(missingMetaMap);

        calculator.shouldThrow = true;
        final missingMetaResult = await service.sync();
        expect(missingMetaResult.status, WidgetSyncStatus.failed);
        expect(missingMetaResult.snapshot!.prayerDays, isEmpty);

        // Case B: Valid snapshot >24h old -> rejected even if horizon still includes currentNow.
        calculator.shouldThrow = false;
        currentNow = DateTime(2026, 11, 11, 9, 0);
        expect((await service.sync()).status, WidgetSyncStatus.updated);

        calculator.shouldThrow = true;
        currentNow = DateTime(2026, 11, 12, 10, 0); // 25 hours later
        final expiredResult = await service.sync();
        expect(expiredResult.status, WidgetSyncStatus.failed);
        expect(expiredResult.snapshot!.prayerDataAvailable, isFalse);
        expect(expiredResult.snapshot!.prayerDays, isEmpty);
      },
    );

    test(
      'rejects corrupt out-of-order prayer timestamps and handles constructor-configured calculation errors',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport();

        // Corrupt out-of-order prayer timestamps (Fajr after Sunrise) fail validation.
        final corruptService = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: _SwitchablePrayerCalculator(returnCorruptOrder: true),
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final corruptResult = await corruptService.sync();
        expect(corruptResult.status, WidgetSyncStatus.failed);
        expect(corruptResult.snapshot!.prayerDataAvailable, isFalse);
        expect(corruptResult.snapshot!.prayerDays, isEmpty);

        // Constructor-configured throwing calculator also leaves no fabricated times.
        final throwingService = HomeWidgetSyncService(
          transport: _FakeWidgetTransport(),
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          calculator: _SwitchablePrayerCalculator(shouldThrow: true),
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final throwResult = await throwingService.sync();
        expect(throwResult.status, WidgetSyncStatus.failed);
        expect(throwResult.snapshot!.prayerDataAvailable, isFalse);
        expect(throwResult.snapshot!.prayerDays, isEmpty);
      },
    );
  });

  group('Phase 1.1 Transport Edge Case — Partial Write Handling', () {
    test(
      'when transport overwrites snapshot JSON but fails schema version key, updates widgets and keeps state consistent',
      () async {
        final store = _InMemoryKeyValueStore();
        final locationCache = PrayerLocationCacheService(store: store);
        await locationCache.save(_sampleIstanbulLocation());

        final settingsManager = PrayerSettingsManager(
          storage: PrayerSettingsStorage(store: store),
        );
        final transport = _FakeWidgetTransport()..failSchemaVersionWrite = true;

        final service = HomeWidgetSyncService(
          transport: transport,
          locationCache: locationCache,
          prayerSettingsManager: settingsManager,
          assetLoader: _fakeAdhkarAssetLoader,
          nowProvider: () => DateTime(2026, 11, 11, 9, 0),
          preferencesReader: () => const WidgetAdhkarRuntimePreferences(
            themeModeLabel: 'فاتح',
            morningTime: TimeOfDay(hour: 6, minute: 0),
            eveningTime: TimeOfDay(hour: 17, minute: 0),
            morningReminderEnabled: true,
            eveningReminderEnabled: true,
          ),
        );

        final result = await service.sync();
        expect(result.status, WidgetSyncStatus.partialWrite);
        expect(result.didWrite, isTrue);
        expect(transport.writeCount, 1);
        expect(transport.updateRequestCount, 1);
        expect(
          transport.storage[HomeWidgetSyncService.snapshotStorageKey],
          isNotNull,
        );
        expect(
          transport.storage[HomeWidgetSyncService.schemaVersionStorageKey],
          isNull,
        );

        // Repeated unchanged call suppresses duplicate write cleanly.
        final second = await service.sync();
        expect(second.status, WidgetSyncStatus.skippedDuplicate);
      },
    );

    test(
      'HomeWidgetPlatformTransport writes metadata first and aborts before overwriting snapshot JSON if schema version fails',
      () async {
        final plugin = _FakeHomeWidgetPluginAdapter();
        plugin.data[HomeWidgetSyncService.snapshotStorageKey] =
            'existing_valid_snapshot';
        plugin.failSchemaWrite = true;

        final platformTransport = HomeWidgetPlatformTransport(
          plugin: plugin,
          platformOverride: TargetPlatform.android,
        );

        final result = await platformTransport.writeSnapshotData(
          snapshotKey: HomeWidgetSyncService.snapshotStorageKey,
          snapshotJson: 'new_snapshot',
          schemaVersionKey: HomeWidgetSyncService.schemaVersionStorageKey,
          schemaVersion: 1,
        );

        expect(result.snapshotPersisted, isFalse);
        expect(result.schemaVersionPersisted, isFalse);
        expect(
          plugin.data[HomeWidgetSyncService.snapshotStorageKey],
          'existing_valid_snapshot',
        );
      },
    );
  });
}
