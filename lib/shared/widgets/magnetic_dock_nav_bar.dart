import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Navigation item model for [MagneticDockNavBar].
class AthkarNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final String? badge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final Object? tag;

  const AthkarNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
    this.badge,
    this.badgeColor,
    this.badgeTextColor,
    this.tag,
  });
}

/// Visual layout styles for the items inside [MagneticDockNavBar].
enum MagneticDockItemStyle {
  /// Icon with label stacked underneath (classic macOS/iOS dock aesthetic).
  stacked,

  /// Active item expands with horizontal label pill; inactive shows icon only.
  pillInline,
}

/// A modern, polished "Magnetic Dock" style Bottom Navigation Bar for Flutter.
///
/// Features:
/// - Floating rounded container with elevation and subtle border.
/// - Real-time finger tracking during interactive drag/touch gestures.
/// - Magnetic snapping with easing curves on release.
/// - Haptic detent clicks on crossing tab boundaries.
/// - Instant tap response.
/// - Full RTL / LTR bi-directional support using [Directionality.of(context)].
/// - Smooth icon and typography color transitions with subtle active scale-up.
/// - Badge notification support per item.
/// - Fully theme-aware with smart Light & Dark mode fallbacks.
class MagneticDockNavBar extends StatefulWidget {
  /// The list of navigation items.
  final List<AthkarNavItem> items;

  /// Current active tab index (0-based).
  final int currentIndex;

  /// Callback when a tab is tapped or snapped to.
  final ValueChanged<int> onItemSelected;

  /// Overall height of the dock container. Defaults to 68.0.
  final double height;

  /// Outer border radius of the dock bar. Defaults to 34.0.
  final double borderRadius;

  /// Corner radius of the sliding magnetic capsule. Defaults to 26.0.
  final double capsuleRadius;

  /// Custom dock background color. If null, adapts to [Theme.of(context)].
  final Color? backgroundColor;

  /// Custom border color. If null, adapts to theme brightness.
  final Color? borderColor;

  /// Custom color for the sliding active capsule pill.
  final Color? activePillColor;

  /// Custom active icon & text color.
  final Color? activeColor;

  /// Custom inactive icon & text color.
  final Color? inactiveColor;

  /// Animation duration for the sliding capsule snapping and color transitions.
  final Duration animationDuration;

  /// Easing curve for the magnetic sliding capsule.
  final Curve animationCurve;

  /// Inner padding of the dock container.
  final EdgeInsetsGeometry padding;

  /// Inset padding around the sliding magnetic capsule.
  final EdgeInsetsGeometry capsuleMargin;

  /// Visual presentation style for dock items.
  final MagneticDockItemStyle itemStyle;

  /// Active item scale factor (e.g. 1.08).
  final double activeScale;

  /// Whether to trigger haptic feedback on tab boundary crossing and selection.
  final bool enableHapticFeedback;

  /// Custom box shadows for the dock bar container.
  final List<BoxShadow>? boxShadow;

  /// Custom box shadows for the sliding capsule pill.
  final List<BoxShadow>? capsuleBoxShadow;

  const MagneticDockNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemSelected,
    this.height = 68.0,
    this.borderRadius = 34.0,
    this.capsuleRadius = 26.0,
    this.backgroundColor,
    this.borderColor,
    this.activePillColor,
    this.activeColor,
    this.inactiveColor,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeOutCubic,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    this.capsuleMargin = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    this.itemStyle = MagneticDockItemStyle.stacked,
    this.activeScale = 1.08,
    this.enableHapticFeedback = true,
    this.boxShadow,
    this.capsuleBoxShadow,
  }) : assert(items.length > 0, 'items must not be empty'),
       assert(
         currentIndex >= 0 && currentIndex < items.length,
         'currentIndex must be between 0 and items.length - 1',
       );

  @override
  State<MagneticDockNavBar> createState() => _MagneticDockNavBarState();
}

class _MagneticDockNavBarState extends State<MagneticDockNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _snapAnimation;

  /// Continuous indicator position in index units: [0.0, items.length - 1.0].
  late double _currentPosition;

  /// Currently highlighted/hovered tab index.
  late int _hoveredIndex;

  /// Whether the user is actively dragging their finger across the dock.
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.currentIndex.toDouble();
    _hoveredIndex = widget.currentIndex;

    _animController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _snapAnimation = Tween<double>(
      begin: _currentPosition,
      end: _currentPosition,
    ).animate(_animController);

    _animController.addListener(() {
      setState(() {
        _currentPosition = _snapAnimation.value;
      });
    });
  }

  @override
  void didUpdateWidget(covariant MagneticDockNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationDuration != widget.animationDuration) {
      _animController.duration = widget.animationDuration;
    }
    // If parent updates currentIndex externally and user is not dragging
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      if (_hoveredIndex != widget.currentIndex ||
          (_currentPosition - widget.currentIndex).abs() > 0.001) {
        _hoveredIndex = widget.currentIndex;
        _snapTo(widget.currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Calculates continuous index [0.0, items.length - 1] from local finger X coordinate.
  double _calculateContinuousPosition(
    double localX,
    double totalWidth,
    bool isRtl,
  ) {
    final itemCount = widget.items.length;
    if (totalWidth <= 0 || itemCount <= 1) return 0.0;

    final double clampedX = localX.clamp(0.0, totalWidth);
    final double slotWidth = totalWidth / itemCount;
    final double rawP = (clampedX / slotWidth) - 0.5;

    return isRtl
        ? ((itemCount - 1) - rawP).clamp(0.0, itemCount - 1.0)
        : rawP.clamp(0.0, itemCount - 1.0);
  }

  /// Calculates discrete slot index [0, items.length - 1] for direct taps.
  int _calculateSlotIndex(double localX, double totalWidth, bool isRtl) {
    final itemCount = widget.items.length;
    if (totalWidth <= 0 || itemCount <= 1) return 0;

    final double clampedX = localX.clamp(0.0, totalWidth);
    final double slotWidth = totalWidth / itemCount;
    final int rawSlot = (clampedX / slotWidth).floor().clamp(0, itemCount - 1);

    return isRtl ? (itemCount - 1 - rawSlot) : rawSlot;
  }

  /// Calculates directional horizontal alignment for [Align].
  AlignmentDirectional _getIndicatorAlignment(
    double position,
    int totalCount,
  ) {
    if (totalCount <= 1) return AlignmentDirectional.center;
    final double x = -1.0 + (2.0 * position / (totalCount - 1));
    return AlignmentDirectional(x, 0.0);
  }

  void _onDragStart(Offset localPosition, double totalWidth, bool isRtl) {
    _isDragging = true;
    _animController.stop();

    final p = _calculateContinuousPosition(localPosition.dx, totalWidth, isRtl);
    final newHovered = p.round().clamp(0, widget.items.length - 1);

    if (newHovered != _hoveredIndex) {
      _hoveredIndex = newHovered;
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }

    setState(() {
      _currentPosition = p;
    });
  }

  void _onDragUpdate(Offset localPosition, double totalWidth, bool isRtl) {
    final p = _calculateContinuousPosition(localPosition.dx, totalWidth, isRtl);
    final newHovered = p.round().clamp(0, widget.items.length - 1);

    if (newHovered != _hoveredIndex) {
      _hoveredIndex = newHovered;
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
    }

    setState(() {
      _currentPosition = p;
    });
  }

  void _onDragEnd() {
    if (!_isDragging) return;
    _isDragging = false;

    final targetIndex = _hoveredIndex;
    _snapTo(
      targetIndex,
      onFinished: () {
        if (widget.enableHapticFeedback) {
          HapticFeedback.lightImpact();
        }
      },
    );

    widget.onItemSelected(targetIndex);
  }

  void _onTapUp(Offset localPosition, double totalWidth, bool isRtl) {
    final targetIndex = _calculateSlotIndex(localPosition.dx, totalWidth, isRtl);
    _hoveredIndex = targetIndex;

    _snapTo(
      targetIndex,
      onFinished: () {
        if (widget.enableHapticFeedback) {
          HapticFeedback.lightImpact();
        }
      },
    );

    widget.onItemSelected(targetIndex);
  }

  void _snapTo(int targetIndex, {VoidCallback? onFinished}) {
    _animController.stop();

    _snapAnimation = Tween<double>(
      begin: _currentPosition,
      end: targetIndex.toDouble(),
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: widget.animationCurve,
      ),
    );

    _animController.forward(from: 0.0).then((_) {
      onFinished?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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

    final Color effectiveActivePillColor;
    if (widget.activePillColor != null) {
      effectiveActivePillColor = widget.activePillColor!.a >= 1.0
          ? widget.activePillColor!.withValues(alpha: isDark ? 0.12 : 0.50)
          : widget.activePillColor!;
    } else {
      effectiveActivePillColor = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.50);
    }

    final effectiveActiveColor =
        widget.activeColor ??
        (isDark ? const Color(0xFFC9A15B) : const Color(0xFF425141));

    final effectiveInactiveColor =
        widget.inactiveColor ??
        (isDark ? const Color(0xFF828E7D) : const Color(0xFF758177));

    final defaultBarShadow = [
      BoxShadow(
        color: isDark ? const Color(0x38000000) : const Color(0x14000000),
        blurRadius: 24,
        offset: const Offset(0, 8),
        spreadRadius: 1,
      ),
      BoxShadow(
        color: isDark ? const Color(0x1F000000) : const Color(0x0A000000),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];

    final defaultPillShadow = [
      BoxShadow(
        color: isDark ? const Color(0x28000000) : const Color(0x0D000000),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];

    final itemCount = widget.items.length;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: widget.boxShadow ?? defaultBarShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: effectiveBorderColor, width: 1.0),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) =>
                      _onDragStart(details.localPosition, totalWidth, isRtl),
                  onHorizontalDragUpdate: (details) =>
                      _onDragUpdate(details.localPosition, totalWidth, isRtl),
                  onHorizontalDragEnd: (details) => _onDragEnd(),
                  onHorizontalDragCancel: () => _onDragEnd(),
                  onTapUp: (details) =>
                      _onTapUp(details.localPosition, totalWidth, isRtl),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Real-Time Tracking & Magnetic Sliding Pill
                      Align(
                        alignment: _getIndicatorAlignment(
                          _currentPosition,
                          itemCount,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 1.0 / itemCount,
                          heightFactor: 1.0,
                          child: Padding(
                            padding: widget.capsuleMargin,
                            child: Container(
                              decoration: BoxDecoration(
                                color: effectiveActivePillColor,
                                borderRadius: BorderRadius.circular(
                                  widget.capsuleRadius,
                                ),
                                border: Border.all(
                                  color: effectiveBorderColor.withValues(
                                    alpha: isDark ? 0.25 : 0.60,
                                  ),
                                  width: 1.0,
                                ),
                                boxShadow:
                                    widget.capsuleBoxShadow ?? defaultPillShadow,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 2. Interactive Navigation Items Row
                      Positioned.fill(
                        child: Row(
                          children: List.generate(itemCount, (index) {
                            final item = widget.items[index];
                            final isSelected = index == _hoveredIndex;

                            return Expanded(
                              child: _MagneticNavItemWidget(
                                item: item,
                                isSelected: isSelected,
                                activeColor: effectiveActiveColor,
                                inactiveColor: effectiveInactiveColor,
                                activeScale: widget.activeScale,
                                animationDuration: widget.animationDuration,
                                animationCurve: widget.animationCurve,
                                itemStyle: widget.itemStyle,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal item representation for [MagneticDockNavBar].
class _MagneticNavItemWidget extends StatelessWidget {
  final AthkarNavItem item;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final double activeScale;
  final Duration animationDuration;
  final Curve animationCurve;
  final MagneticDockItemStyle itemStyle;

  const _MagneticNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.activeScale,
    required this.animationDuration,
    required this.animationCurve,
    required this.itemStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedScale(
        scale: isSelected ? activeScale : 1.0,
        duration: animationDuration,
        curve: animationCurve,
        child: TweenAnimationBuilder<Color?>(
          duration: animationDuration,
          curve: animationCurve,
          tween: ColorTween(
            begin: isSelected ? inactiveColor : activeColor,
            end: isSelected ? activeColor : inactiveColor,
          ),
          builder: (context, animatedColor, child) {
            final displayColor = animatedColor ?? inactiveColor;

            if (itemStyle == MagneticDockItemStyle.pillInline) {
              return _buildInlineContent(displayColor);
            }
            return _buildStackedContent(displayColor);
          },
        ),
      ),
    );
  }

  /// Compact Stacked Layout: Icon + Subtext with Optional Badge.
  Widget _buildStackedContent(Color color) {
    final iconData = (isSelected && item.activeIcon != null)
        ? item.activeIcon!
        : item.icon;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              iconData,
              size: 22,
              color: color,
            ),
            if (item.badge != null)
              PositionedDirectional(
                top: -3,
                end: -8,
                child: _buildBadge(item.badge!),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Flexible(
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  /// Inline Horizontal Layout: Icon with expanding text pill.
  Widget _buildInlineContent(Color color) {
    final iconData = (isSelected && item.activeIcon != null)
        ? item.activeIcon!
        : item.icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              iconData,
              size: 21,
              color: color,
            ),
            if (item.badge != null && !isSelected)
              PositionedDirectional(
                top: -3,
                end: -6,
                child: _buildBadge(item.badge!),
              ),
          ],
        ),
        AnimatedSize(
          duration: animationDuration,
          curve: animationCurve,
          child: isSelected
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 5),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Visual badge pill badge indicator.
  Widget _buildBadge(String badgeText) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
      decoration: BoxDecoration(
        color: item.badgeColor ?? const Color(0xFFC54A4A),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontFamily: 'Fustat',
          color: item.badgeTextColor ?? Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
    );
  }
}
