import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

/// A highly reusable Scaffold component that wraps standard pages,
/// ensuring design system conformity, responsiveness, and default SafeArea behavior.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;
  final bool wrapWithSafeArea;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
    this.wrapWithSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve default page background color using Design System Warm Beige / Warm Dark
    final resolvedBackgroundColor = backgroundColor ??
        (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    return Scaffold(
      appBar: appBar,
      backgroundColor: resolvedBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: wrapWithSafeArea ? SafeArea(child: body) : body,
    );
  }
}
