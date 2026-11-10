import 'dart:ui';
import 'package:flutter/material.dart';

/// Shows a frosted glass bottom sheet with smooth blur and specular borders.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    builder: (modalContext) {
      final theme = Theme.of(modalContext);
      final isDark = theme.brightness == Brightness.dark;

      final Color effectiveBgColor = isDark
          ? const Color(0xFF1E241C).withValues(alpha: 0.65)
          : Colors.white.withValues(alpha: 0.70);

      final Color effectiveBorderColor = isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.70);

      final Color handleColor = isDark
          ? const Color(0xFF353E32)
          : const Color(0xFFD8CEBE);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
            child: Container(
              decoration: BoxDecoration(
                color: effectiveBgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: effectiveBorderColor, width: 1.2),
                  left: BorderSide(color: effectiveBorderColor, width: 1.0),
                  right: BorderSide(color: effectiveBorderColor, width: 1.0),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Drag Indicator Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Flexible(
                      child: builder(modalContext),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Shows a frosted glass modal dialog with blur and specular highlights.
Future<T?> showGlassDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;

      final Color effectiveBgColor = isDark
          ? const Color(0xFF1E241C).withValues(alpha: 0.65)
          : Colors.white.withValues(alpha: 0.75);

      final Color effectiveBorderColor = isDark
          ? Colors.white.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.70);

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveBgColor,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: effectiveBorderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0x30000000)
                          : const Color(0x15000000),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: builder(dialogContext),
              ),
            ),
          ),
        ),
      );
    },
  );
}
