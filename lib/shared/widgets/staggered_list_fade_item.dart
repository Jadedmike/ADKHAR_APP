import 'package:flutter/material.dart';

/// Reusable List Staggered Fade & 8px Upward Entrance Animation Widget.
/// Delay: 35ms per index, Duration: 260ms.
class StaggeredListFadeItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayStep;
  final Duration duration;

  const StaggeredListFadeItem({
    super.key,
    required this.index,
    required this.child,
    this.delayStep = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 260),
  });

  @override
  State<StaggeredListFadeItem> createState() => _StaggeredListFadeItemState();
}

class _StaggeredListFadeItemState extends State<StaggeredListFadeItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.08), // Slight 8px upward movement
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = widget.delayStep * widget.index;
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
