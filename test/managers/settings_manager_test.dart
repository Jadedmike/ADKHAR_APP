import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/managers/settings_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsManager Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SettingsManager.fontSizeOption.value = 'متوسط';
      SettingsManager.themeModeOption.value = 'فاتح';
      SettingsManager.vibrationOption.value = true;
      SettingsManager.keepScreenOn.value = true;
      SettingsManager.showSource.value = true;
      SettingsManager.rememberLastPosition.value = true;
    });

    test('default settings values', () {
      expect(SettingsManager.fontSizeOption.value, equals('متوسط'));
      expect(SettingsManager.dhikrFontSize, equals(22.0));
      expect(SettingsManager.themeModeOption.value, equals('فاتح'));
      expect(SettingsManager.themeMode, equals(ThemeMode.light));
      expect(SettingsManager.vibrationOption.value, isTrue);
      expect(SettingsManager.keepScreenOn.value, isTrue);
      expect(SettingsManager.rememberLastPosition.value, isTrue);
      expect(SettingsManager.morningTime.value, equals(const TimeOfDay(hour: 6, minute: 0)));
      expect(SettingsManager.eveningTime.value, equals(const TimeOfDay(hour: 17, minute: 0)));
    });

    test('setMorningTime & setEveningTime - updates value and persists', () async {
      await SettingsManager.setMorningTime(const TimeOfDay(hour: 8, minute: 30));
      expect(SettingsManager.morningTime.value, equals(const TimeOfDay(hour: 8, minute: 30)));

      await SettingsManager.setEveningTime(const TimeOfDay(hour: 19, minute: 15));
      expect(SettingsManager.eveningTime.value, equals(const TimeOfDay(hour: 19, minute: 15)));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('morning_time_hour'), equals(8));
      expect(prefs.getInt('morning_time_minute'), equals(30));
      expect(prefs.getInt('evening_time_hour'), equals(19));
      expect(prefs.getInt('evening_time_minute'), equals(15));
    });

    test(
      'setFontSizeOption - updates value, calculates font size double, and persists',
      () async {
        await SettingsManager.setFontSizeOption('صغير');
        expect(SettingsManager.fontSizeOption.value, equals('صغير'));
        expect(SettingsManager.dhikrFontSize, equals(18.0));

        await SettingsManager.setFontSizeOption('كبير');
        expect(SettingsManager.dhikrFontSize, equals(26.0));

        await SettingsManager.setFontSizeOption('كبير جداً');
        expect(SettingsManager.dhikrFontSize, equals(30.0));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('font_size_option'), equals('كبير جداً'));
      },
    );

    test(
      'setThemeModeOption - updates value, converts to ThemeMode, and persists',
      () async {
        await SettingsManager.setThemeModeOption('داكن');
        expect(SettingsManager.themeModeOption.value, equals('داكن'));
        expect(SettingsManager.themeMode, equals(ThemeMode.dark));

        await SettingsManager.setThemeModeOption('تكيّف حسب النظام');
        expect(SettingsManager.themeMode, equals(ThemeMode.system));

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('theme_mode_option'),
          equals('تكيّف حسب النظام'),
        );
      },
    );

    test('setVibrationOption - updates value and persists', () async {
      await SettingsManager.setVibrationOption(false);
      expect(SettingsManager.vibrationOption.value, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('vibration_option'), isFalse);
    });

    test('init - loads stored preferences correctly', () async {
      SharedPreferences.setMockInitialValues({
        'font_size_option': 'كبير',
        'theme_mode_option': 'داكن',
        'vibration_option': false,
        'remember_last_position': false,
        'morning_time_hour': 7,
        'morning_time_minute': 15,
        'evening_time_hour': 18,
        'evening_time_minute': 45,
      });

      await SettingsManager.init();

      expect(SettingsManager.fontSizeOption.value, equals('كبير'));
      expect(SettingsManager.dhikrFontSize, equals(26.0));
      expect(SettingsManager.themeModeOption.value, equals('داكن'));
      expect(SettingsManager.themeMode, equals(ThemeMode.dark));
      expect(SettingsManager.vibrationOption.value, isFalse);
      expect(SettingsManager.rememberLastPosition.value, isFalse);
      expect(SettingsManager.morningTime.value, equals(const TimeOfDay(hour: 7, minute: 15)));
      expect(SettingsManager.eveningTime.value, equals(const TimeOfDay(hour: 18, minute: 45)));
    });
  });
}
