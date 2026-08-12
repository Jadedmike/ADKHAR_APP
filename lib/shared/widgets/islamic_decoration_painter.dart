import 'dart:math' as math;
import 'package:flutter/material.dart';

class IslamicDecorationPainter extends CustomPainter {
  final bool isLightMode;

  const IslamicDecorationPainter({required this.isLightMode});

  @override
  void paint(Canvas canvas, Size size) {
    final Color goldColor = isLightMode
        ? const Color(0xFFD4B579).withValues(alpha: 0.35) // Soft gold arch line
        : const Color(0xFFD6BE8D).withValues(alpha: 0.20);

    final Color shadowLeafColor = const Color(
      0xFF2C3E31,
    ).withValues(alpha: 0.08); // Soft leaf shadow

    final Color deepGreen = const Color(0xFF3B4E3E); // Dark olive green
    final Color mediumGreen = const Color(0xFF6E8672); // Medium sage green

    // ==========================================
    // 1. TOP-RIGHT & BOTTOM-LEFT CLEAN ARCHES
    // ==========================================
    _drawSubtleArch(canvas, size, goldColor, isTopRight: true);
    _drawSubtleArch(canvas, size, goldColor, isTopRight: false);

    // ==========================================
    // 2. TOP-LEFT CORNER: NATURAL OLIVE BRANCH & SHADOW
    // ==========================================
    _drawTopLeftOliveBranchWithShadow(
      canvas,
      size,
      deepGreen,
      mediumGreen,
      shadowLeafColor,
    );

    // ==========================================
    // 3. BOTTOM-RIGHT CORNER: NATURAL OLIVE BRANCH
    // ==========================================
    _drawBottomRightOliveBranch(canvas, size, deepGreen, mediumGreen);
  }

  /// Draws a clean, elegant double ogee arch in the corner without heavy grid lines.
  void _drawSubtleArch(
    Canvas canvas,
    Size size,
    Color color, {
    required bool isTopRight,
  }) {
    final double w = size.width;
    final double h = size.height;

    final Paint borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Paint thinBorderPaint = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final Path archPath = Path();
    final Path outerArchPath = Path();

    if (isTopRight) {
      archPath.moveTo(w * 0.62, 0);
      archPath.cubicTo(w * 0.72, h * 0.12, w * 0.85, h * 0.18, w, h * 0.32);

      outerArchPath.moveTo(w * 0.58, 0);
      outerArchPath.cubicTo(
        w * 0.68,
        h * 0.14,
        w * 0.82,
        h * 0.20,
        w,
        h * 0.35,
      );
    } else {
      archPath.moveTo(0, h * 0.68);
      archPath.cubicTo(w * 0.18, h * 0.82, w * 0.32, h * 0.88, w * 0.42, h);

      outerArchPath.moveTo(0, h * 0.65);
      outerArchPath.cubicTo(
        w * 0.20,
        h * 0.80,
        w * 0.35,
        h * 0.86,
        w * 0.45,
        h,
      );
    }

    canvas.drawPath(archPath, borderPaint);
    canvas.drawPath(outerArchPath, thinBorderPaint);
  }

  /// Draws the top-left olive branch and soft blurred shadow.
  void _drawTopLeftOliveBranchWithShadow(
    Canvas canvas,
    Size size,
    Color deepGreen,
    Color mediumGreen,
    Color shadowColor,
  ) {
    canvas.save();
    canvas.translate(size.width * 0.08, size.height * 0.08);
    canvas.rotate(-math.pi / 6.0);

    // 1. Shadow overlay underneath branch
    final Paint shadowPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

    final Paint shadowStemPaint = Paint()
      ..color = shadowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    final Path shadowStem = Path()
      ..moveTo(-size.width * 0.15, -size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.06,
        size.width * 0.38,
        size.height * 0.26,
      );
    canvas.drawPath(shadowStem, shadowStemPaint);

    void drawShadowLeaf(Offset pos, double rot, double len) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      final Path leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-len * 0.24, -len * 0.4, 0, -len)
        ..quadraticBezierTo(len * 0.24, -len * 0.4, 0, 0);
      canvas.drawPath(leaf, shadowPaint);
      canvas.restore();
    }

    drawShadowLeaf(const Offset(0, 0), -0.7, 52.0);
    drawShadowLeaf(const Offset(38, 14), 0.7, 58.0);
    drawShadowLeaf(const Offset(76, 30), -0.6, 56.0);
    drawShadowLeaf(const Offset(114, 52), 0.6, 64.0);
    drawShadowLeaf(const Offset(152, 78), -0.5, 60.0);

    // 2. Real Green Olive Branch on top of shadow
    canvas.translate(-10, -10);

    final Paint stemPaint = Paint()
      ..color =
          const Color(0xFF4E3D28) // Woody brown stem
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final Path realStem = Path()
      ..moveTo(-size.width * 0.15, -size.height * 0.08)
      ..quadraticBezierTo(
        size.width * 0.12,
        size.height * 0.06,
        size.width * 0.38,
        size.height * 0.26,
      );
    canvas.drawPath(realStem, stemPaint);

    void drawBranchLeaf(Offset pos, double rot, double len) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);

      final Path leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-len * 0.22, -len * 0.4, 0, -len)
        ..quadraticBezierTo(len * 0.22, -len * 0.4, 0, 0);

      final Paint leafFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [deepGreen, mediumGreen],
        ).createShader(Rect.fromLTWH(-len * 0.3, -len, len * 0.6, len))
        ..style = PaintingStyle.fill;

      canvas.drawPath(leafPath, leafFill);

      final Paint leafOutline = Paint()
        ..color = deepGreen.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(leafPath, leafOutline);

      final Paint vein = Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset.zero, Offset(0, -len * 0.92), vein);

      canvas.restore();
    }

    drawBranchLeaf(const Offset(0, 0), -0.7, 48.0);
    drawBranchLeaf(const Offset(38, 14), 0.7, 54.0);
    drawBranchLeaf(const Offset(76, 30), -0.6, 52.0);
    drawBranchLeaf(const Offset(114, 52), 0.6, 60.0);
    drawBranchLeaf(const Offset(152, 78), -0.5, 56.0);

    canvas.restore();
  }

  /// Draws a detailed, natural green olive branch in the bottom-right corner.
  void _drawBottomRightOliveBranch(
    Canvas canvas,
    Size size,
    Color deepGreen,
    Color mediumGreen,
  ) {
    canvas.save();
    canvas.translate(size.width, size.height);
    canvas.rotate(-math.pi * 0.70);

    final double len = size.height * 0.50;

    final Paint stemPaint = Paint()
      ..color = const Color(0xFF4E3D28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final Path stem = Path()
      ..moveTo(-len * 0.1, 0)
      ..quadraticBezierTo(len * 0.4, len * 0.12, len * 0.96, len * 0.04);
    canvas.drawPath(stem, stemPaint);

    void drawGreenLeaf(Offset pos, double angleRad, double leafSize) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angleRad);

      final Path leafPath = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-leafSize * 0.22, -leafSize * 0.4, 0, -leafSize)
        ..quadraticBezierTo(leafSize * 0.22, -leafSize * 0.4, 0, 0);

      final Paint leafPaint = Paint()
        ..shader =
            LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [deepGreen, mediumGreen],
            ).createShader(
              Rect.fromLTWH(
                -leafSize * 0.3,
                -leafSize,
                leafSize * 0.6,
                leafSize,
              ),
            )
        ..style = PaintingStyle.fill;

      canvas.drawPath(leafPath, leafPaint);

      final Paint strokePaint = Paint()
        ..color = deepGreen.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(leafPath, strokePaint);

      final Paint veinPaint = Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset.zero, Offset(0, -leafSize * 0.92), veinPaint);

      canvas.restore();
    }

    Offset getStemPoint(double t) {
      final Offset p0 = Offset(-len * 0.1, 0);
      final Offset p1 = Offset(len * 0.4, len * 0.12);
      final Offset p2 = Offset(len * 0.96, len * 0.04);

      final double x =
          (1 - t) * (1 - t) * p0.dx + 2 * (1 - t) * t * p1.dx + t * t * p2.dx;
      final double y =
          (1 - t) * (1 - t) * p0.dy + 2 * (1 - t) * t * p1.dy + t * t * p2.dy;
      return Offset(x, y);
    }

    drawGreenLeaf(getStemPoint(0.96), 1.25, 46.0);
    drawGreenLeaf(getStemPoint(0.85), -1.15, 52.0);
    drawGreenLeaf(getStemPoint(0.72), 1.30, 56.0);
    drawGreenLeaf(getStemPoint(0.60), -1.05, 58.0);
    drawGreenLeaf(getStemPoint(0.48), 1.20, 60.0);
    drawGreenLeaf(getStemPoint(0.35), -1.20, 54.0);
    drawGreenLeaf(getStemPoint(0.22), 1.05, 48.0);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant IslamicDecorationPainter oldDelegate) {
    return oldDelegate.isLightMode != isLightMode;
  }
}
