import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:adhkar/features/adhkar/presentation/pages/home_page.dart';
import 'package:adhkar/features/prayer/data/services/prayer_location_cache_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_location_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_notification_settings_storage.dart';
import 'package:adhkar/features/prayer/data/services/prayer_settings_storage.dart';
import 'package:adhkar/features/prayer/domain/entities/saved_prayer_location.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_notification_manager.dart';
import 'package:adhkar/features/prayer/presentation/managers/prayer_settings_manager.dart';
import 'package:adhkar/features/prayer/presentation/pages/prayer_notification_settings_page.dart';
import 'package:adhkar/features/prayer/presentation/pages/prayer_times_page.dart';
import 'package:adhkar/features/qibla/data/services/compass_sensor_service.dart';
import 'package:adhkar/features/qibla/presentation/pages/qibla_page.dart';

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

class _FakeLocationProvider implements LocationProviderAdapter {
  @override
  TargetPlatform platform = TargetPlatform.android;

  int getCurrentCalls = 0;

  @override
  Future<geolocator.LocationPermission> checkPermission() async =>
      geolocator.LocationPermission.whileInUse;

  @override
  Future<RawLocationSample> getCurrentPosition({
    required geolocator.LocationAccuracy accuracy,
    required bool forceAndroidLocationManager,
    required Duration timeLimit,
  }) async {
    getCurrentCalls++;
    return RawLocationSample(
      latitude: 41.0082,
      longitude: 28.9784,
      timestamp: DateTime.utc(2026, 6, 15, 10, 0),
    );
  }

  @override
  Future<RawLocationSample?> getLastKnownPosition({
    required bool forceAndroidLocationManager,
  }) async => null;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<geolocator.LocationPermission> requestPermission() async =>
      geolocator.LocationPermission.whileInUse;
}

class _FakeGeocoder implements ReverseGeocoderAdapter {
  @override
  Future<ReverseGeocodedAddress?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    return const ReverseGeocodedAddress(
      isoCountryCode: 'TR',
      countryName: 'تركيا',
      city: 'إسطنبول',
      district: 'إسنيورت',
    );
  }
}

class _FakeCompassSource implements CompassEventSource {
  @override
  TargetPlatform platform;

  @override
  Stream<CompassEvent>? events;

  _FakeCompassSource({required this.platform, this.events});
}

Widget _wrapRtlApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  final istanbul = SavedPrayerLocation(
    latitude: 41.0082,
    longitude: 28.9784,
    isoCountryCode: 'TR',
    countryName: 'تركيا',
    city: 'إسطنبول',
    district: 'إسنيورت',
    timestamp: DateTime.utc(2026, 6, 15, 8, 0),
    source: LocationSourceType.fresh,
  );

  group('Prayer Times, Notification Settings, Qibla & Home Integration Widget Tests', () {
    testWidgets('PrayerTimesPage opens saved location without GPS and displays all 6 events + tomorrow Fajr', (tester) async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      await cache.save(istanbul);

      final provider = _FakeLocationProvider();
      final locService = PrayerLocationService(
        provider: provider,
        geocoder: _FakeGeocoder(),
        cache: cache,
      );
      final settingsManager = PrayerSettingsManager(
        storage: PrayerSettingsStorage(store: store),
      );
      final notifManager = PrayerNotificationManager(
        storage: PrayerNotificationSettingsStorage(store: store),
        prayerSettingsManager: settingsManager,
        locationCache: cache,
      );

      await tester.pumpWidget(
        _wrapRtlApp(
          PrayerTimesPage(
            settingsManager: settingsManager,
            locationService: locService,
            locationCache: cache,
            notificationManager: notifManager,
            nowProvider: () => DateTime(2026, 6, 15, 6, 30),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must NOT acquire GPS when saved location exists!
      expect(provider.getCurrentCalls, 0);
      expect(find.text('تركيا، إسطنبول، إسنيورت'), findsOneWidget);
      final eventsListFinder = find.byKey(const ValueKey('prayer_events_list'));
      expect(eventsListFinder, findsOneWidget);
      expect(
        find.descendant(of: eventsListFinder, matching: find.text('الفجر')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eventsListFinder, matching: find.text('الشروق')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eventsListFinder, matching: find.text('الظهر')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eventsListFinder, matching: find.text('العصر')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eventsListFinder, matching: find.text('المغرب')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: eventsListFinder, matching: find.text('العشاء')),
        findsOneWidget,
      );
      expect(find.text('فجر الغد'), findsOneWidget);
    });

    testWidgets('PrayerTimesPage shows missing location state when cache empty and never requests GPS automatically', (tester) async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      final provider = _FakeLocationProvider();
      final locService = PrayerLocationService(
        provider: provider,
        geocoder: _FakeGeocoder(),
        cache: cache,
      );

      await tester.pumpWidget(
        _wrapRtlApp(
          PrayerTimesPage(
            settingsManager: PrayerSettingsManager(
              storage: PrayerSettingsStorage(store: store),
            ),
            locationService: locService,
            locationCache: cache,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(provider.getCurrentCalls, 0);
      expect(find.text('لا يوجد موقع محفوظ'), findsOneWidget);
      expect(find.text('تحديد الموقع الآن'), findsOneWidget);
    });

    testWidgets('PrayerNotificationSettingsPage displays 5 obligatory prayers only and no Sunrise', (tester) async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      final settingsManager = PrayerSettingsManager(
        storage: PrayerSettingsStorage(store: store),
      );
      final notifManager = PrayerNotificationManager(
        storage: PrayerNotificationSettingsStorage(store: store),
        prayerSettingsManager: settingsManager,
        locationCache: cache,
      );

      await tester.pumpWidget(
        _wrapRtlApp(
          PrayerNotificationSettingsPage(
            notificationManager: notifManager,
            locationCache: cache,
            locationService: PrayerLocationService(cache: cache),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تفعيل تنبيهات الصلاة'), findsOneWidget);
      expect(find.text('تنبيه قصير'), findsOneWidget);
      expect(find.text('صامت'), findsOneWidget);
      expect(find.text('الفجر'), findsOneWidget);
      expect(find.text('الظهر'), findsOneWidget);
      expect(find.text('العصر'), findsOneWidget);
      expect(find.text('المغرب'), findsOneWidget);
      expect(find.text('العشاء'), findsOneWidget);
      expect(find.text('الشروق'), findsNothing);
    });

    testWidgets('QiblaPage shows alignment only within +-5 deg and hides compass arrow on unsupported WMM date', (tester) async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      await cache.save(istanbul);

      final controller = StreamController<CompassEvent>.broadcast();
      final sensorService = CompassSensorService(
        source: _FakeCompassSource(
          platform: TargetPlatform.iOS,
          events: controller.stream,
        ),
      );

      await tester.pumpWidget(
        _wrapRtlApp(
          QiblaPage(
            key: const ValueKey('qibla_ios_supported'),
            locationCache: cache,
            locationService: PrayerLocationService(cache: cache),
            sensorService: sensorService,
            nowProvider: () => DateTime.utc(2026, 6, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('اتجاه القبلة'), findsWidgets);
      expect(find.text('تركيا، إسطنبول، إسنيورت'), findsOneWidget);

      // Bearing for Istanbul is ~152 deg. Send 152 deg trueHeading -> aligned!
      controller.add(CompassEvent.fromList([152.0, 0.0, 10.0]));
      await tester.pumpAndSettle();
      expect(find.text('أنت متجه نحو القبلة'), findsOneWidget);

      // Send 200 deg -> NOT aligned!
      controller.add(CompassEvent.fromList([200.0, 0.0, 10.0]));
      await tester.pumpAndSettle();
      expect(find.text('أنت متجه نحو القبلة'), findsNothing);

      await controller.close();

      // Unsupported WMM date on Android must show explicit WMM error, not assume 0 declination.
      final androidSensor = CompassSensorService(
        source: _FakeCompassEventSourceAndroid(),
      );
      await tester.pumpWidget(
        _wrapRtlApp(
          QiblaPage(
            key: const ValueKey('qibla_android_unsupported'),
            locationCache: cache,
            locationService: PrayerLocationService(cache: cache),
            sensorService: androidSensor,
            nowProvider: () => DateTime.utc(2031, 1, 1),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('تعذر تصحيح الانحراف المغناطيسي'), findsOneWidget);
    });

    testWidgets('HomePage preserves Tasbeeh and adds Prayer & Qibla entries in RTL', (tester) async {
      await tester.pumpWidget(_wrapRtlApp(const HomePage()));
      await tester.pump();

      expect(find.text('مواقيت الصلاة'), findsOneWidget);
      expect(find.text('اتجاه القبلة'), findsOneWidget);
      expect(find.text('المسبحة'), findsOneWidget);
    });
  });
}

class _FakeCompassEventSourceAndroid implements CompassEventSource {
  @override
  TargetPlatform get platform => TargetPlatform.android;

  @override
  Stream<CompassEvent>? get events => const Stream.empty();
}
