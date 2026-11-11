import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:adhkar/features/prayer/data/services/prayer_location_cache_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_location_service.dart';
import 'package:adhkar/features/prayer/data/services/prayer_settings_storage.dart';
import 'package:adhkar/features/prayer/domain/entities/saved_prayer_location.dart';

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

  bool serviceEnabled = true;
  geolocator.LocationPermission checkResult =
      geolocator.LocationPermission.whileInUse;
  geolocator.LocationPermission requestResult =
      geolocator.LocationPermission.whileInUse;

  Future<RawLocationSample> Function(
    geolocator.LocationAccuracy accuracy,
    bool forceLocationManager,
    Duration timeLimit,
  )? onGetCurrent;

  Future<RawLocationSample?> Function(bool forceLocationManager)? onLastKnown;

  int getCurrentCalls = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<geolocator.LocationPermission> checkPermission() async => checkResult;

  @override
  Future<geolocator.LocationPermission> requestPermission() async =>
      requestResult;

  @override
  Future<RawLocationSample> getCurrentPosition({
    required geolocator.LocationAccuracy accuracy,
    required bool forceAndroidLocationManager,
    required Duration timeLimit,
  }) {
    getCurrentCalls++;
    return onGetCurrent!(accuracy, forceAndroidLocationManager, timeLimit);
  }

  @override
  Future<RawLocationSample?> getLastKnownPosition({
    required bool forceAndroidLocationManager,
  }) async {
    if (onLastKnown == null) return null;
    return onLastKnown!(forceAndroidLocationManager);
  }
}

class _FakeGeocoder implements ReverseGeocoderAdapter {
  ReverseGeocodedAddress? response;
  bool shouldThrow = false;
  int calls = 0;

  @override
  Future<ReverseGeocodedAddress?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    calls++;
    if (shouldThrow) {
      throw Exception('Geocode unavailable');
    }
    return response;
  }
}

void main() {
  group('SavedPrayerLocation & PrayerLocationService', () {
    test('formats readable Arabic displayName and falls back cleanly without raw coords', () {
      final full = SavedPrayerLocation(
        latitude: 41.03,
        longitude: 28.67,
        isoCountryCode: 'TR',
        countryName: 'تركيا',
        city: 'إسطنبول',
        district: 'إسنيورت',
        timestamp: DateTime.utc(2026, 6, 1),
        source: LocationSourceType.fresh,
      );
      expect(full.displayName, 'تركيا، إسطنبول، إسنيورت');

      final noAddress = SavedPrayerLocation(
        latitude: 41.03,
        longitude: 28.67,
        timestamp: DateTime.utc(2026, 6, 1),
        source: LocationSourceType.cached,
      );
      expect(noAddress.displayName, SavedPrayerLocation.fallbackDisplayName);
      expect(noAddress.displayName.contains('41.03'), isFalse);
    });

    test('fails cleanly when location services disabled or permission denied without using cache', () async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      final provider = _FakeLocationProvider()..serviceEnabled = false;
      final geocoder = _FakeGeocoder();
      final service = PrayerLocationService(
        provider: provider,
        geocoder: geocoder,
        cache: cache,
      );

      await expectLater(
        service.acquireAndSaveLocation(),
        throwsA(
          predicate<LocationAcquisitionException>(
            (e) => e.reason == LocationAcquisitionFailureReason.serviceDisabled,
          ),
        ),
      );

      provider
        ..serviceEnabled = true
        ..checkResult = geolocator.LocationPermission.denied
        ..requestResult = geolocator.LocationPermission.denied;
      await expectLater(
        service.acquireAndSaveLocation(),
        throwsA(
          predicate<LocationAcquisitionException>(
            (e) => e.reason == LocationAcquisitionFailureReason.permissionDenied,
          ),
        ),
      );

      provider.checkResult = geolocator.LocationPermission.deniedForever;
      await expectLater(
        service.acquireAndSaveLocation(),
        throwsA(
          predicate<LocationAcquisitionException>(
            (e) =>
                e.reason ==
                LocationAcquisitionFailureReason.permissionDeniedForever,
          ),
        ),
      );
    });

    test('Android timeout falls back to LocationManager then recent valid last-known location', () async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      final now = DateTime.utc(2026, 6, 1, 12, 0);
      final provider = _FakeLocationProvider()
        ..platform = TargetPlatform.android
        ..onGetCurrent = (acc, forceLm, limit) async {
          if (!forceLm) {
            throw TimeoutException('Fused timed out');
          }
          return RawLocationSample(
            latitude: 41.0082,
            longitude: 28.9784,
            timestamp: now,
          );
        };
      final geocoder = _FakeGeocoder()
        ..response = const ReverseGeocodedAddress(
          isoCountryCode: 'TR',
          countryName: 'تركيا',
          city: 'إسطنبول',
          district: 'الفاتح',
        );
      final service = PrayerLocationService(
        provider: provider,
        geocoder: geocoder,
        cache: cache,
        now: () => now,
      );

      final lmResult = await service.acquireAndSaveLocation();
      expect(lmResult.source, LocationSourceType.fresh);
      expect(lmResult.displayName, 'تركيا، إسطنبول، الفاتح');

      // Now both primary & LocationManager time out -> lastKnown cached fallback
      provider.onGetCurrent = (acc, forceLm, limit) async {
        throw TimeoutException('Timed out');
      };
      provider.onLastKnown = (forceLm) async {
        if (!forceLm) return null;
        return RawLocationSample(
          latitude: 24.7136,
          longitude: 46.6753,
          timestamp: now.subtract(const Duration(minutes: 20)),
        );
      };
      geocoder.response = const ReverseGeocodedAddress(
        isoCountryCode: 'SA',
        countryName: 'السعودية',
        city: 'الرياض',
      );

      final lastKnownResult = await service.acquireAndSaveLocation();
      expect(lastKnownResult.source, LocationSourceType.cached);
      expect(lastKnownResult.isoCountryCode, 'SA');
    });

    test('rejects stale or invalid last-known coordinates and preserves prior cache on failure', () async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      final now = DateTime.utc(2026, 6, 1, 12, 0);

      final priorValid = SavedPrayerLocation(
        latitude: 30.0444,
        longitude: 31.2357,
        isoCountryCode: 'EG',
        countryName: 'مصر',
        city: 'القاهرة',
        timestamp: now.subtract(const Duration(hours: 1)),
        source: LocationSourceType.fresh,
      );
      await cache.save(priorValid);

      final provider = _FakeLocationProvider()
        ..platform = TargetPlatform.android
        ..onGetCurrent = (_, _, _) async {
          throw TimeoutException('timeout');
        }
        ..onLastKnown = (forceLm) async {
          if (!forceLm) {
            return RawLocationSample(
              latitude: double.nan,
              longitude: 10.0,
              timestamp: now,
            );
          }
          // Stale > 24h
          return RawLocationSample(
            latitude: 20.0,
            longitude: 30.0,
            timestamp: now.subtract(const Duration(hours: 48)),
          );
        };

      final service = PrayerLocationService(
        provider: provider,
        geocoder: _FakeGeocoder(),
        cache: cache,
        now: () => now,
      );

      await expectLater(
        service.acquireAndSaveLocation(),
        throwsA(isA<LocationAcquisitionException>()),
      );

      // Prior valid location must still be intact in cache!
      expect(await cache.load(), equals(priorValid));
    });

    test('reverse geocoding failure keeps coordinates and resolveAddressForSavedLocation enriches without GPS', () async {
      final store = _MemStore();
      final cache = PrayerLocationCacheService(store: store);
      final now = DateTime.utc(2026, 6, 1, 12, 0);

      final provider = _FakeLocationProvider()
        ..onGetCurrent = (_, _, _) async => RawLocationSample(
          latitude: 41.03,
          longitude: 28.67,
          timestamp: now,
        );
      final geocoder = _FakeGeocoder()..shouldThrow = true;
      final service = PrayerLocationService(
        provider: provider,
        geocoder: geocoder,
        cache: cache,
        now: () => now,
      );

      final saved = await service.acquireAndSaveLocation();
      expect(saved.latitude, 41.03);
      expect(saved.displayName, SavedPrayerLocation.fallbackDisplayName);
      expect(provider.getCurrentCalls, 1);

      // Now geocoder recovers; enriching existing saved location must NOT call GPS!
      geocoder.shouldThrow = false;
      geocoder.response = const ReverseGeocodedAddress(
        isoCountryCode: 'TR',
        countryName: 'تركيا',
        city: 'إسطنبول',
        district: 'إسنيورت',
      );
      final enriched = await service.resolveAddressForSavedLocation(saved);
      expect(provider.getCurrentCalls, 1);
      expect(enriched.displayName, 'تركيا، إسطنبول، إسنيورت');
      expect((await cache.load())?.displayName, 'تركيا، إسطنبول، إسنيورت');
    });
  });
}

