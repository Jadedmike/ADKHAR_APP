import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' as geolocator;
import '../../domain/entities/saved_prayer_location.dart';
import 'prayer_location_cache_service.dart';

/// Reasons why foreground location acquisition can fail.
enum LocationAcquisitionFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  invalidCoordinates,
  unavailable,
}

/// Typed exception describing a foreground location acquisition failure.
class LocationAcquisitionException implements Exception {
  final LocationAcquisitionFailureReason reason;
  final String arabicMessage;
  final Object? cause;

  const LocationAcquisitionException({
    required this.reason,
    required this.arabicMessage,
    this.cause,
  });

  @override
  String toString() => 'LocationAcquisitionException($reason): $arabicMessage';
}

/// Simplified location fix returned by [LocationProviderAdapter].
class RawLocationSample {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const RawLocationSample({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });
}

/// Simplified address metadata returned by [ReverseGeocoderAdapter].
class ReverseGeocodedAddress {
  final String? isoCountryCode;
  final String? countryName;
  final String? city;
  final String? district;

  const ReverseGeocodedAddress({
    this.isoCountryCode,
    this.countryName,
    this.city,
    this.district,
  });

  bool get hasAnyAddressField {
    return (countryName?.trim().isNotEmpty ?? false) ||
        (city?.trim().isNotEmpty ?? false) ||
        (district?.trim().isNotEmpty ?? false);
  }
}

/// Abstraction over platform location services for dependency injection & testing.
abstract class LocationProviderAdapter {
  TargetPlatform get platform;

  Future<bool> isLocationServiceEnabled();
  Future<geolocator.LocationPermission> checkPermission();
  Future<geolocator.LocationPermission> requestPermission();

  Future<RawLocationSample> getCurrentPosition({
    required geolocator.LocationAccuracy accuracy,
    required bool forceAndroidLocationManager,
    required Duration timeLimit,
  });

  Future<RawLocationSample?> getLastKnownPosition({
    required bool forceAndroidLocationManager,
  });
}

/// Default [geolocator]-backed implementation of [LocationProviderAdapter].
/// Performs strictly foreground one-shot lookups (never streams or background tracking).
class GeolocatorLocationProviderAdapter implements LocationProviderAdapter {
  const GeolocatorLocationProviderAdapter();

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  Future<bool> isLocationServiceEnabled() {
    return geolocator.Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<geolocator.LocationPermission> checkPermission() {
    return geolocator.Geolocator.checkPermission();
  }

  @override
  Future<geolocator.LocationPermission> requestPermission() {
    return geolocator.Geolocator.requestPermission();
  }

  @override
  Future<RawLocationSample> getCurrentPosition({
    required geolocator.LocationAccuracy accuracy,
    required bool forceAndroidLocationManager,
    required Duration timeLimit,
  }) async {
    final geolocator.LocationSettings settings;
    if (platform == TargetPlatform.android) {
      settings = geolocator.AndroidSettings(
        accuracy: accuracy,
        forceLocationManager: forceAndroidLocationManager,
        timeLimit: timeLimit,
      );
    } else {
      settings = geolocator.LocationSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      );
    }

    final position = await geolocator.Geolocator.getCurrentPosition(
      locationSettings: settings,
    );
    return RawLocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }

  @override
  Future<RawLocationSample?> getLastKnownPosition({
    required bool forceAndroidLocationManager,
  }) async {
    final position = await geolocator.Geolocator.getLastKnownPosition(
      forceAndroidLocationManager: forceAndroidLocationManager,
    );
    if (position == null) return null;
    return RawLocationSample(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: position.timestamp,
    );
  }
}

/// Abstraction over platform reverse geocoding for dependency injection & testing.
abstract class ReverseGeocoderAdapter {
  Future<ReverseGeocodedAddress?> reverseGeocode(
    double latitude,
    double longitude,
  );
}

/// Default [geocoding]-backed implementation of [ReverseGeocoderAdapter].
class PlatformReverseGeocoderAdapter implements ReverseGeocoderAdapter {
  const PlatformReverseGeocoderAdapter();

  @override
  Future<ReverseGeocodedAddress?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      await geocoding.setLocaleIdentifier('ar');
    } catch (_) {}

    final placemarks = await geocoding.placemarkFromCoordinates(
      latitude,
      longitude,
    );
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;
    final country = _clean(p.country);
    final city = _clean(p.locality) ?? _clean(p.administrativeArea);
    final district = _clean(p.subLocality) ?? _clean(p.subAdministrativeArea);
    final iso = _clean(p.isoCountryCode)?.toUpperCase();

    return ReverseGeocodedAddress(
      isoCountryCode: iso,
      countryName: country,
      city: city,
      district: district,
    );
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// Foreground one-shot location service with Android timeout fallbacks,
/// bounded timeouts, coordinate validation, reverse geocoding, and cache preservation.
class PrayerLocationService {
  static const Duration defaultPrimaryTimeout = Duration(seconds: 10);
  static const Duration defaultAndroidFallbackTimeout = Duration(seconds: 8);
  static const Duration defaultLastKnownTimeout = Duration(seconds: 3);
  static const Duration defaultGeocodeTimeout = Duration(seconds: 5);
  static const Duration defaultMaxLastKnownAge = Duration(hours: 24);

  final LocationProviderAdapter _provider;
  final ReverseGeocoderAdapter _geocoder;
  final PrayerLocationCacheService _cache;
  final Duration _primaryTimeout;
  final Duration _androidFallbackTimeout;
  final Duration _lastKnownTimeout;
  final Duration _geocodeTimeout;
  final Duration _maxLastKnownAge;
  final DateTime Function() _now;

  PrayerLocationService({
    LocationProviderAdapter? provider,
    ReverseGeocoderAdapter? geocoder,
    PrayerLocationCacheService? cache,
    Duration primaryTimeout = defaultPrimaryTimeout,
    Duration androidFallbackTimeout = defaultAndroidFallbackTimeout,
    Duration lastKnownTimeout = defaultLastKnownTimeout,
    Duration geocodeTimeout = defaultGeocodeTimeout,
    Duration maxLastKnownAge = defaultMaxLastKnownAge,
    DateTime Function()? now,
  }) : _provider = provider ?? const GeolocatorLocationProviderAdapter(),
       _geocoder = geocoder ?? const PlatformReverseGeocoderAdapter(),
       _cache = cache ?? PrayerLocationCacheService.instance,
       _primaryTimeout = primaryTimeout,
       _androidFallbackTimeout = androidFallbackTimeout,
       _lastKnownTimeout = lastKnownTimeout,
       _geocodeTimeout = geocodeTimeout,
       _maxLastKnownAge = maxLastKnownAge,
       _now = now ?? DateTime.now;

  static final PrayerLocationService instance = PrayerLocationService();

  /// Checks current location permission status without prompting the user.
  Future<geolocator.LocationPermission> checkPermission() {
    return _provider.checkPermission();
  }

  /// Checks whether OS location services are enabled without acquiring GPS.
  Future<bool> isLocationServiceEnabled() {
    return _provider.isLocationServiceEnabled();
  }

  /// Acquires a one-shot foreground location, reverse geocodes it, and saves it.
  ///
  /// Only call after explicit user action.
  /// If acquisition fails, the previously cached valid location is preserved untouched.
  Future<SavedPrayerLocation> acquireAndSaveLocation({
    bool requestPermissionIfNeeded = true,
  }) async {
    // 1. Verify OS location services are enabled before any acquisition or cache fallback.
    final bool serviceEnabled = await _provider.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.serviceDisabled,
        arabicMessage:
            'خدمات الموقع غير مفعّلة على الجهاز. يرجى تفعيل خدمة الموقع (GPS) والمحاولة مجدداً.',
      );
    }

    // 2. Verify location permission; never use cached coordinates when denied.
    geolocator.LocationPermission permission = await _provider.checkPermission();
    if (permission == geolocator.LocationPermission.denied &&
        requestPermissionIfNeeded) {
      permission = await _provider.requestPermission();
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      throw const LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.permissionDeniedForever,
        arabicMessage:
            'تم رفض إذن الموقع بشكل دائم. يرجى تفعيل إذن الموقع من إعدادات التطبيق.',
      );
    }

    if (permission == geolocator.LocationPermission.denied ||
        permission == geolocator.LocationPermission.unableToDetermine) {
      throw const LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.permissionDenied,
        arabicMessage:
            'لم يتم منح إذن الوصول إلى الموقع. يلزم الإذن لحساب مواقيت الصلاة واتجاه القبلة.',
      );
    }

    // 3. Acquire coordinates with bounded timeout and Android fallbacks.
    final _AcquiredSample sample = await _acquireSampleWithFallback();

    // 4. Reverse geocode coordinates with bounded timeout (preserves coordinates on failure).
    final ReverseGeocodedAddress? address = await _tryReverseGeocode(
      sample.sample.latitude,
      sample.sample.longitude,
    );

    final saved = SavedPrayerLocation(
      latitude: sample.sample.latitude,
      longitude: sample.sample.longitude,
      isoCountryCode: address?.isoCountryCode,
      countryName: address?.countryName,
      city: address?.city,
      district: address?.district,
      timestamp: sample.sample.timestamp,
      source: sample.source,
    );

    await _cache.save(saved);
    return saved;
  }

  /// Attempts to enrich an existing saved location that lacks readable address metadata
  /// using only its saved coordinates (no GPS request).
  Future<SavedPrayerLocation> resolveAddressForSavedLocation(
    SavedPrayerLocation existing,
  ) async {
    if (!existing.hasValidCoordinates) {
      return existing;
    }
    if (existing.hasReadableAddress &&
        existing.isoCountryCode != null &&
        existing.isoCountryCode!.isNotEmpty) {
      return existing;
    }

    final address = await _tryReverseGeocode(
      existing.latitude,
      existing.longitude,
    );
    if (address == null ||
        (!address.hasAnyAddressField && address.isoCountryCode == null)) {
      return existing;
    }

    final updated = existing.copyWith(
      isoCountryCode: address.isoCountryCode ?? existing.isoCountryCode,
      countryName: address.countryName ?? existing.countryName,
      city: address.city ?? existing.city,
      district: address.district ?? existing.district,
    );
    await _cache.save(updated);
    return updated;
  }

  Future<_AcquiredSample> _acquireSampleWithFallback() async {
    // Step A: Primary fresh location request.
    try {
      final primary = await _provider
          .getCurrentPosition(
            accuracy: geolocator.LocationAccuracy.medium,
            forceAndroidLocationManager: false,
            timeLimit: _primaryTimeout,
          )
          .timeout(_primaryTimeout);

      if (isValidWgs84Coordinates(primary.latitude, primary.longitude)) {
        return _AcquiredSample(primary, LocationSourceType.fresh);
      }
      throw const LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.invalidCoordinates,
        arabicMessage: 'تم استلام إحداثيات غير صالحة من نظام تحديد الموقع.',
      );
    } on TimeoutException catch (timeoutError) {
      if (_provider.platform != TargetPlatform.android) {
        throw LocationAcquisitionException(
          reason: LocationAcquisitionFailureReason.timeout,
          arabicMessage:
              'انتهت مهلة تحديد الموقع. يرجى المحاولة في مكان مفتوح أو إعادة المحاولة.',
          cause: timeoutError,
        );
      }
      // On Android, proceed to Step B (LocationManager fallback) and Step C (last-known).
      return _acquireAndroidFallback(timeoutError);
    } on geolocator.LocationServiceDisabledException catch (error) {
      throw LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.serviceDisabled,
        arabicMessage: 'خدمات الموقع غير مفعّلة على الجهاز.',
        cause: error,
      );
    } on geolocator.PermissionDeniedException catch (error) {
      throw LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.permissionDenied,
        arabicMessage: 'تم رفض إذن الوصول إلى الموقع.',
        cause: error,
      );
    }
  }

  Future<_AcquiredSample> _acquireAndroidFallback(
    TimeoutException primaryTimeoutError,
  ) async {
    // Step B: Lower-accuracy Android LocationManager fallback.
    try {
      final fallback = await _provider
          .getCurrentPosition(
            accuracy: geolocator.LocationAccuracy.low,
            forceAndroidLocationManager: true,
            timeLimit: _androidFallbackTimeout,
          )
          .timeout(_androidFallbackTimeout);

      if (isValidWgs84Coordinates(fallback.latitude, fallback.longitude)) {
        return _AcquiredSample(fallback, LocationSourceType.fresh);
      }
    } on TimeoutException {
      // Continue to last-known fallback.
    } on geolocator.LocationServiceDisabledException catch (error) {
      throw LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.serviceDisabled,
        arabicMessage: 'خدمات الموقع غير مفعّلة على الجهاز.',
        cause: error,
      );
    } on geolocator.PermissionDeniedException catch (error) {
      throw LocationAcquisitionException(
        reason: LocationAcquisitionFailureReason.permissionDenied,
        arabicMessage: 'تم رفض إذن الوصول إلى الموقع.',
        cause: error,
      );
    }

    // Step C: Last-known position from available Android providers (recent & valid only).
    final candidates = <RawLocationSample?>[];
    for (final forceLm in const [false, true]) {
      try {
        final lastKnown = await _provider
            .getLastKnownPosition(forceAndroidLocationManager: forceLm)
            .timeout(_lastKnownTimeout);
        candidates.add(lastKnown);
      } on TimeoutException {
        // Bounded timeout: ignore slow provider and try next.
      }
    }

    final currentTime = _now().toUtc();
    RawLocationSample? newestValid;
    for (final candidate in candidates) {
      if (candidate == null) continue;
      if (!isValidWgs84Coordinates(candidate.latitude, candidate.longitude)) {
        continue;
      }
      final age = currentTime.difference(candidate.timestamp.toUtc());
      if (age.isNegative || age > _maxLastKnownAge) {
        continue;
      }
      if (newestValid == null ||
          candidate.timestamp.toUtc().isAfter(newestValid.timestamp.toUtc())) {
        newestValid = candidate;
      }
    }

    if (newestValid != null) {
      return _AcquiredSample(newestValid, LocationSourceType.cached);
    }

    throw LocationAcquisitionException(
      reason: LocationAcquisitionFailureReason.timeout,
      arabicMessage:
          'تعذر الحصول على الموقع ضمن المهلة المحددة. يرجى التأكد من إشارة GPS وإعادة المحاولة.',
      cause: primaryTimeoutError,
    );
  }

  Future<ReverseGeocodedAddress?> _tryReverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      return await _geocoder
          .reverseGeocode(latitude, longitude)
          .timeout(_geocodeTimeout);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }
}

class _AcquiredSample {
  final RawLocationSample sample;
  final LocationSourceType source;

  const _AcquiredSample(this.sample, this.source);
}

