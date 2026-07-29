import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../../config/theme/app_typography.dart';
import '../../config/theme/app_radius.dart';
import '../../config/theme/app_spacing.dart';

/// Button variants available in the design system.
enum AppButtonVariant {
  primary,
  secondary,
}

/// A highly reusable, responsive, and RTL-compatible button component
/// that conforms to the centralized Adhkar design system.
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isFullWidth = false,
    this.width,
    this.height = 54.0, // Default premium tall height (48px - 56px)
    this.borderRadius,
  });

  bool get isDisabled => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolve Colors based on variant and disabled state
    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    if (isDisabled) {
      backgroundColor = isDark ? const Color(0xFF33302B) : const Color(0x80EADFCF); // 50% opacity sand
      foregroundColor = isDark ? const Color(0xFF707973) : const Color(0x99707973); // 60% opacity gray
    } else {
      switch (variant) {
        case AppButtonVariant.primary:
          backgroundColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
          foregroundColor = isDark ? AppColors.textPrimaryLight : AppColors.onPrimaryLight;
          break;
        case AppButtonVariant.secondary:
          backgroundColor = Colors.transparent;
          foregroundColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;
          borderSide = BorderSide(
            color: isDark ? AppColors.primaryDark : AppColors.primaryLight,
            width: 1.5,
          );
          break;
      }
    }

    // Build button content. Row automatically mirrors layout direction in RTL.
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          icon!,
          AppSpacing.gapH8, // Enforces standard spacing
        ],
        Text(
          text,
          style: AppTypography.button.copyWith(
            color: foregroundColor,
          ),
        ),
      ],
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      disabledBackgroundColor: backgroundColor,
      disabledForegroundColor: foregroundColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.borderSM, // Default to borderSM
        side: borderSide,
      ),
    );

    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: content,
    );

    // Apply width constraints for responsiveness
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: button,
      );
    }

    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return SizedBox(
      height: height,
      child: button,
    );
  }
}
