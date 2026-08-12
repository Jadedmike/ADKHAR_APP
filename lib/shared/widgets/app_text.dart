import 'package:flutter/material.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/app_colors.dart';

/// Available typographic variants corresponding to the Design System scale.
enum AppTextVariant {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  caption,
  button,
  scripture,
}

/// A reusable text component that encapsulates the project's typography system.
/// Automatically handles RTL alignment rules and default color mappings.
class AppText extends StatelessWidget {
  final String text;
  final AppTextVariant variant;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final FontWeight? fontWeight;

  const AppText(
    this.text, {
    super.key,
    this.variant = AppTextVariant.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve base style from Design System typography rules
    TextStyle style;
    switch (variant) {
      case AppTextVariant.displayLarge:
        style = AppTypography.displayLarge;
        break;
      case AppTextVariant.displayMedium:
        style = AppTypography.displayMedium;
        break;
      case AppTextVariant.displaySmall:
        style = AppTypography.displaySmall;
        break;
      case AppTextVariant.headlineLarge:
        style = AppTypography.headlineLarge;
        break;
      case AppTextVariant.headlineMedium:
        style = AppTypography.headlineMedium;
        break;
      case AppTextVariant.headlineSmall:
        style = AppTypography.headlineSmall;
        break;
      case AppTextVariant.titleLarge:
        style = AppTypography.titleLarge;
        break;
      case AppTextVariant.titleMedium:
        style = AppTypography.titleMedium;
        break;
      case AppTextVariant.titleSmall:
        style = AppTypography.titleSmall;
        break;
      case AppTextVariant.bodyLarge:
        style = AppTypography.bodyLarge;
        break;
      case AppTextVariant.bodyMedium:
        style = AppTypography.bodyMedium;
        break;
      case AppTextVariant.bodySmall:
        style = AppTypography.bodySmall;
        break;
      case AppTextVariant.caption:
        style = AppTypography.caption;
        break;
      case AppTextVariant.button:
        style = AppTypography.button;
        break;
      case AppTextVariant.scripture:
        style = AppTypography.scripture();
        break;
    }

    // Resolve color based on theme and role
    Color defaultColor;
    if (variant == AppTextVariant.caption ||
        variant == AppTextVariant.bodyLarge ||
        variant == AppTextVariant.bodyMedium ||
        variant == AppTextVariant.bodySmall) {
      defaultColor = isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight; // Soft Gray
    } else {
      defaultColor = isDark
          ? AppColors.textPrimaryDark
          : AppColors.textPrimaryLight; // Dark Olive
    }

    final resolvedStyle = style.copyWith(
      color: color ?? defaultColor,
      height: height,
      fontWeight: fontWeight,
    );

    return Text(
      text,
      style: resolvedStyle,
      textAlign: textAlign, // Defaults to start (Respects RTL Directionality)
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
