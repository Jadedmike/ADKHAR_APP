import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium, reusable Frosted Glass (Glassmorphic) button with micro-interactions,
/// tactile haptic feedback, and dynamic Light/Dark mode styling.
class GlassButton extends StatefulWidget {
  final String? label;
  final Widget? icon;
  final Widget? child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? radius;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? accentColor;
  final bool enableHaptics;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final double pressedScale;

  const GlassButton({
    super.key,
    this.label,
    this.icon,
    this.child,
    required this.onPressed,
    this.width,
    this.height = 52.0,
    this.padding,
    this.borderRadius,
    this.radius,
    this.isFullWidth = false,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.accentColor,
    this.enableHaptics = true,
    this.blurSigma = 20.0,
    this.boxShadow,
    this.pressedScale = 0.96,
  }) : assert(
         label != null || child != null || icon != null,
         'Either label, child, or icon must be provided',
       );

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ??
        BorderRadius.circular(widget.radius ?? 22);

    final Color effectiveBgColor;
    if (widget.backgroundColor != null) {
      effectiveBgColor = widget.backgroundColor!.a >= 1.0
          ? widget.backgroundColor!.withValues(alpha: isDark ? 0.40 : 0.35)
          : widget.backgroundColor!;
    } else {
      effectiveBgColor = isDark
          ? const Color(0xFF1E241C).withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.35);
    }

    final Color effectiveBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.65));

    final Color effectiveFgColor = widget.textColor ??
        widget.accentColor ??
        (isDark ? const Color(0xFFF6F1E7) : const Color(0xFF333E32));

    final defaultShadow = [
      BoxShadow(
        color: isDark ? const Color(0x24000000) : const Color(0x0C000000),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ];

    Widget content = widget.child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              IconTheme(
                data: IconThemeData(
                  color: widget.iconColor ?? effectiveFgColor,
                  size: 20,
                ),
                child: widget.icon!,
              ),
              if (widget.label != null) const SizedBox(width: 8),
            ],
            if (widget.label != null)
              Text(
                widget.label!,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: effectiveFgColor,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        );

    Widget button = Container(
      width: widget.isFullWidth ? double.infinity : widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: widget.boxShadow ?? defaultShadow,
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
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: effectiveRadius,
              border: Border.all(color: effectiveBorderColor, width: 1.0),
            ),
            child: Center(
              widthFactor:
                  (widget.isFullWidth || widget.width != null) ? null : 1.0,
              heightFactor: widget.height != null ? null : 1.0,
              child: content,
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: button,
      ),
    );
  }
}

/// A compact, glassmorphic icon button for app bars, back buttons, and toolbars.
class GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final String? tooltip;
  final bool enableHaptics;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final double pressedScale;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 42.0,
    this.iconSize = 20.0,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.isCircle = false,
    this.tooltip,
    this.enableHaptics = true,
    this.blurSigma = 20.0,
    this.boxShadow,
    this.pressedScale = 0.92,
  });

  @override
  State<GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<GlassIconButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveRadius = widget.isCircle
        ? BorderRadius.circular(widget.size / 2)
        : (widget.borderRadius ?? BorderRadius.circular(16));

    final Color effectiveBgColor;
    if (widget.backgroundColor != null) {
      effectiveBgColor = widget.backgroundColor!.a >= 1.0
          ? widget.backgroundColor!.withValues(alpha: isDark ? 0.40 : 0.35)
          : widget.backgroundColor!;
    } else {
      effectiveBgColor = isDark
          ? const Color(0xFF1E241C).withValues(alpha: 0.40)
          : Colors.white.withValues(alpha: 0.35);
    }

    final Color effectiveBorderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.65));

    final Color effectiveIconColor = widget.color ??
        (isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E));

    final defaultShadow = [
      BoxShadow(
        color: isDark ? const Color(0x20000000) : const Color(0x0A000000),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ];

    Widget iconWidget = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: widget.isCircle ? null : effectiveRadius,
        boxShadow: widget.boxShadow ?? defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: effectiveBgColor,
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : effectiveRadius,
              border: Border.all(color: effectiveBorderColor, width: 1.0),
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: effectiveIconColor,
              ),
            ),
          ),
        ),
      ),
    );

    Widget result = AnimatedScale(
      scale: _isPressed ? widget.pressedScale : 1.0,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: _handleTap,
        child: iconWidget,
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: result);
    }
    return result;
  }
}
