import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data class representing saved reading position state.
class LastReadingPosition {
  final String categoryTitle;
  final String? jsonAssetPath;
  final int index;
  final double scrollOffset;

  const LastReadingPosition({
    required this.categoryTitle,
    this.jsonAssetPath,
    required this.index,
    required this.scrollOffset,
  });
}

/// Global Settings Manager for app preferences including copy settings, font size, theme mode, and reading state.
class SettingsManager {
  static const String _keyCopySource = 'copy_source';
  static const String _keyFontSizeOption = 'font_size_option';
  static const String _keyThemeMode = 'theme_mode_option';
  static const String _keyVibration = 'vibration_option';
  static const String _keyKeepScreenOn = 'keep_screen_on';
  static const String _keyShowSource = 'show_source';
  static const String _keyShowTranslation = 'show_translation';
  static const String _keyMorningReminder = 'morning_reminder';
  static const String _keyEveningReminder = 'evening_reminder';
  static const String _keyDailyReminder = 'daily_reminder';
  static const String _keyRememberLastPosition = 'remember_last_position';
  static const String _keyLastCategoryTitle = 'last_category_title';
  static const String _keyLastDhikrIndex = 'last_dhikr_index';
  static const String _keyLastScrollOffset = 'last_scroll_offset';
  static const String _keyLastJsonAssetPath = 'last_json_asset_path';

  /// ValueNotifier for whether to include source when copying text.
  static final ValueNotifier<bool> copySource = ValueNotifier<bool>(false);

  /// ValueNotifier holding current Dhikr font size option ('صغير', 'متوسط', 'كبير', 'كبير جداً')
  static final ValueNotifier<String> fontSizeOption = ValueNotifier<String>(
    'متوسط',
  );

  /// ValueNotifier holding current Theme Mode option ('فاتح', 'داكن', 'تكيّف حسب النظام')
  static final ValueNotifier<String> themeModeOption = ValueNotifier<String>(
    'فاتح',
  );

  /// ValueNotifier for haptic vibration feedback during count.
  static final ValueNotifier<bool> vibrationOption = ValueNotifier<bool>(true);

  /// ValueNotifier for keeping screen on during reading.
  static final ValueNotifier<bool> keepScreenOn = ValueNotifier<bool>(true);

  /// ValueNotifier for displaying source and reference below Dhikr.
  static final ValueNotifier<bool> showSource = ValueNotifier<bool>(true);

  /// ValueNotifier for displaying translation when available.
  static final ValueNotifier<bool> showTranslation = ValueNotifier<bool>(true);

  /// ValueNotifier for Morning Dhikr reminder.
  static final ValueNotifier<bool> morningReminder = ValueNotifier<bool>(true);

  /// ValueNotifier for Evening Dhikr reminder.
  static final ValueNotifier<bool> eveningReminder = ValueNotifier<bool>(true);

  /// ValueNotifier for Daily Duas reminder.
  static final ValueNotifier<bool> dailyReminder = ValueNotifier<bool>(true);

  /// ValueNotifier for remembering last reading position.
  static final ValueNotifier<bool> rememberLastPosition = ValueNotifier<bool>(
    true,
  );

  static String? _cachedLastCategoryTitle;
  static int _cachedLastDhikrIndex = 0;
  static double _cachedLastScrollOffset = 0.0;
  static String? _cachedLastJsonAssetPath;

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
      keepScreenOn.value = prefs.getBool(_keyKeepScreenOn) ?? true;
      showSource.value = prefs.getBool(_keyShowSource) ?? true;
      showTranslation.value = prefs.getBool(_keyShowTranslation) ?? true;
      morningReminder.value = prefs.getBool(_keyMorningReminder) ?? true;
      eveningReminder.value = prefs.getBool(_keyEveningReminder) ?? true;
      dailyReminder.value = prefs.getBool(_keyDailyReminder) ?? true;
      rememberLastPosition.value =
          prefs.getBool(_keyRememberLastPosition) ?? true;

      _cachedLastCategoryTitle = prefs.getString(_keyLastCategoryTitle);
      _cachedLastJsonAssetPath = prefs.getString(_keyLastJsonAssetPath);
      _cachedLastDhikrIndex = prefs.getInt(_keyLastDhikrIndex) ?? 0;
      _cachedLastScrollOffset = prefs.getDouble(_keyLastScrollOffset) ?? 0.0;
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

  /// Set and persist keep screen on option
  static Future<void> setKeepScreenOn(bool value) async {
    keepScreenOn.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyKeepScreenOn, value);
    } catch (_) {}
  }

  /// Set and persist show source option
  static Future<void> setShowSource(bool value) async {
    showSource.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowSource, value);
    } catch (_) {}
  }

  /// Set and persist show translation option
  static Future<void> setShowTranslation(bool value) async {
    showTranslation.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyShowTranslation, value);
    } catch (_) {}
  }

  /// Set and persist morning reminder option
  static Future<void> setMorningReminder(bool value) async {
    morningReminder.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyMorningReminder, value);
    } catch (_) {}
  }

  /// Set and persist evening reminder option
  static Future<void> setEveningReminder(bool value) async {
    eveningReminder.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyEveningReminder, value);
    } catch (_) {}
  }

  /// Set and persist daily reminder option
  static Future<void> setDailyReminder(bool value) async {
    dailyReminder.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDailyReminder, value);
    } catch (_) {}
  }

  /// Set and persist remember last position option
  static Future<void> setRememberLastPosition(bool value) async {
    rememberLastPosition.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberLastPosition, value);
      if (!value) {
        await clearLastReadingPosition();
      }
    } catch (_) {}
  }

  /// Save last reading position if feature enabled
  static Future<void> saveLastReadingPosition({
    required String categoryTitle,
    String? jsonAssetPath,
    required int index,
    required double scrollOffset,
  }) async {
    if (!rememberLastPosition.value) return;

    _cachedLastCategoryTitle = categoryTitle;
    _cachedLastJsonAssetPath = jsonAssetPath;
    _cachedLastDhikrIndex = index;
    _cachedLastScrollOffset = scrollOffset;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastCategoryTitle, categoryTitle);
      if (jsonAssetPath != null && jsonAssetPath.isNotEmpty) {
        await prefs.setString(_keyLastJsonAssetPath, jsonAssetPath);
      } else {
        await prefs.remove(_keyLastJsonAssetPath);
      }
      await prefs.setInt(_keyLastDhikrIndex, index);
      await prefs.setDouble(_keyLastScrollOffset, scrollOffset);
    } catch (_) {}
  }

  /// Clear saved reading position
  static Future<void> clearLastReadingPosition() async {
    _cachedLastCategoryTitle = null;
    _cachedLastJsonAssetPath = null;
    _cachedLastDhikrIndex = 0;
    _cachedLastScrollOffset = 0.0;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastCategoryTitle);
      await prefs.remove(_keyLastJsonAssetPath);
      await prefs.remove(_keyLastDhikrIndex);
      await prefs.remove(_keyLastScrollOffset);
    } catch (_) {}
  }

  /// Helper to get last reading position if enabled and present
  static LastReadingPosition? getLastReadingPosition() {
    if (!rememberLastPosition.value) return null;
    if (_cachedLastCategoryTitle == null || _cachedLastCategoryTitle!.isEmpty) {
      return null;
    }
    return LastReadingPosition(
      categoryTitle: _cachedLastCategoryTitle!,
      jsonAssetPath: _cachedLastJsonAssetPath,
      index: _cachedLastDhikrIndex,
      scrollOffset: _cachedLastScrollOffset,
    );
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
