import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhkar/features/adhkar/presentation/managers/favorites_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FavoritesManager Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FavoritesManager.favoriteDhikrs.value = [];
    });

    test('getItemText - extracts text cleanly from various keys', () {
      expect(
        FavoritesManager.getItemText({'text': '  سبحان الله  '}),
        equals('سبحان الله'),
      );
      expect(
        FavoritesManager.getItemText({'content': 'الحمد لله'}),
        equals('الحمد لله'),
      );
      expect(
        FavoritesManager.getItemText({'dhikr': 'الله أكبر'}),
        equals('الله أكبر'),
      );
      expect(FavoritesManager.getItemText({'title': 'دعاء'}), equals('دعاء'));
      expect(FavoritesManager.getItemText({}), equals(''));
    });

    test('initial state - empty favorites list', () {
      expect(FavoritesManager.favoriteDhikrs.value, isEmpty);
      expect(FavoritesManager.isFavoriteText('سبحان الله'), isFalse);
    });

    test('toggleFavorite - adds item and persists to storage', () async {
      final dhikr = {'id': 1, 'text': 'سُبْحَانَ اللَّهِ'};

      final isNowFav = await FavoritesManager.toggleFavorite(
        null,
        dhikr,
        showSnackBar: false,
      );

      expect(isNowFav, isTrue);
      expect(FavoritesManager.favoriteDhikrs.value.length, equals(1));
      expect(FavoritesManager.isFavorite(dhikr), isTrue);
      expect(FavoritesManager.isFavoriteText('سُبْحَانَ اللَّهِ'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      final storedJson = prefs.getString('favorite_dhikrs');
      expect(storedJson, isNotNull);
      final List<dynamic> parsed = json.decode(storedJson!);
      expect(parsed.length, equals(1));
    });

    test('toggleFavorite - removes item when toggled twice', () async {
      final dhikr = {'id': 1, 'text': 'سُبْحَانَ اللَّهِ'};

      await FavoritesManager.toggleFavorite(null, dhikr, showSnackBar: false);
      expect(FavoritesManager.isFavorite(dhikr), isTrue);

      final isNowFav = await FavoritesManager.toggleFavorite(
        null,
        dhikr,
        showSnackBar: false,
      );

      expect(isNowFav, isFalse);
      expect(FavoritesManager.favoriteDhikrs.value, isEmpty);
      expect(FavoritesManager.isFavorite(dhikr), isFalse);
    });

    test('removeFavorite - removes item directly', () async {
      final dhikr1 = {'text': 'الذكر الأول'};
      final dhikr2 = {'text': 'الذكر الثاني'};

      await FavoritesManager.toggleFavorite(null, dhikr1, showSnackBar: false);
      await FavoritesManager.toggleFavorite(null, dhikr2, showSnackBar: false);
      expect(FavoritesManager.favoriteDhikrs.value.length, equals(2));

      await FavoritesManager.removeFavorite(null, dhikr1, showSnackBar: false);
      expect(FavoritesManager.favoriteDhikrs.value.length, equals(1));
      expect(FavoritesManager.isFavorite(dhikr1), isFalse);
      expect(FavoritesManager.isFavorite(dhikr2), isTrue);
    });

    test('init - loads stored favorites on startup', () async {
      final storedItems = [
        {'text': 'أَسْتَغْفِرُ اللَّهَ'},
        {'text': 'لَا إِلَهَ إِلَّا اللَّهُ'},
      ];
      SharedPreferences.setMockInitialValues({
        'favorite_dhikrs': json.encode(storedItems),
      });

      await FavoritesManager.init();

      expect(FavoritesManager.favoriteDhikrs.value.length, equals(2));
      expect(FavoritesManager.isFavoriteText('أَسْتَغْفِرُ اللَّهَ'), isTrue);
      expect(
        FavoritesManager.isFavoriteText('لَا إِلَهَ إِلَّا اللَّهُ'),
        isTrue,
      );
    });
  });
}
