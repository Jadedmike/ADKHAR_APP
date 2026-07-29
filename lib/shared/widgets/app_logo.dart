import 'package:flutter/material.dart';
import 'logo_painter.dart';

/// Reusable widget for displaying the official application logo.
/// Renders the logo using LogoPainter to ensure pixel-perfect vector rendering.
class AppLogo extends StatelessWidget {
  final double width;
  final double height;

  const AppLogo({
    super.key,
    this.width = 170.0,
    this.height = 170.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: const LogoPainter(),
    );
  }
}

