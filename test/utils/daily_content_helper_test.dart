import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/utils/daily_content_helper.dart';

void main() {
  group('DailyContentHelper Unit Tests', () {
    test('calculateDayOfYear - correctly calculates day of year', () {
      final jan1 = DateTime(2026, 1, 1);
      expect(DailyContentHelper.getDayOfYear(jan1), equals(1));

      final aug24 = DateTime(2026, 8, 24);
      expect(DailyContentHelper.getDayOfYear(aug24), equals(236));
    });

    test('deterministic content selection - same date produces exact same items', () {
      final date = DateTime(2026, 8, 24);

      final dhikr1 = DailyContentHelper.getDhikrOfTheDay(date);
      final dhikr2 = DailyContentHelper.getDhikrOfTheDay(date);
      expect(dhikr1.text, equals(dhikr2.text));
      expect(dhikr1.source, equals(dhikr2.source));

      final dua1 = DailyContentHelper.getDuaOfTheDay(date);
      final dua2 = DailyContentHelper.getDuaOfTheDay(date);
      expect(dua1.text, equals(dua2.text));
      expect(dua1.source, equals(dua2.source));

      final ayah1 = DailyContentHelper.getAyahOfTheDay(date);
      final ayah2 = DailyContentHelper.getAyahOfTheDay(date);
      expect(ayah1.text, equals(ayah2.text));
      expect(ayah1.source, equals(ayah2.source));
    });

    test('date transition - next calendar day changes mapped indices & items', () {
      final today = DateTime(2026, 8, 24);
      final tomorrow = DateTime(2026, 8, 25);

      final todayDhikrIndex = DailyContentHelper.getDhikrIndex(today);
      final tomorrowDhikrIndex = DailyContentHelper.getDhikrIndex(tomorrow);
      expect(todayDhikrIndex, isNot(equals(tomorrowDhikrIndex)));

      final todayDuaIndex = DailyContentHelper.getDuaIndex(today);
      final tomorrowDuaIndex = DailyContentHelper.getDuaIndex(tomorrow);
      expect(todayDuaIndex, isNot(equals(tomorrowDuaIndex)));

      final todayAyahIndex = DailyContentHelper.getAyahIndex(today);
      final tomorrowAyahIndex = DailyContentHelper.getAyahIndex(tomorrow);
      expect(todayAyahIndex, isNot(equals(tomorrowAyahIndex)));
    });

    test('print today mapping for verification report', () {
      final date = DateTime(2026, 8, 24);
      final dayOfYear = DailyContentHelper.getDayOfYear(date);

      final dhikrIndex = DailyContentHelper.getDhikrIndex(date);
      final dhikrItem = DailyContentHelper.getDhikrOfTheDay(date);

      final duaIndex = DailyContentHelper.getDuaIndex(date);
      final duaItem = DailyContentHelper.getDuaOfTheDay(date);

      final ayahIndex = DailyContentHelper.getAyahIndex(date);
      final ayahItem = DailyContentHelper.getAyahOfTheDay(date);

      final quoteIndex = DailyContentHelper.getQuoteIndex(date);
      final quoteItem = DailyContentHelper.getQuoteOfTheDay(date);

      print('--- DAILY MAPPING REPORT (2026-08-24) ---');
      print('Day of Year: $dayOfYear');
      print('Dhikr Index: $dhikrIndex -> "${dhikrItem.text}" (${dhikrItem.source})');
      print('Dua Index: $duaIndex -> "${duaItem.text}" (${duaItem.source})');
      print('Ayah Index: $ayahIndex -> "${ayahItem.text}" (${ayahItem.source})');
      print('Quote Index: $quoteIndex -> "${quoteItem.text}" (${quoteItem.source})');

      expect(dayOfYear, equals(236));
    });
  });
}
