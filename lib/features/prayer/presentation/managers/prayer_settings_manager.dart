import 'package:flutter/foundation.dart';
import '../../data/services/prayer_settings_storage.dart';
import '../../domain/entities/prayer_calculation_method.dart';
import '../../domain/entities/prayer_madhab.dart';
import '../../domain/entities/prayer_settings.dart';

/// Reactive controller managing [PrayerSettings] with atomic write-before-mutate semantics.
///
/// If persisting a change fails, the in-memory [current] value is preserved
/// unchanged and the typed [PrayerSettingsException] is rethrown to the caller.
class PrayerSettingsManager {
  final PrayerSettingsStorage _storage;
  final ValueNotifier<PrayerSettings> current;

  PrayerSettingsManager({
    PrayerSettingsStorage? storage,
    PrayerSettings? initialSettings,
  }) : _storage = storage ?? PrayerSettingsStorage(),
       current = ValueNotifier<PrayerSettings>(
         initialSettings ?? PrayerSettings.defaults(),
       );

  static final PrayerSettingsManager instance = PrayerSettingsManager();

  PrayerSettings get value => current.value;

  /// Loads stored settings into [current].
  /// Throws [PrayerSettingsException] if stored data is invalid or unreadable.
  Future<PrayerSettings> load() async {
    final loaded = await _storage.load();
    current.value = loaded;
    return loaded;
  }

  /// Loads stored settings or resets [current] to defaults if storage is corrupted.
  Future<PrayerSettings> loadSafely() async {
    final loaded = await _storage.loadOrDefault();
    current.value = loaded;
    return loaded;
  }

  /// Persists [next] first, updating [current] only after storage succeeds.
  Future<void> updateSettings(PrayerSettings next) async {
    await _storage.save(next);
    current.value = next;
  }

  Future<void> setCalculationMode(PrayerCalculationMode mode) {
    return updateSettings(current.value.copyWith(calculationMode: mode));
  }

  Future<void> setManualMethod(PrayerCalculationMethod method) {
    return updateSettings(current.value.copyWith(manualMethod: method));
  }

  Future<void> setMadhab(PrayerMadhab madhab) {
    return updateSettings(current.value.copyWith(madhab: madhab));
  }

  void dispose() {
    current.dispose();
  }
}

