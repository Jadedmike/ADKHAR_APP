import 'package:flutter/foundation.dart';
import '../../data/services/prayer_location_cache_service.dart';
import '../../data/services/prayer_notification_scheduler.dart';
import '../../data/services/prayer_notification_settings_storage.dart';
import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_notification_settings.dart';
import '../../domain/entities/saved_prayer_location.dart';
import '../managers/prayer_settings_manager.dart';

/// Coordinates prayer notification settings, permission gating, notification
/// coordinate cache lifecycle, and rolling 7-day OS schedule synchronization.
class PrayerNotificationManager {
  final PrayerNotificationSettingsStorage _storage;
  final PrayerNotificationScheduler _scheduler;
  final PrayerNotificationPlatformGateway _gateway;
  final PrayerSettingsManager _prayerSettingsManager;
  final PrayerLocationCacheService _locationCache;

  final ValueNotifier<PrayerNotificationSettings> current;

  PrayerNotificationManager({
    PrayerNotificationSettingsStorage? storage,
    PrayerNotificationScheduler? scheduler,
    PrayerNotificationPlatformGateway? gateway,
    PrayerSettingsManager? prayerSettingsManager,
    PrayerLocationCacheService? locationCache,
    PrayerNotificationSettings? initialSettings,
  }) : _storage = storage ?? PrayerNotificationSettingsStorage(),
       _gateway = gateway ?? LocalNotificationsPrayerGateway(),
       _prayerSettingsManager =
           prayerSettingsManager ?? PrayerSettingsManager.instance,
       _locationCache = locationCache ?? PrayerLocationCacheService.instance,
       _scheduler =
           scheduler ??
           PrayerNotificationScheduler(
             gateway: gateway ?? LocalNotificationsPrayerGateway(),
           ),
       current = ValueNotifier<PrayerNotificationSettings>(
         initialSettings ?? PrayerNotificationSettings.defaults(),
       );

  static final PrayerNotificationManager instance = PrayerNotificationManager();

  PrayerNotificationSettings get value => current.value;

  /// Non-blocking startup synchronization called after `NotificationService.init()`.
  ///
  /// - Uses ONLY previously saved coordinates (never requests GPS).
  /// - Never requests notification or location permissions at startup.
  Future<void> syncOnStartup() async {
    try {
      await _prayerSettingsManager.loadSafely();
      final settings = await _storage.loadOrDefault();
      current.value = settings;

      if (!settings.masterEnabled) {
        await _scheduler.cancelAllPrayerNotifications();
        await _storage.clearCachedNotificationLocation();
        return;
      }

      final hasPermission = await _gateway.hasPermissionWithoutPrompt();
      if (!hasPermission) {
        await _scheduler.cancelAllPrayerNotifications();
        return;
      }

      final SavedPrayerLocation? location =
          await _storage.loadCachedNotificationLocation() ??
          await _locationCache.load();
      if (location == null || !location.hasValidCoordinates) {
        return;
      }

      await _storage.saveCachedNotificationLocation(location);
      await _scheduler.scheduleRollingSevenDays(
        location: location,
        prayerSettings: _prayerSettingsManager.value,
        notificationSettings: settings,
      );
    } catch (_) {
      // Never crash or block app startup on non-critical notification sync.
    }
  }

  /// Loads stored notification settings into [current].
  Future<PrayerNotificationSettings> loadSafely() async {
    final loaded = await _storage.loadOrDefault();
    current.value = loaded;
    return loaded;
  }

  /// Checks whether notification permission is already granted without prompting.
  Future<bool> hasPermissionWithoutPrompt() {
    return _gateway.hasPermissionWithoutPrompt();
  }

  /// Requests OS notification permission (call only after explicit Arabic explanation).
  Future<bool> requestPermission() {
    return _gateway.requestPermission();
  }

  /// Enables or disables master prayer notifications.
  ///
  /// When enabling, caller must have explained permission in Arabic; this checks
  /// or requests permission if [requestPermissionIfNeeded] is true.
  /// When disabling, cancels ONLY prayer notifications (5000–5069) and removes
  /// the notification-specific cached coordinates (preserving app saved location).
  Future<bool> setMasterEnabled(
    bool enabled, {
    bool requestPermissionIfNeeded = true,
  }) async {
    if (!enabled) {
      final next = current.value.copyWith(masterEnabled: false);
      await _storage.save(next);
      current.value = next;
      await _scheduler.cancelAllPrayerNotifications();
      await _storage.clearCachedNotificationLocation();
      return true;
    }

    bool granted = await _gateway.hasPermissionWithoutPrompt();
    if (!granted && requestPermissionIfNeeded) {
      granted = await _gateway.requestPermission();
    }
    if (!granted) {
      final disabled = current.value.copyWith(masterEnabled: false);
      await _storage.save(disabled);
      current.value = disabled;
      await _scheduler.cancelAllPrayerNotifications();
      return false;
    }

    final next = current.value.copyWith(masterEnabled: true);
    await _storage.save(next);
    current.value = next;
    await resyncWithSavedLocation();
    return true;
  }

  Future<void> setPrayerEnabled(ObligatoryPrayer prayer, bool enabled) async {
    final next = current.value.withPrayerEnabled(prayer, enabled);
    await _storage.save(next);
    current.value = next;
    await resyncWithSavedLocation();
  }

  Future<void> setSoundMode(PrayerNotificationSoundMode mode) async {
    final next = current.value.copyWith(soundMode: mode);
    await _storage.save(next);
    current.value = next;
    await resyncWithSavedLocation();
  }

  /// Resets prayer notification settings to default (disabled) and clears
  /// notification-specific cached coordinates without touching the app's saved location.
  Future<void> resetSettings() async {
    await _storage.resetToDefaults();
    current.value = PrayerNotificationSettings.defaults();
    await _scheduler.cancelAllPrayerNotifications();
  }

  /// Resynchronizes prayer notifications whenever prayer calculation settings
  /// or saved location change. Never acquires GPS.
  Future<PrayerScheduleResult?> resyncWithSavedLocation({
    SavedPrayerLocation? explicitLocation,
  }) async {
    if (!current.value.masterEnabled) {
      await _scheduler.cancelAllPrayerNotifications();
      return null;
    }

    final location =
        explicitLocation ??
        await _locationCache.load() ??
        await _storage.loadCachedNotificationLocation();

    if (location == null || !location.hasValidCoordinates) {
      return null;
    }

    await _storage.saveCachedNotificationLocation(location);
    return _scheduler.scheduleRollingSevenDays(
      location: location,
      prayerSettings: _prayerSettingsManager.value,
      notificationSettings: current.value,
    );
  }
}

