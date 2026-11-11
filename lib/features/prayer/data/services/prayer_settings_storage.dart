import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/prayer_settings.dart';

/// Abstraction over key-value persistence to allow deterministic unit testing.
abstract class KeyValueStore {
  Future<String?> getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
}

/// Default [SharedPreferences]-backed implementation of [KeyValueStore].
class SharedPreferencesKeyValueStore implements KeyValueStore {
  final Future<SharedPreferences> Function() _prefsProvider;

  SharedPreferencesKeyValueStore({
    Future<SharedPreferences> Function()? prefsProvider,
  }) : _prefsProvider = prefsProvider ?? SharedPreferences.getInstance;

  @override
  Future<String?> getString(String key) async {
    final prefs = await _prefsProvider();
    return prefs.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    final prefs = await _prefsProvider();
    return prefs.setString(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _prefsProvider();
    return prefs.remove(key);
  }
}

/// Persistent storage service for [PrayerSettings].
class PrayerSettingsStorage {
  static const String storageKey = 'prayer_settings_v1_json';

  final KeyValueStore _store;

  PrayerSettingsStorage({KeyValueStore? store})
    : _store = store ?? SharedPreferencesKeyValueStore();

  /// Loads and validates [PrayerSettings] from storage.
  ///
  /// Returns [PrayerSettings.defaults] when no value has been saved yet.
  /// Throws [PrayerSettingsException] on storage read failure, malformed JSON,
  /// invalid fields, or unsupported schema versions.
  Future<PrayerSettings> load() async {
    final String? rawJson;
    try {
      rawJson = await _store.getString(storageKey);
    } catch (error) {
      throw PrayerSettingsReadException(
        'Failed to read prayer settings from storage.',
        error,
      );
    }

    if (rawJson == null || rawJson.trim().isEmpty) {
      return PrayerSettings.defaults();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException catch (error) {
      throw PrayerSettingsFormatException(
        'Malformed JSON in prayer settings.',
        error,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const PrayerSettingsFormatException(
        'Prayer settings JSON root must be an object.',
      );
    }

    return PrayerSettings.fromJson(decoded);
  }

  /// Safely loads settings, falling back to [PrayerSettings.defaults] if stored data is corrupted.
  Future<PrayerSettings> loadOrDefault() async {
    try {
      return await load();
    } on PrayerSettingsException {
      return PrayerSettings.defaults();
    }
  }

  /// Persists [settings] to storage.
  /// Throws [PrayerSettingsWriteException] if persistence fails.
  Future<void> save(PrayerSettings settings) async {
    if (settings.schemaVersion != PrayerSettings.currentSchemaVersion) {
      throw PrayerSettingsSchemaException(
        'Cannot save unsupported schema version: ${settings.schemaVersion}.',
        foundVersion: settings.schemaVersion,
      );
    }

    final String encoded = jsonEncode(settings.toJson());
    try {
      final bool ok = await _store.setString(storageKey, encoded);
      if (!ok) {
        throw const PrayerSettingsWriteException(
          'Storage backend returned false while saving prayer settings.',
        );
      }
    } on PrayerSettingsException {
      rethrow;
    } catch (error) {
      throw PrayerSettingsWriteException(
        'Failed to write prayer settings to storage.',
        error,
      );
    }
  }
}

