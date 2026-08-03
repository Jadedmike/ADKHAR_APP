import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../features/adhkar/presentation/managers/settings_manager.dart';

/// Helper class for copying Dhikr/Dua text to clipboard and displaying feedback SnackBar.
class DhikrCopyHelper {
  static void copyToClipboard(BuildContext context, Map<String, dynamic> dhikr) {
    final String text = (dhikr['text'] ?? dhikr['content'] ?? dhikr['dhikr'] ?? dhikr['title'] ?? '').toString();
    if (text.isEmpty) return;

    String textToCopy = text;
    if (SettingsManager.copySource.value) {
      final String source = (dhikr['source'] ?? '').toString().trim();
      final String reference = (dhikr['reference'] ?? '').toString().trim();
      final List<String> details = [];
      if (source.isNotEmpty) details.add(source);
      if (reference.isNotEmpty && reference != source) details.add(reference);

      if (details.isNotEmpty) {
        textToCopy += '\nالمصدر: ${details.join(' - ')}';
      }
    }

    Clipboard.setData(ClipboardData(text: textToCopy));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFFC5A059),
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'تم نسخ الذكر',
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFDF9),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4E5B4E),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFEADFCF), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
