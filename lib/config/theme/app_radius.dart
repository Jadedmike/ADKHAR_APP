import 'package:flutter/material.dart';

/// Centralized repository of all final border corner radii.
/// Smooth, larger radii match the calm and peaceful design language.
class AppRadius {
  AppRadius._();

  // Border sizes
  static const double xs = 6.0; // Minimal corner roundness
  static const double sm = 12.0; // Button corners / Small element card corners
  static const double md = 18.0; // Main cards / Content boxes
  static const double lg = 24.0; // Dialogs / Sheets
  static const double xl = 32.0; // Large accent layouts
  static const double round = 999.0; // Fully circular / Oval pill shapes

  // BorderRadius wrappers
  static const BorderRadius borderXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius borderSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius borderRound = BorderRadius.all(
    Radius.circular(round),
  );
}
