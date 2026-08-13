import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JSON Data Files Integrity Tests', () {
    final List<String> jsonFiles = [
      'assets/json/morning.json',
      'assets/json/evening.json',
      'assets/json/after_prayer.json',
      'assets/json/sleep.json',
      'assets/json/travel.json',
      'assets/json/quran_duas.json',
      'assets/json/prophetic_duas.json',
      'assets/json/forgiveness_duas.json',
    ];

    for (final relativePath in jsonFiles) {
      test('verifies file integrity for $relativePath', () {
        final file = File(relativePath);
        expect(
          file.existsSync(),
          isTrue,
          reason: '$relativePath must exist on disk',
        );

        final content = file.readAsStringSync();
        expect(content, isNotEmpty, reason: '$relativePath must not be empty');

        final dynamic decoded = json.decode(content);
        expect(
          decoded,
          isA<List<dynamic>>(),
          reason: '$relativePath must be a JSON array',
        );

        final List<dynamic> list = decoded as List<dynamic>;
        expect(
          list,
          isNotEmpty,
          reason: '$relativePath array must contain items',
        );

        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          expect(
            item,
            isA<Map<String, dynamic>>(),
            reason: 'Item $i in $relativePath must be an object',
          );

          final map = item as Map<String, dynamic>;
          final text =
              (map['text'] ??
                      map['content'] ??
                      map['dhikr'] ??
                      map['title'] ??
                      '')
                  .toString()
                  .trim();
          expect(
            text,
            isNotEmpty,
            reason: 'Item $i in $relativePath must have non-empty text/content',
          );
        }
      });
    }
  });
}
