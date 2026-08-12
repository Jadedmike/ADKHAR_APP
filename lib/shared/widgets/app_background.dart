import 'package:flutter/material.dart';

/// Reusable full-screen viewport background widget for the "ذكر" application.
/// Ensures decorative ornaments and radial gradients stay fixed to the screen viewport
/// regardless of scrolling content above it.
class AppBackground extends StatelessWidget {
  final Widget? child;

  const AppBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF161A15) : const Color(0xFFF8F4EC);
    final gradientColors = isDark
        ? const [Color(0xFF1D221C), Color(0xFF161A15), Color(0xFF111410)]
        : const [Color(0xFFFAF7F0), Color(0xFFF8F4EC), Color(0xFFEFE9DC)];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fullscreen Fixed Viewport Decorative Layer
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Radial Gradient Background
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    gradient: RadialGradient(
                      center: const Alignment(-0.6, -0.6),
                      radius: 1.3,
                      colors: gradientColors,
                    ),
                  ),
                ),

                // Corner Ornaments - Gold Arches
                Positioned.fill(
                  child: Opacity(
                    opacity: isDark ? 0.32 : 0.35,
                    child: Image.asset(
                      'assets/images/gold.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                ),

                // Corner Ornaments - Olive Branches
                Positioned.fill(
                  child: Opacity(
                    opacity: isDark ? 0.42 : 0.45,
                    child: Image.asset(
                      'assets/images/olivebranches.png',
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Foreground Content Canvas (if passed)
        if (child != null) Positioned.fill(child: child!),
      ],
    );
  }
}
