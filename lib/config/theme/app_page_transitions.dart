import 'package:flutter/material.dart';

/// Premium RTL-friendly Slide & Soft Fade Page Transitions Builder.
/// Duration: 280ms, Curve: EaseInOutCubic. Zero bounce, rotation, or zoom.
class RtlFadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const RtlFadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final slideAnimation = Tween<Offset>(
      begin: const Offset(-0.15, 0.0), // RTL subtle slide
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    return SlideTransition(
      position: slideAnimation,
      child: FadeTransition(opacity: fadeAnimation, child: child),
    );
  }
}

/// Helper to createPageRoute for direct Navigator calls.
class AppPageRoute {
  static PageRouteBuilder<T> create<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation =
            Tween<Offset>(
              begin: const Offset(-0.15, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic),
            );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }
}
