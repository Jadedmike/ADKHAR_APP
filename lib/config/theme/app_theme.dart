import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_page_transitions.dart';

/// Central theme orchestrator that builds production-ready MaterialApp [ThemeData].
class AppTheme {
  AppTheme._();

  static const _pageTransitionsTheme = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: RtlFadeSlidePageTransitionsBuilder(),
      TargetPlatform.iOS: RtlFadeSlidePageTransitionsBuilder(),
      TargetPlatform.windows: RtlFadeSlidePageTransitionsBuilder(),
      TargetPlatform.macOS: RtlFadeSlidePageTransitionsBuilder(),
      TargetPlatform.linux: RtlFadeSlidePageTransitionsBuilder(),
    },
  );

  /// Global Card Theme Configuration for Light Mode
  static CardThemeData get lightCardTheme => const CardThemeData(
    color: AppColors.cardLight,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.borderMD,
      side: BorderSide(color: AppColors.borderLight, width: 1),
    ),
  );

  /// Global Card Theme Configuration for Dark Mode
  static CardThemeData get darkCardTheme => const CardThemeData(
    color: AppColors.cardDark,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadius.borderMD,
      side: BorderSide(color: AppColors.borderDark, width: 1),
    ),
  );

  /// Global Button Styles for Light Mode
  static ElevatedButtonThemeData get lightElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.onPrimaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSM),
          textStyle: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  /// Global Button Styles for Dark Mode
  static ElevatedButtonThemeData get darkElevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderSM),
          textStyle: TextStyle(
            fontFamily: AppTypography.uiFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  /// Reusable Container Decoration
  static BoxDecoration cardDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: AppRadius.borderMD,
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      ),
      boxShadow: isDark ? AppShadows.darkLow : AppShadows.low,
    );
  }

  /// ThemeData for Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.onPrimaryLight,
        secondary: AppColors.goldLight,
        onSecondary: Colors.white,
        error: AppColors.error,
        surface: AppColors.surfaceLight,
      ),
      cardTheme: lightCardTheme,
      elevatedButtonTheme: lightElevatedButtonTheme,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondaryLight,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.textPrimaryLight,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  /// ThemeData for Dark Theme (Exact specs matching dark olive & warm cream text)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      pageTransitionsTheme: _pageTransitionsTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.onPrimaryDark,
        secondary: AppColors.goldDark,
        onSecondary: Colors.black,
        error: AppColors.error,
        surface: AppColors.surfaceDark,
      ),
      cardTheme: darkCardTheme,
      elevatedButtonTheme: darkElevatedButtonTheme,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: AppTypography.displayMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        displaySmall: AppTypography.displaySmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineLarge: AppTypography.headlineLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineMedium: AppTypography.headlineMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        headlineSmall: AppTypography.headlineSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: AppTypography.titleLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: AppTypography.titleMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        titleSmall: AppTypography.titleSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: AppTypography.bodyLarge.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        bodyMedium: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        bodySmall: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondaryDark,
        ),
        labelLarge: AppTypography.labelLarge.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        labelMedium: AppTypography.labelMedium.copyWith(
          color: AppColors.textPrimaryDark,
        ),
        labelSmall: AppTypography.labelSmall.copyWith(
          color: AppColors.textPrimaryDark,
        ),
      ),
    );
  }
}
