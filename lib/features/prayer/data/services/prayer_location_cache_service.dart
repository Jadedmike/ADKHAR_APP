import 'dart:convert';
import '../../domain/entities/saved_prayer_location.dart';
import 'prayer_settings_storage.dart';

/// Persistent cache for the user's saved prayer & Qibla location.
///
/// Uses an independent storage key (`prayer_saved_location_v1_json`) completely
/// decoupled from prayer notification settings.
class PrayerLocationCacheService {
  static const String storageKey = 'prayer_saved_location_v1_json';

  final KeyValueStore _store;

  PrayerLocationCacheService({KeyValueStore? store})
    : _store = store ?? SharedPreferencesKeyValueStore();

  static final PrayerLocationCacheService instance =
      PrayerLocationCacheService();

  /// Loads the saved location if present and valid; otherwise returns `null`.
  Future<SavedPrayerLocation?> load() async {
    try {
      final raw = await _store.getString(storageKey);
      if (raw == null || raw.trim().isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      return SavedPrayerLocation.tryFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Saves [location] to persistent storage.
  Future<bool> save(SavedPrayerLocation location) async {
    try {
      return await _store.setString(storageKey, location.toEncodedJson());
    } catch (_) {
      return false;
    }
  }

  /// Clears the saved location cache.
  Future<bool> clear() async {
    try {
      return await _store.remove(storageKey);
    } catch (_) {
      return false;
    }
  }
}

