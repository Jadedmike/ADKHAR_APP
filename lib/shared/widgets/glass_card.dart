import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium, reusable Frosted Glass (Glassmorphic) card container
/// with micro-interactions, silky blur, and specular border highlights.
class GlassCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final BorderRadius? borderRadius;
  final double? radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final bool enableHaptics;
  final double pressedScale;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.borderRadius,
    this.radius,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 20.0,
    this.boxShadow,
    this.enableHaptics = true,
    this.pressedScale = 0.98,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
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
      HapticFeedback.lightImpact();
    }
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ??
        (widget.radius != null
            ? BorderRadius.circular(widget.radius!)
            : BorderRadius.circular(22));

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
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.65));

    final defaultShadow = [
      BoxShadow(
        color: isDark ? const Color(0x20000000) : const Color(0x0A000000),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ];

    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      margin: widget.margin,
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
            padding: widget.padding ?? const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: effectiveRadius,
              border: Border.all(color: effectiveBorderColor, width: 1.0),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null) {
      return RepaintBoundary(
        child: AnimatedScale(
          scale: _isPressed ? widget.pressedScale : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: cardContent,
          ),
        ),
      );
    }

    return RepaintBoundary(child: cardContent);
  }
}
