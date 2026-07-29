import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global Settings Manager for app preferences including copy settings, font size, and theme mode.
class SettingsManager {
  static const String _keyCopySource = 'copy_source';
  static const String _keyFontSizeOption = 'font_size_option';
  static const String _keyThemeMode = 'theme_mode_option';
  static const String _keyVibration = 'vibration_option';

  /// ValueNotifier for whether to include source when copying text.
  static final ValueNotifier<bool> copySource = ValueNotifier<bool>(false);

  /// ValueNotifier holding current Dhikr font size option ('صغير', 'متوسط', 'كبير', 'كبير جداً')
  static final ValueNotifier<String> fontSizeOption = ValueNotifier<String>('متوسط');

  /// ValueNotifier holding current Theme Mode option ('فاتح', 'داكن', 'تكيّف حسب النظام')
  static final ValueNotifier<String> themeModeOption = ValueNotifier<String>('فاتح');

  /// ValueNotifier for haptic vibration feedback during count.
  static final ValueNotifier<bool> vibrationOption = ValueNotifier<bool>(true);

  /// Helper getter to convert font size option to double pixel size for Dhikr/Dua text.
  static double get dhikrFontSize {
    switch (fontSizeOption.value) {
      case 'صغير':
        return 18.0;
      case 'كبير':
        return 26.0;
      case 'كبير جداً':
        return 30.0;
      case 'متوسط':
      default:
        return 22.0;
    }
  }

  /// Helper getter for Flutter ThemeMode
  static ThemeMode get themeMode {
    switch (themeModeOption.value) {
      case 'داكن':
        return ThemeMode.dark;
      case 'تكيّف حسب النظام':
        return ThemeMode.system;
      case 'فاتح':
      default:
        return ThemeMode.light;
    }
  }

  /// Initialize settings from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      copySource.value = prefs.getBool(_keyCopySource) ?? false;
      fontSizeOption.value = prefs.getString(_keyFontSizeOption) ?? 'متوسط';
      themeModeOption.value = prefs.getString(_keyThemeMode) ?? 'فاتح';
      vibrationOption.value = prefs.getBool(_keyVibration) ?? true;
    } catch (_) {}
  }

  /// Set and persist vibration option
  static Future<void> setVibrationOption(bool value) async {
    vibrationOption.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVibration, value);
    } catch (_) {}
  }

  /// Toggle or update copy source setting
  static Future<void> setCopySource(bool value) async {
    copySource.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyCopySource, value);
    } catch (_) {}
  }

  /// Set and persist font size option
  static Future<void> setFontSizeOption(String option) async {
    fontSizeOption.value = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyFontSizeOption, option);
    } catch (_) {}
  }

  /// Set and persist theme mode option
  static Future<void> setThemeModeOption(String option) async {
    themeModeOption.value = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyThemeMode, option);
    } catch (_) {}
  }
}
