import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized repository of all final typography.
/// Uses 'Cairo' as the primary Arabic UI font and 'Noto Naskh Arabic'
/// for Quranic verses, Hadith, and long scriptural texts.
class AppTypography {
  AppTypography._();

  // Font Families configured via Google Fonts
  static final String primaryFont = GoogleFonts.cairo().fontFamily ?? 'Roboto';
  static final String scriptureFont =
      GoogleFonts.notoNaskhArabic().fontFamily ?? 'Georgia';

  // Compatibility getter for theme configurations
  static String get uiFontFamily => primaryFont;

  /// Standard Arabic scriptural typography configured for Quran, Hadith and long Arabic text.
  /// Incorporates Noto Naskh Arabic with an expanded line height to cleanly display Tashkeel.
  static TextStyle scripture({
    double fontSize = 24,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double height = 2.0,
  }) => TextStyle(
    fontFamily: scriptureFont,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );

  // --- Display Styles (using Cairo) ---
  static TextStyle get displayLarge => TextStyle(
    fontFamily: primaryFont,
    fontSize: 57,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get displayMedium => TextStyle(
    fontFamily: primaryFont,
    fontSize: 45,
    fontWeight: FontWeight.bold,
  );

  static TextStyle get displaySmall => TextStyle(
    fontFamily: primaryFont,
    fontSize: 36,
    fontWeight: FontWeight.bold,
  );

  // --- Headline Styles (using Cairo) ---
  static TextStyle get headlineLarge => TextStyle(
    fontFamily: primaryFont,
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headlineMedium => TextStyle(
    fontFamily: primaryFont,
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headlineSmall => TextStyle(
    fontFamily: primaryFont,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  // --- Title Styles (using Cairo) ---
  static TextStyle get titleLarge => TextStyle(
    fontFamily: primaryFont,
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleMedium => TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get titleSmall => TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  // --- Body Styles (using Cairo) ---
  static TextStyle get bodyLarge => TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // --- Caption Style (using Cairo) ---
  static TextStyle get caption => TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // --- Button Text Style (using Cairo) ---
  static TextStyle get button => TextStyle(
    fontFamily: primaryFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // --- Label Styles (using Cairo) for Material 3 Compatibility ---
  static TextStyle get labelLarge => TextStyle(
    fontFamily: primaryFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: primaryFont,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: primaryFont,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
