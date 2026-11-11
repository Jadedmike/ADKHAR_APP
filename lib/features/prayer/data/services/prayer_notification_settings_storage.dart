import 'dart:convert';
import '../../domain/entities/prayer_notification_settings.dart';
import '../../domain/entities/saved_prayer_location.dart';
import 'prayer_settings_storage.dart';

/// Persistent storage for [PrayerNotificationSettings] and its separate
/// notification-specific coordinate cache.
class PrayerNotificationSettingsStorage {
  static const String storageKey = 'prayer_notification_settings_v1_json';
  static const String notificationLocationCacheKey =
      'prayer_notification_location_v1_json';

  final KeyValueStore _store;

  PrayerNotificationSettingsStorage({KeyValueStore? store})
    : _store = store ?? SharedPreferencesKeyValueStore();

  Future<PrayerNotificationSettings> load() async {
    final raw = await _store.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return PrayerNotificationSettings.defaults();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (error) {
      throw PrayerNotificationFormatException(
        'Malformed JSON in prayer notification settings.',
        error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PrayerNotificationFormatException(
        'Prayer notification settings JSON root must be an object.',
      );
    }

    return PrayerNotificationSettings.fromJson(decoded);
  }

  Future<PrayerNotificationSettings> loadOrDefault() async {
    try {
      return await load();
    } catch (_) {
      return PrayerNotificationSettings.defaults();
    }
  }

  Future<void> save(PrayerNotificationSettings settings) async {
    if (settings.schemaVersion !=
        PrayerNotificationSettings.currentSchemaVersion) {
      throw PrayerNotificationSchemaException(
        'Cannot save unsupported schema version: ${settings.schemaVersion}.',
        foundVersion: settings.schemaVersion,
      );
    }
    try {
      final ok = await _store.setString(
        storageKey,
        jsonEncode(settings.toJson()),
      );
      if (!ok) {
        throw const PrayerNotificationWriteException(
          'Storage backend returned false while saving prayer notification settings.',
        );
      }
    } on PrayerNotificationSettingsException {
      rethrow;
    } catch (error) {
      throw PrayerNotificationWriteException(
        'Failed to write prayer notification settings.',
        error,
      );
    }
  }

  Future<void> resetToDefaults() async {
    await save(PrayerNotificationSettings.defaults());
    await clearCachedNotificationLocation();
  }

  /// Loads the notification-specific cached coordinates (separate from the app's
  /// independent saved prayer location).
  Future<SavedPrayerLocation?> loadCachedNotificationLocation() async {
    try {
      final raw = await _store.getString(notificationLocationCacheKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return SavedPrayerLocation.tryFromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Persists coordinates used specifically for prayer notification scheduling.
  Future<bool> saveCachedNotificationLocation(
    SavedPrayerLocation location,
  ) async {
    try {
      return await _store.setString(
        notificationLocationCacheKey,
        location.toEncodedJson(),
      );
    } catch (_) {
      return false;
    }
  }

  /// Clears ONLY the notification-specific cached coordinates.
  /// Never modifies `prayer_saved_location_v1_json`.
  Future<bool> clearCachedNotificationLocation() async {
    try {
      return await _store.remove(notificationLocationCacheKey);
    } catch (_) {
      return false;
    }
  }
}

