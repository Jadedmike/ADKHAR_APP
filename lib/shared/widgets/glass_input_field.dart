import 'dart:ui';
import 'package:flutter/material.dart';

/// A premium, frosted glass search bar and input field with dynamic focus lighting.
class GlassInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final double height;
  final BorderRadius? borderRadius;
  final bool autofocus;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextDirection? textDirection;

  const GlassInputField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.height = 50.0,
    this.borderRadius,
    this.autofocus = false,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.textDirection,
  });

  @override
  State<GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<GlassInputField> {
  late FocusNode _effectiveFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(GlassInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);
      _effectiveFocusNode = widget.focusNode ?? FocusNode();
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(20);

    final Color effectiveBgColor = isDark
        ? const Color(0xFF1E241C).withValues(alpha: _isFocused ? 0.50 : 0.40)
        : Colors.white.withValues(alpha: _isFocused ? 0.45 : 0.35);

    final Color effectiveBorderColor = _isFocused
        ? (isDark
            ? const Color(0xFFC9A15B).withValues(alpha: 0.85)
            : const Color(0xFFC5A059).withValues(alpha: 0.85))
        : (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.65));

    final Color textColor =
        isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F);

    final Color hintColor =
        isDark ? const Color(0xFFD8CEBE) : const Color(0xFF8C968B);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x0C000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: effectiveRadius,
              border: Border.all(
                color: effectiveBorderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                if (widget.prefixIcon != null) ...[
                  widget.prefixIcon!,
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _effectiveFocusNode,
                    autofocus: widget.autofocus,
                    readOnly: widget.readOnly,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textDirection: widget.textDirection ?? TextDirection.rtl,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    onTap: widget.onTap,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: hintColor,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  const SizedBox(width: 6),
                  widget.suffixIcon!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
