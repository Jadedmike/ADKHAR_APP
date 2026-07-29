import 'package:flutter/material.dart';

/// Helper utility for handling screen width breakpoints.
class ResponsiveHelper {
  // Production-ready device width breakpoints
  static const double mobileBreakPoint = 600.0;
  static const double tabletBreakPoint = 1200.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakPoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileBreakPoint &&
      MediaQuery.sizeOf(context).width < tabletBreakPoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakPoint;
}

/// A responsive layout builder widget that switches between
/// mobile, tablet, and desktop layout sizes.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.tabletBreakPoint) {
          return desktop;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileBreakPoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }
}
