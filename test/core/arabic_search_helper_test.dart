import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:adhkar/core/utils/arabic_search_helper.dart';

void main() {
  group('ArabicSearchHelper Unit Tests', () {
    test('normalize - removes diacritics correctly', () {
      const textWithTashkeel = 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ';
      final normalized = ArabicSearchHelper.normalize(textWithTashkeel);
      expect(normalized, equals('اصبحنا واصبح الملك لله'));
    });

    test('normalize - unifies alef variations (أ, إ, آ -> ا)', () {
      expect(ArabicSearchHelper.normalize('أحمد'), equals('احمد'));
      expect(ArabicSearchHelper.normalize('إحسان'), equals('احسان'));
      expect(ArabicSearchHelper.normalize('آمن'), equals('امن'));
    });

    test(
      'normalize - unifies alef maqsura (ى -> ي) and teh marbuta (ة -> ه)',
      () {
        expect(ArabicSearchHelper.normalize('على'), equals('علي'));
        expect(ArabicSearchHelper.normalize('الجمعة'), equals('الجمعه'));
      },
    );

    test('normalize - converts English text to lowercase', () {
      expect(ArabicSearchHelper.normalize('ADHKAR App'), equals('adhkar app'));
    });

    test('normalize - handles empty string', () {
      expect(ArabicSearchHelper.normalize(''), equals(''));
    });

    test(
      'matches - returns true for exact and partial diacritic-insensitive matches',
      () {
        const text = 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ';

        expect(ArabicSearchHelper.matches(text, 'سُبْحَانَ'), isTrue);
        expect(ArabicSearchHelper.matches(text, 'سبحان'), isTrue);
        expect(ArabicSearchHelper.matches(text, 'حمد'), isTrue);
        expect(ArabicSearchHelper.matches('أَصْبَحْنَا', 'اصبحنا'), isTrue);
      },
    );

    test('matches - returns true when query is empty or whitespace', () {
      const text = 'اللَّهُمَّ أَنتَ رَبِّي';
      expect(ArabicSearchHelper.matches(text, ''), isTrue);
      expect(ArabicSearchHelper.matches(text, '   '), isTrue);
    });

    test('matches - returns false when query does not match', () {
      const text = 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ';
      expect(ArabicSearchHelper.matches(text, 'المساء'), isFalse);
    });

    test(
      'buildHighlightSpans - highlights matching text while preserving original text',
      () {
        const originalText = 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ';
        const query = 'اصبحنا';
        const defaultStyle = TextStyle(color: Colors.black);
        const highlightStyle = TextStyle(color: Color(0xFFFFD700));

        final spans = ArabicSearchHelper.buildHighlightSpans(
          text: originalText,
          query: query,
          defaultStyle: defaultStyle,
          highlightStyle: highlightStyle,
        );

        expect(spans, isNotEmpty);
        expect(spans.first.text, equals('أَصْبَحْنَا'));
        expect(spans.first.style, equals(highlightStyle));
      },
    );

    test(
      'buildHighlightSpans - returns single default span when query is empty or no match',
      () {
        const text = 'أَصْبَحْنَا';
        const defaultStyle = TextStyle(color: Colors.black);
        const highlightStyle = TextStyle(color: Color(0xFFFFD700));

        final emptyQuerySpans = ArabicSearchHelper.buildHighlightSpans(
          text: text,
          query: '',
          defaultStyle: defaultStyle,
          highlightStyle: highlightStyle,
        );
        expect(emptyQuerySpans.length, equals(1));
        expect(emptyQuerySpans.first.text, equals(text));
        expect(emptyQuerySpans.first.style, equals(defaultStyle));

        final noMatchSpans = ArabicSearchHelper.buildHighlightSpans(
          text: text,
          query: 'مختلف',
          defaultStyle: defaultStyle,
          highlightStyle: highlightStyle,
        );
        expect(noMatchSpans.length, equals(1));
        expect(noMatchSpans.first.text, equals(text));
        expect(noMatchSpans.first.style, equals(defaultStyle));
      },
    );
  });
}
