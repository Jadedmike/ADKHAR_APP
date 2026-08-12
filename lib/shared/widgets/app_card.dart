import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';

/// Card styles available in the design system.
enum AppCardVariant { normal, outlined }

/// A highly reusable, responsive Card component that acts as the primary
/// content container across the Adhkar application, conforming to Design System rules.
class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.normal,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Default to standard AppSpacing.md (16px) padding if not specified
    final resolvedPadding = padding ?? const EdgeInsets.all(AppSpacing.md);

    // Styling properties to resolve dynamically
    Color backgroundColor;
    Border border;
    List<BoxShadow>? boxShadow;

    switch (variant) {
      case AppCardVariant.normal:
        backgroundColor = isDark
            ? AppColors.cardDark
            : AppColors.cardLight; // White cards (light)
        border = Border.all(
          color: isDark
              ? AppColors.borderDark
              : AppColors.borderLight, // Sand border
          width: 1,
        );
        boxShadow = isDark
            ? AppShadows.darkLow
            : AppShadows.low; // Soft tinted shadows
        break;
      case AppCardVariant.outlined:
        backgroundColor = isDark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight; // Light Beige surfaces
        border = Border.all(
          color: isDark
              ? AppColors.primaryDark
              : AppColors.primaryLight, // Highlighted Olive Green border
          width: 1.5,
        );
        boxShadow = null; // Outlined cards do not have shadows
        break;
    }

    return Container(
      width: width,
      height: height,
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius:
            borderRadius ?? AppRadius.borderMD, // Default MD = 18px corners
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
