import 'package:share_plus/share_plus.dart';

/// Helper utility for sharing Dhikr/Dua content via native system share sheet.
class DhikrShareHelper {
  /// Shares a Dhikr or Dua item formatted strictly with source and app attribution.
  static Future<void> shareDhikr(Map<String, dynamic> dhikr) async {
    final String text = (dhikr['text'] ?? dhikr['content'] ?? dhikr['dhikr'] ?? dhikr['title'] ?? '').toString().trim();
    if (text.isEmpty) return;

    final String source = (dhikr['source'] ?? '').toString().trim();

    final StringBuffer buffer = StringBuffer();
    buffer.writeln(text);
    buffer.writeln();

    if (source.isNotEmpty) {
      buffer.writeln('المصدر:');
      buffer.writeln(source);
      buffer.writeln();
    }

    buffer.write('تمت المشاركة عبر تطبيق "مع الرسول ﷺ من الصباح إلى المساء"');

    await Share.share(buffer.toString());
  }
}
