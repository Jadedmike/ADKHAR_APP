import 'package:flutter/material.dart';
import 'package:adhkar/config/theme/app_colors.dart';

/// A unified, bi-directional (RTL/LTR) header widget that guarantees
/// true horizontal centering of the title/subtitle (or custom title widget)
/// relative to the full screen width, unaffected by leading/trailing actions.
class ScreenHeader extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? titleWidget;
  final Widget? leading;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  const ScreenHeader({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.leading,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? centerChild = titleWidget;
    if (centerChild == null && title != null) {
      centerChild = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            title!,
            textAlign: crossAxisAlignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: crossAxisAlignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
              ),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (centerChild != null)
            Align(
              alignment: Alignment.center,
              child: centerChild,
            ),
          if (leading != null)
            Align(
              alignment: AlignmentDirectional.topStart,
              child: leading!,
            ),
          if (trailing != null)
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: trailing!,
            ),
        ],
      ),
    );
  }
}
