import 'package:flutter/material.dart';

/// Centralized repository of all final shadows.
/// Uses soft, low-opacity shadows tinted with the primary olive green color
/// to avoid harsh artificial dark shadows and look organic and premium.
class AppShadows {
  AppShadows._();

  // Shadow color tinted with olive-green to merge naturally with warm beige backgrounds
  static const Color _shadowColorLight = Color(0x0A3E5042); // 4% Olive Green
  static const Color _shadowColorMedium = Color(0x0F3E5042); // 6% Olive Green
  static const Color _shadowColorHigh = Color(0x143E5042); // 8% Olive Green

  // Dark mode shadow colors (softer, deep warm glow)
  static const Color _shadowColorDark = Color(0x3D000000); 

  static List<BoxShadow> get low => [
        const BoxShadow(
          color: _shadowColorLight,
          offset: Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get medium => [
        const BoxShadow(
          color: _shadowColorMedium,
          offset: Offset(0, 8),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get high => [
        const BoxShadow(
          color: _shadowColorHigh,
          offset: Offset(0, 16),
          blurRadius: 32,
          spreadRadius: -8,
        ),
      ];

  // Exposes shadow styles for dark theme custom widgets
  static List<BoxShadow> get darkLow => [
        const BoxShadow(
          color: _shadowColorDark,
          offset: Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];
}
