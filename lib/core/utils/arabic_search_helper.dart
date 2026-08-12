import 'package:flutter/material.dart';

/// Helper utility for normalizing Arabic text and highlighting search matches.
class ArabicSearchHelper {
  static final RegExp _diacriticsRegex = RegExp(
    r'[\u064B-\u0652\u0640\u0653-\u0655\u0670\u0671]',
  );

  /// Normalizes Arabic text by removing diacritics and unifying alef, alef maqsura, and teh marbuta shapes.
  static String normalize(String text) {
    if (text.isEmpty) return '';
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      if (!_diacriticsRegex.hasMatch(char)) {
        if (char == 'أ' || char == 'إ' || char == 'آ') {
          buffer.write('ا');
        } else if (char == 'ى') {
          buffer.write('ي');
        } else if (char == 'ة') {
          buffer.write('ه');
        } else {
          buffer.write(char.toLowerCase());
        }
      }
    }
    return buffer.toString();
  }

  /// Checks if [query] matches anywhere inside [targetText] after normalizing both.
  static bool matches(String targetText, String query) {
    final String cleanQuery = normalize(query.trim());
    if (cleanQuery.isEmpty) return true;
    final String cleanTarget = normalize(targetText);
    return cleanTarget.contains(cleanQuery);
  }

  /// Builds a list of [TextSpan]s highlighting the matched query terms in [text],
  /// preserving original diacritics and text formatting.
  static List<TextSpan> buildHighlightSpans({
    required String text,
    required String query,
    required TextStyle defaultStyle,
    required TextStyle highlightStyle,
  }) {
    if (text.isEmpty) return [];
    final String cleanQuery = normalize(query.trim());
    if (cleanQuery.isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final List<int> normToOrigMap = [];
    final StringBuffer normBuffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      if (!_diacriticsRegex.hasMatch(char)) {
        normToOrigMap.add(i);
        if (char == 'أ' || char == 'إ' || char == 'آ') {
          normBuffer.write('ا');
        } else if (char == 'ى') {
          normBuffer.write('ي');
        } else if (char == 'ة') {
          normBuffer.write('ه');
        } else {
          normBuffer.write(char.toLowerCase());
        }
      }
    }

    normToOrigMap.add(text.length);
    final String cleanText = normBuffer.toString();

    if (cleanText.isEmpty || !cleanText.contains(cleanQuery)) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final List<TextSpan> spans = [];
    int currentOrigIndex = 0;
    int searchFromNormIndex = 0;

    while (searchFromNormIndex < cleanText.length) {
      final int matchNormIndex = cleanText.indexOf(
        cleanQuery,
        searchFromNormIndex,
      );
      if (matchNormIndex == -1) {
        break;
      }

      final int matchNormEnd = matchNormIndex + cleanQuery.length;
      final int origStart = normToOrigMap[matchNormIndex];
      final int origEnd = normToOrigMap[matchNormEnd];

      if (origStart > currentOrigIndex) {
        spans.add(
          TextSpan(
            text: text.substring(currentOrigIndex, origStart),
            style: defaultStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(origStart, origEnd),
          style: highlightStyle,
        ),
      );

      currentOrigIndex = origEnd;
      searchFromNormIndex = matchNormEnd;
    }

    if (currentOrigIndex < text.length) {
      spans.add(
        TextSpan(text: text.substring(currentOrigIndex), style: defaultStyle),
      );
    }

    return spans;
  }
}
