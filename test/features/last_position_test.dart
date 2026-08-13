import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/managers/settings_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Last Reading Position Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SettingsManager.rememberLastPosition.value = true;
      SettingsManager.clearLastReadingPosition();
    });

    test(
      'saveLastReadingPosition & getLastReadingPosition - saves and retrieves position correctly',
      () async {
        await SettingsManager.saveLastReadingPosition(
          categoryTitle: 'أذكار الصباح',
          jsonAssetPath: 'assets/json/morning.json',
          index: 5,
          scrollOffset: 120.5,
        );

        final pos = SettingsManager.getLastReadingPosition();
        expect(pos, isNotNull);
        expect(pos!.categoryTitle, equals('أذكار الصباح'));
        expect(pos.jsonAssetPath, equals('assets/json/morning.json'));
        expect(pos.index, equals(5));
        expect(pos.scrollOffset, equals(120.5));
      },
    );

    test('clearLastReadingPosition - removes saved position', () async {
      await SettingsManager.saveLastReadingPosition(
        categoryTitle: 'أذكار المساء',
        jsonAssetPath: 'assets/json/evening.json',
        index: 2,
        scrollOffset: 50.0,
      );
      expect(SettingsManager.getLastReadingPosition(), isNotNull);

      await SettingsManager.clearLastReadingPosition();
      expect(SettingsManager.getLastReadingPosition(), isNull);
    });

    test(
      'disabling rememberLastPosition clears saved position and returns null',
      () async {
        await SettingsManager.saveLastReadingPosition(
          categoryTitle: 'أذكار النوم',
          jsonAssetPath: 'assets/json/sleep.json',
          index: 3,
          scrollOffset: 80.0,
        );
        expect(SettingsManager.getLastReadingPosition(), isNotNull);

        await SettingsManager.setRememberLastPosition(false);
        expect(SettingsManager.rememberLastPosition.value, isFalse);
        expect(SettingsManager.getLastReadingPosition(), isNull);
      },
    );

    test(
      'init - loads stored last reading position from SharedPreferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'remember_last_position': true,
          'last_category_title': 'أذكار بعد الصلاة',
          'last_json_asset_path': 'assets/json/after_prayer.json',
          'last_dhikr_index': 7,
          'last_scroll_offset': 200.0,
        });

        await SettingsManager.init();

        final pos = SettingsManager.getLastReadingPosition();
        expect(pos, isNotNull);
        expect(pos!.categoryTitle, equals('أذكار بعد الصلاة'));
        expect(pos.jsonAssetPath, equals('assets/json/after_prayer.json'));
        expect(pos.index, equals(7));
        expect(pos.scrollOffset, equals(200.0));
      },
    );
  });
}
