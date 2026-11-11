import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/daily_prayer_times.dart';
import '../../domain/entities/prayer_notification_settings.dart';
import '../../domain/entities/prayer_settings.dart';
import '../../domain/entities/saved_prayer_location.dart';
import 'prayer_times_calculator.dart';

/// Abstraction over notification plugin operations for prayer scheduling.
/// Guarantees strict isolation to IDs 5000-5069 and allows pure unit testing.
abstract class PrayerNotificationPlatformGateway {
  TargetPlatform get platform;

  Future<void> ensurePrayerChannelsCreated();
  Future<bool> hasPermissionWithoutPrompt();
  Future<bool> requestPermission();
  Future<bool> canScheduleExactAlarmsWithoutPrompt();
  Future<List<PendingNotificationRequest>> pendingNotificationRequests();
  Future<void> cancelNotification(int id);
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledLocalTime,
    required PrayerNotificationSoundMode soundMode,
    required AndroidScheduleMode androidScheduleMode,
  });
}

/// Default [FlutterLocalNotificationsPlugin]-backed implementation of [PrayerNotificationPlatformGateway].
class LocalNotificationsPrayerGateway
    implements PrayerNotificationPlatformGateway {
  static const String shortChannelId = 'prayer_times_short_channel';
  static const String shortChannelName = 'تنبيهات مواقيت الصلاة';
  static const String shortChannelDescription =
      'تنبيه قصير عند دخول وقت الصلوات المفروضة';

  static const String silentChannelId = 'prayer_times_silent_channel';
  static const String silentChannelName = 'تنبيهات الصلاة الصامتة';
  static const String silentChannelDescription =
      'إشعار صامت بدون صوت عند دخول وقت الصلوات المفروضة';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _channelsCreated = false;

  LocalNotificationsPrayerGateway({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? NotificationService.plugin;

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  Future<void> ensurePrayerChannelsCreated() async {
    if (_channelsCreated) return;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            shortChannelId,
            shortChannelName,
            description: shortChannelDescription,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        await androidImpl.createNotificationChannel(
          const AndroidNotificationChannel(
            silentChannelId,
            silentChannelName,
            description: silentChannelDescription,
            importance: Importance.defaultImportance,
            playSound: false,
            enableVibration: false,
          ),
        );
      }
      _channelsCreated = true;
    } catch (_) {}
  }

  @override
  Future<bool> hasPermissionWithoutPrompt() {
    return NotificationService.hasPermissionWithoutPrompt();
  }

  @override
  Future<bool> requestPermission() {
    return NotificationService.requestPermission();
  }

  @override
  Future<bool> canScheduleExactAlarmsWithoutPrompt() {
    return NotificationService.canScheduleExactAlarmsWithoutPrompt();
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    if (id < PrayerNotificationScheduler.minNotificationId ||
        id > PrayerNotificationScheduler.maxNotificationId) {
      throw RangeError.range(
        id,
        PrayerNotificationScheduler.minNotificationId,
        PrayerNotificationScheduler.maxNotificationId,
        'id',
        'Prayer notification cancellation must stay strictly within 5000-5069.',
      );
    }
    try {
      await _plugin.cancel(id);
    } catch (_) {}
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
    if (id < PrayerNotificationScheduler.minNotificationId ||
        id > PrayerNotificationScheduler.maxNotificationId) {
      throw RangeError.range(
        id,
        PrayerNotificationScheduler.minNotificationId,
        PrayerNotificationScheduler.maxNotificationId,
        'id',
        'Prayer notification ID must stay strictly within 5000-5069.',
      );
    }

    final bool isSilent = soundMode == PrayerNotificationSoundMode.silent;
    final androidDetails = AndroidNotificationDetails(
      isSilent ? silentChannelId : shortChannelId,
      isSilent ? silentChannelName : shortChannelName,
      channelDescription: isSilent
          ? silentChannelDescription
          : shortChannelDescription,
      importance: isSilent ? Importance.defaultImportance : Importance.high,
      priority: isSilent ? Priority.defaultPriority : Priority.high,
      playSound: !isSilent,
      silent: isSilent,
      enableVibration: !isSilent,
    );

    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentBadge: false,
      presentSound: !isSilent,
    );

    final tzDate = tz.TZDateTime.from(scheduledLocalTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      NotificationDetails(android: androidDetails, iOS: darwinDetails),
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}

/// Summary of a prayer notification synchronization run.
class PrayerScheduleResult {
  final int scheduledCount;
  final int skippedPastCount;
  final int cappedByIosLimitCount;
  final AndroidScheduleMode androidScheduleMode;

  const PrayerScheduleResult({
    required this.scheduledCount,
    required this.skippedPastCount,
    required this.cappedByIosLimitCount,
    required this.androidScheduleMode,
  });
}

/// Schedules rolling 7-day local notifications for the 5 obligatory prayers only.
///
/// - Never schedules Sunrise.
/// - Strictly isolated to notification IDs 5000–5069.
/// - Never calls plugin-wide `cancelAll()`.
class PrayerNotificationScheduler {
  static const int minNotificationId = 5000;
  static const int maxNotificationId = 5069;
  static const int rollingDays = 7;
  static const int iosPendingNotificationLimit = 64;

  final PrayerNotificationPlatformGateway _gateway;
  final PrayerTimesCalculator _calculator;
  final DateTime Function() _now;

  PrayerNotificationScheduler({
    PrayerNotificationPlatformGateway? gateway,
    PrayerTimesCalculator? calculator,
    DateTime Function()? now,
  }) : _gateway = gateway ?? LocalNotificationsPrayerGateway(),
       _calculator = calculator ?? PrayerTimesCalculator.instance,
       _now = now ?? DateTime.now;

  /// Computes a deterministic unique notification ID inside 5000..5069.
  /// [dayOffset] must be in 0..6.
  static int notificationIdFor(int dayOffset, ObligatoryPrayer prayer) {
    if (dayOffset < 0 || dayOffset >= rollingDays) {
      throw RangeError.range(dayOffset, 0, rollingDays - 1, 'dayOffset');
    }
    return minNotificationId + (dayOffset * 10) + prayer.index;
  }

  static bool isPrayerNotificationId(int id) {
    return id >= minNotificationId && id <= maxNotificationId;
  }

  /// Cancels ONLY prayer-owned notifications in 5000–5069.
  /// Never touches Adhkar notification IDs (1001, 1002, 2001–2003, 9999).
  Future<void> cancelAllPrayerNotifications() async {
    final pending = await _gateway.pendingNotificationRequests();
    final idsToCancel = <int>{};
    for (final req in pending) {
      if (isPrayerNotificationId(req.id)) {
        idsToCancel.add(req.id);
      }
    }
    // Also sweep the canonical rolling ID slots in case platform pending list omitted any.
    for (int day = 0; day < rollingDays; day++) {
      for (final prayer in ObligatoryPrayer.values) {
        idsToCancel.add(notificationIdFor(day, prayer));
      }
    }

    for (final id in idsToCancel) {
      await _gateway.cancelNotification(id);
    }
  }

  /// Synchronizes the rolling 7-day prayer notification schedule.
  Future<PrayerScheduleResult> scheduleRollingSevenDays({
    required SavedPrayerLocation location,
    required PrayerSettings prayerSettings,
    required PrayerNotificationSettings notificationSettings,
  }) async {
    await cancelAllPrayerNotifications();

    if (!notificationSettings.masterEnabled) {
      return const PrayerScheduleResult(
        scheduledCount: 0,
        skippedPastCount: 0,
        cappedByIosLimitCount: 0,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    final bool hasPermission = await _gateway.hasPermissionWithoutPrompt();
    if (!hasPermission) {
      return const PrayerScheduleResult(
        scheduledCount: 0,
        skippedPastCount: 0,
        cappedByIosLimitCount: 0,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    await _gateway.ensurePrayerChannelsCreated();

    final bool canExact = await _gateway.canScheduleExactAlarmsWithoutPrompt();
    final AndroidScheduleMode scheduleMode = canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    final DateTime localNow = _now().toLocal();
    final DateTime startDay = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
    );

    final pendingAfterCancel = await _gateway.pendingNotificationRequests();
    final int nonPrayerPendingCount = pendingAfterCancel
        .where((req) => !isPrayerNotificationId(req.id))
        .length;

    final int? maxAllowedPrayerNotifications =
        _gateway.platform == TargetPlatform.iOS
        ? math.max(0, iosPendingNotificationLimit - nonPrayerPendingCount)
        : null;

    int scheduledCount = 0;
    int skippedPastCount = 0;
    int cappedByIosLimitCount = 0;

    for (int dayOffset = 0; dayOffset < rollingDays; dayOffset++) {
      final date = DateTime(
        startDay.year,
        startDay.month,
        startDay.day + dayOffset,
      );

      final dailyTimes = _calculator.calculate(
        latitude: location.latitude,
        longitude: location.longitude,
        settings: prayerSettings,
        isoCountryCode: location.isoCountryCode,
        localDate: date,
      );

      // Iterate strictly over the 5 obligatory prayers (never Sunrise).
      for (final prayer in ObligatoryPrayer.values) {
        if (!notificationSettings.isPrayerEnabled(prayer)) {
          continue;
        }

        final scheduledTime = dailyTimes.timeForObligatory(prayer);
        if (!scheduledTime.isAfter(localNow)) {
          skippedPastCount++;
          continue;
        }

        if (maxAllowedPrayerNotifications != null &&
            scheduledCount >= maxAllowedPrayerNotifications) {
          cappedByIosLimitCount++;
          continue;
        }

        final id = notificationIdFor(dayOffset, prayer);
        await _gateway.schedulePrayerNotification(
          id: id,
          title: 'حان الآن وقت صلاة ${prayer.arabicName}',
          body: '${location.displayName} • حيّ على الصلاة',
          scheduledLocalTime: scheduledTime,
          soundMode: notificationSettings.soundMode,
          androidScheduleMode: scheduleMode,
        );
        scheduledCount++;
      }
    }

    return PrayerScheduleResult(
      scheduledCount: scheduledCount,
      skippedPastCount: skippedPastCount,
      cappedByIosLimitCount: cappedByIosLimitCount,
      androidScheduleMode: scheduleMode,
    );
  }
}

