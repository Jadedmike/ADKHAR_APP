import 'package:flutter/material.dart';

/// Centralized repository of spacing sizes (gaps, margins, padding).
/// This prevents hardcoded double values for gaps or layouts.
class AppSpacing {
  AppSpacing._();

  // Spacing sizes
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Horizontal SizedBoxes for padding/spacing in rows
  static const SizedBox gapH4 = SizedBox(width: xs);
  static const SizedBox gapH8 = SizedBox(width: sm);
  static const SizedBox gapH16 = SizedBox(width: md);
  static const SizedBox gapH24 = SizedBox(width: lg);
  static const SizedBox gapH32 = SizedBox(width: xl);
  static const SizedBox gapH48 = SizedBox(width: xxl);

  // Vertical SizedBoxes for padding/spacing in columns
  static const SizedBox gapV4 = SizedBox(height: xs);
  static const SizedBox gapV8 = SizedBox(height: sm);
  static const SizedBox gapV16 = SizedBox(height: md);
  static const SizedBox gapV24 = SizedBox(height: lg);
  static const SizedBox gapV32 = SizedBox(height: xl);
  static const SizedBox gapV48 = SizedBox(height: xxl);
}
