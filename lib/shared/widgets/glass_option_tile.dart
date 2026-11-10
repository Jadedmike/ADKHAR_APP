import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A sleek, frosted glass list tile / option row for settings, selections,
/// and option dialogs matching the unified glassmorphism aesthetic.
class GlassOptionTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final String? titleText;
  final Widget? subtitle;
  final String? subtitleText;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final bool enableHaptics;

  const GlassOptionTile({
    super.key,
    this.leading,
    this.title,
    this.titleText,
    this.subtitle,
    this.subtitleText,
    this.trailing,
    this.onTap,
    this.isSelected = false,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 18.0,
    this.enableHaptics = true,
  }) : assert(title != null || titleText != null, 'Either title or titleText must be provided');

  @override
  State<GlassOptionTile> createState() => _GlassOptionTileState();
}

class _GlassOptionTileState extends State<GlassOptionTile> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    if (widget.enableHaptics) {
      HapticFeedback.selectionClick();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(18);

    final Color defaultBgColor = isDark
        ? const Color(0xFF1E241C).withValues(alpha: widget.isSelected ? 0.55 : 0.40)
        : Colors.white.withValues(alpha: widget.isSelected ? 0.50 : 0.35);

    final Color effectiveBgColor = widget.backgroundColor ?? defaultBgColor;

    final Color defaultBorderColor;
    if (widget.isSelected) {
      defaultBorderColor = isDark
          ? const Color(0xFFC9A15B).withValues(alpha: 0.8)
          : const Color(0xFFC5A059).withValues(alpha: 0.8);
    } else {
      defaultBorderColor = isDark
          ? Colors.white.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.60);
    }

    final Color effectiveBorderColor = widget.borderColor ?? defaultBorderColor;

    final Widget titleWidget = widget.title ??
        Text(
          widget.titleText ?? '',
          style: TextStyle(
            fontFamily: 'Fustat',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: widget.isSelected
                ? (isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E))
                : (isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F)),
          ),
        );

    final Widget? subtitleWidget = widget.subtitle ??
        (widget.subtitleText != null
            ? Text(
                widget.subtitleText!,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFFD8CEBE)
                      : const Color(0xFF707973),
                ),
              )
            : null);

    final Widget? trailingWidget = widget.trailing ??
        (widget.isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFFC5A059),
                size: 22,
              )
            : null);

    Widget content = Row(
      children: [
        if (widget.leading != null) ...[
          widget.leading!,
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleWidget,
              if (subtitleWidget != null) ...[
                const SizedBox(height: 3),
                subtitleWidget,
              ],
            ],
          ),
        ),
        if (trailingWidget != null) ...[
          const SizedBox(width: 12),
          trailingWidget,
        ],
      ],
    );

    Widget tile = Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x18000000) : const Color(0x08000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: Container(
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: effectiveBorderColor,
                width: widget.isSelected ? 1.5 : 1.0,
              ),
            ),
            child: content,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return RepaintBoundary(
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: tile,
          ),
        ),
      );
    }

    return RepaintBoundary(child: tile);
  }
}
