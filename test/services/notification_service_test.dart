import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/managers/settings_manager.dart';
import 'package:adhkar/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService Scheduling Tests', () {
    setUpAll(() {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    });

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('scheduleMorningNotification calculates target time 2 minutes in future correctly', () async {
      final now = tz.TZDateTime.now(tz.local);
      final futureTime = now.add(const Duration(minutes: 2));

      final testTime = TimeOfDay(hour: futureTime.hour, minute: futureTime.minute);
      await SettingsManager.setMorningTime(testTime);

      expect(SettingsManager.morningTime.value, equals(testTime));
      expect(SettingsManager.morningTime.value.hour, equals(futureTime.hour));
      expect(SettingsManager.morningTime.value.minute, equals(futureTime.minute));
    });

    test('scheduleEveningNotification calculates target time 2 minutes in future correctly', () async {
      final now = tz.TZDateTime.now(tz.local);
      final futureTime = now.add(const Duration(minutes: 2));

      final testTime = TimeOfDay(hour: futureTime.hour, minute: futureTime.minute);
      await SettingsManager.setEveningTime(testTime);

      expect(SettingsManager.eveningTime.value, equals(testTime));
      expect(SettingsManager.eveningTime.value.hour, equals(futureTime.hour));
      expect(SettingsManager.eveningTime.value.minute, equals(futureTime.minute));
    });
  });
}
