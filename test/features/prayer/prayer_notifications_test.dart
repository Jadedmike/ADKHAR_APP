import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/services/notification_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_location_cache_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_notification_scheduler.dart';
import 'package:adhkar/features/prayer/data/services/prayer_notification_settings_storage.dart';
import 'package:adhkar/features/prayer/data/services/prayer_settings_storage.dart';
import 'package:adhkar/features/prayer/domain/entities/daily_prayer_times.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_notification_settings.dart';
import 'package:adhkar/features/prayer/domain/entities/prayer_settings.dart';
import 'package:adhkar/features/prayer/domain/entities/saved_prayer_location.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_notification_manager.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_settings_manager.dart';

class _MemStore implements KeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    values[key] = value;
    return true;
  }
}

class _ScheduledRecord {
  final int id;
  final String title;
  final String body;
  final DateTime scheduledLocalTime;
  final PrayerNotificationSoundMode soundMode;
  final AndroidScheduleMode androidScheduleMode;

  const _ScheduledRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledLocalTime,
    required this.soundMode,
    required this.androidScheduleMode,
  });
}

class _FakeGateway implements PrayerNotificationPlatformGateway {
  @override
  TargetPlatform platform = TargetPlatform.android;

  bool hasPermission = true;
  bool requestPermissionResult = true;
  bool canExactAlarms = true;
  int requestPermissionCalls = 0;
  bool channelsCreated = false;

  final List<PendingNotificationRequest> externalPending = [];
  final Map<int, _ScheduledRecord> scheduled = {};
  final List<int> cancelledIds = [];

  @override
  Future<void> ensurePrayerChannelsCreated() async {
    channelsCreated = true;
  }

  @override
  Future<bool> hasPermissionWithoutPrompt() async => hasPermission;

  @override
  Future<bool> requestPermission() async {
    requestPermissionCalls++;
    hasPermission = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<bool> canScheduleExactAlarmsWithoutPrompt() async => canExactAlarms;

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return [
      ...externalPending,
      for (final entry in scheduled.values)
        PendingNotificationRequest(entry.id, entry.title, entry.body, null),
    ];
  }

  @override
  Future<void> cancelNotification(int id) async {
    cancelledIds.add(id);
    scheduled.remove(id);
  }

  @override
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledLocalTime,
    required PrayerNotificationSoundMode soundMode,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    scheduled[id] = _ScheduledRecord(
      id: id,
      title: title,
      body: body,
      scheduledLocalTime: scheduledLocalTime,
      soundMode: soundMode,
      androidScheduleMode: androidScheduleMode,
    );
  }
}

void main() {
  // Align test meridian longitude with device-local timezone so local solar
  // times fall on the same local calendar day regardless of runner timezone
  // (e.g., Fajr ~03:15, Dhuhr ~12:00, Asr ~15:40, Maghrib ~19:08, Isha ~20:42).
  final double localMeridianLon =
      (DateTime(2026, 6, 15).timeZoneOffset.inMinutes / 4.0).clamp(-180.0, 180.0);
  final sampleLocation = SavedPrayerLocation(
    latitude: 35.0,
    longitude: localMeridianLon,
    countryName: 'موقع الاختبار',
    city: 'المدينة',
    timestamp: DateTime.utc(2026, 6, 15),
    source: LocationSourceType.fresh,
  );

  group('PrayerNotificationSettings & Isolation', () {
    test('defaults have master disabled, 5 obligatory prayers enabled, short sound', () {
      final defaults = PrayerNotificationSettings.defaults();
      expect(defaults.schemaVersion, 1);
      expect(defaults.masterEnabled, isFalse);
      expect(defaults.soundMode, PrayerNotificationSoundMode.shortAlert);
      for (final prayer in ObligatoryPrayer.values) {
        expect(defaults.isPrayerEnabled(prayer), isTrue);
      }
      expect(ObligatoryPrayer.values.length, 5);
    });

    test('serialization rejects unsupported schema version & malformed JSON', () async {
      final store = _MemStore();
      final storage = PrayerNotificationSettingsStorage(store: store);

      store.values[PrayerNotificationSettingsStorage.storageKey] = jsonEncode({
        'schemaVersion': 99,
        'masterEnabled': true,
        'soundMode': 'short',
        'enabledPrayers': {},
      });
      expect(
        () => storage.load(),
        throwsA(isA<PrayerNotificationSchemaException>()),
      );

      store.values[PrayerNotificationSettingsStorage.storageKey] = 'invalid';
      expect(
        () => storage.load(),
        throwsA(isA<PrayerNotificationFormatException>()),
      );
    });

    test('NotificationService Adhkar IDs are strictly isolated from 5000-5069', () {
      for (final id in NotificationService.adhkarOwnedIds) {
        expect(PrayerNotificationScheduler.isPrayerNotificationId(id), isFalse);
      }
      expect(
        NotificationService.adhkarOwnedIds,
        containsAll(const [1001, 1002, 2001, 2002, 2003, 9999]),
      );
    });

    test('schedules rolling 7 days for 5 obligatory prayers only, never Sunrise, in 5000-5069', () async {
      final gateway = _FakeGateway()
        ..externalPending.addAll(const [
          PendingNotificationRequest(1001, 'أذكار الصباح', '', null),
          PendingNotificationRequest(1002, 'أذكار المساء', '', null),
        ]);

      // Midday on June 15 -> Fajr and Dhuhr passed, Asr/Maghrib/Isha remain for day 0.
      final now = DateTime(2026, 6, 15, 14, 0);
      final scheduler = PrayerNotificationScheduler(
        gateway: gateway,
        now: () => now,
      );

      final result = await scheduler.scheduleRollingSevenDays(
        location: sampleLocation,
        prayerSettings: PrayerSettings.defaults(),
        notificationSettings: PrayerNotificationSettings(masterEnabled: true),
      );

      expect(gateway.channelsCreated, isTrue);
      expect(result.androidScheduleMode, AndroidScheduleMode.exactAllowWhileIdle);
      // Day 0: 3 prayers (Asr, Maghrib, Isha), Days 1..6: 6 * 5 = 30 -> 33 total
      expect(result.scheduledCount, 33);
      expect(result.skippedPastCount, 2);

      for (final record in gateway.scheduled.values) {
        expect(record.id, inInclusiveRange(5000, 5069));
        expect(record.title.contains('الشروق'), isFalse);
        expect(record.scheduledLocalTime.isAfter(now), isTrue);
      }

      // Adhkar IDs were NEVER cancelled!
      expect(gateway.cancelledIds.contains(1001), isFalse);
      expect(gateway.cancelledIds.contains(1002), isFalse);
      expect(gateway.externalPending.length, 2);
    });

    test('respects individual prayer switches and silent sound mode', () async {
      final gateway = _FakeGateway();
      final now = DateTime(2026, 6, 15, 1, 0);
      final scheduler = PrayerNotificationScheduler(
        gateway: gateway,
        now: () => now,
      );

      final settings = PrayerNotificationSettings(
        masterEnabled: true,
        soundMode: PrayerNotificationSoundMode.silent,
        enabledPrayers: const {
          ObligatoryPrayer.fajr: true,
          ObligatoryPrayer.dhuhr: false,
          ObligatoryPrayer.asr: true,
          ObligatoryPrayer.maghrib: false,
          ObligatoryPrayer.isha: true,
        },
      );

      final result = await scheduler.scheduleRollingSevenDays(
        location: sampleLocation,
        prayerSettings: PrayerSettings.defaults(),
        notificationSettings: settings,
      );

      expect(result.scheduledCount, 21); // 7 days * 3 enabled prayers
      for (final record in gateway.scheduled.values) {
        expect(record.soundMode, PrayerNotificationSoundMode.silent);
        expect(record.title.contains('الظهر'), isFalse);
        expect(record.title.contains('المغرب'), isFalse);
      }
    });

    test('falls back to inexactAllowWhileIdle when Android exact alarms unavailable', () async {
      final gateway = _FakeGateway()
        ..platform = TargetPlatform.android
        ..canExactAlarms = false;
      final scheduler = PrayerNotificationScheduler(
        gateway: gateway,
        now: () => DateTime(2026, 6, 15, 1, 0),
      );

      final result = await scheduler.scheduleRollingSevenDays(
        location: sampleLocation,
        prayerSettings: PrayerSettings.defaults(),
        notificationSettings: PrayerNotificationSettings(masterEnabled: true),
      );

      expect(
        result.androidScheduleMode,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
      expect(result.scheduledCount, 35);
    });

    test('respects iOS 64 pending notification limit alongside Adhkar notifications', () async {
      final gateway = _FakeGateway()
        ..platform = TargetPlatform.iOS;
      // 35 existing non-prayer pending notifications -> only 29 slots left for prayer.
      for (int i = 0; i < 35; i++) {
        gateway.externalPending.add(
          PendingNotificationRequest(1000 + i, 'adhkar', '', null),
        );
      }

      final scheduler = PrayerNotificationScheduler(
        gateway: gateway,
        now: () => DateTime(2026, 6, 15, 1, 0),
      );

      final result = await scheduler.scheduleRollingSevenDays(
        location: sampleLocation,
        prayerSettings: PrayerSettings.defaults(),
        notificationSettings: PrayerNotificationSettings(masterEnabled: true),
      );

      expect(result.scheduledCount, 29);
      expect(result.cappedByIosLimitCount, 6);
      final totalPending = await gateway.pendingNotificationRequests();
      expect(totalPending.length, 64);
    });

    test('startup sync never requests permissions and cleans notification cache on disable without removing app location', () async {
      final store = _MemStore();
      final notifStorage = PrayerNotificationSettingsStorage(store: store);
      final locationCache = PrayerLocationCacheService(store: store);
      final prayerSettingsManager = PrayerSettingsManager(
        storage: PrayerSettingsStorage(store: store),
      );
      final gateway = _FakeGateway()..hasPermission = false;
      final scheduler = PrayerNotificationScheduler(
        gateway: gateway,
        now: () => DateTime(2026, 6, 15, 1, 0),
      );

      await locationCache.save(sampleLocation);
      await notifStorage.save(PrayerNotificationSettings(masterEnabled: true));

      final manager = PrayerNotificationManager(
        storage: notifStorage,
        scheduler: scheduler,
        gateway: gateway,
        prayerSettingsManager: prayerSettingsManager,
        locationCache: locationCache,
      );

      // Startup sync when permission denied: must NOT call requestPermission()
      await manager.syncOnStartup();
      expect(gateway.requestPermissionCalls, 0);
      expect(gateway.scheduled, isEmpty);

      // Startup sync when permission granted & saved location present
      gateway.hasPermission = true;
      await manager.syncOnStartup();
      expect(gateway.requestPermissionCalls, 0);
      expect(gateway.scheduled.length, 35);
      expect(await notifStorage.loadCachedNotificationLocation(), isNotNull);

      // Disabling master clears notification cache & prayer notifications,
      // while preserving independent saved location!
      await manager.setMasterEnabled(false);
      expect(gateway.scheduled, isEmpty);
      expect(await notifStorage.loadCachedNotificationLocation(), isNull);
      expect(await locationCache.load(), equals(sampleLocation));
    });
  });
}

