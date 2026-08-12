import 'package:flutter/material.dart';

/// Centralized repository of all final application colors.
/// Light Mode: Warm Beige background (#F8F4EC), Olive Green (#4E5B4E), Gold (#C5A059), Cream Cards (#FFFDF9).
/// Dark Mode: Dark Olive Canvas (#161A15), Dark Secondary (#1F241D), Dark Olive Cards (#262D24), Warm Cream Text (#F6F1E7), Gold (#C9A15B), Olive Accent (#7E8A63).
class AppColors {
  AppColors._();

  // --- LIGHT THEME PALETTE ---
  static const Color primaryLight = Color(0xFF4E5B4E);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color goldLight = Color(0xFFC5A059);
  static const Color backgroundLight = Color(0xFFF8F4EC);
  static const Color secondaryBgLight = Color(0xFFFAF7F0);
  static const Color cardLight = Color(0xFFFFFDF9);
  static const Color surfaceLight = Color(0xFFF7F2E8);
  static const Color textPrimaryLight = Color(0xFF1E281F);
  static const Color textSecondaryLight = Color(0xFF707973);
  static const Color borderLight = Color(0xFFEADFCF);

  // --- DARK THEME PALETTE (Exact Specs) ---
  static const Color primaryDark = Color(
    0xFF2E362C,
  ); // Dark Olive Button (#2E362C)
  static const Color onPrimaryDark = Color(
    0xFFC9A15B,
  ); // Gold text on primary button (#C9A15B)
  static const Color goldDark = Color(0xFFC9A15B); // Gold Accent (#C9A15B)
  static const Color oliveDark = Color(0xFF7E8A63); // Muted Olive (#7E8A63)
  static const Color backgroundDark = Color(
    0xFF161A15,
  ); // Main Background (#161A15)
  static const Color secondaryBgDark = Color(
    0xFF1F241D,
  ); // Secondary Background (#1F241D)
  static const Color cardDark = Color(0xFF262D24); // Card Background (#262D24)
  static const Color surfaceDark = Color(
    0xFF1F241D,
  ); // Secondary Surface (#1F241D)
  static const Color textPrimaryDark = Color(
    0xFFF6F1E7,
  ); // Warm Cream Primary Text (#F6F1E7)
  static const Color textSecondaryDark = Color(
    0xFFD8CEBE,
  ); // Secondary Text (#D8CEBE)
  static const Color borderDark = Color(0xFF353E32); // Dark Border (#353E32)

  // Feedback Colors
  static const Color error = Color(0xFFBA4A4A);
  static const Color success = Color(0xFF4A8B5F);

  /// Helper getter for current theme background color
  static Color background(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? backgroundDark
        : backgroundLight;
  }

  /// Helper getter for current theme card color
  static Color card(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? cardDark
        : cardLight;
  }

  /// Helper getter for current theme surface color
  static Color surface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : surfaceLight;
  }

  /// Helper getter for current theme border color
  static Color border(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? borderDark
        : borderLight;
  }

  /// Helper getter for primary text color
  static Color textPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textPrimaryDark
        : textPrimaryLight;
  }

  /// Helper getter for secondary text color
  static Color textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? textSecondaryDark
        : textSecondaryLight;
  }

  /// Helper getter for gold accent color
  static Color gold(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? goldDark
        : goldLight;
  }

  /// Helper getter for primary button / accent color
  static Color primary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? oliveDark
        : primaryLight;
  }
}
