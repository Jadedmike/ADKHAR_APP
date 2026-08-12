import 'dart:math' as math;
import 'package:flutter/material.dart';

class LogoPainter extends CustomPainter {
  const LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double radius = math.min(w, h) * 0.45;
    final Offset center = Offset(w / 2, h / 2);

    // ==========================================
    // 1. GOLDEN CRESCENT MOON
    // ==========================================
    final Paint moonPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          Color(0xFF997A44), // Deeper bronze gold
          Color(0xFFD4BF8A), // Radiant soft gold
          Color(0xFFF1E6CC), // Champagne highlight gold
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    // Crescent shape by subtracting inner offset circle
    final Path outerCircle = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final Offset innerCenter = center + Offset(-radius * 0.28, -radius * 0.28);
    final Path innerCircle = Path()
      ..addOval(Rect.fromCircle(center: innerCenter, radius: radius * 0.96));

    final Path crescentPath = Path.combine(
      PathOperation.difference,
      outerCircle,
      innerCircle,
    );

    canvas.drawPath(crescentPath, moonPaint);

    // ==========================================
    // 2. LARGE BROAD LEAF (CENTER HOLLOW OF CRESCENT)
    // ==========================================
    canvas.save();
    // Position base of large leaf inside the lower crescent hollow
    final Offset leafBase = center + Offset(radius * 0.08, radius * 0.26);
    canvas.translate(leafBase.dx, leafBase.dy);
    canvas.rotate(0.22); // Tilt slightly to the right

    final double leafLen = radius * 0.95;
    final double leafWidth = radius * 0.48;

    final Path broadLeafPath = Path();
    broadLeafPath.moveTo(0, 0);
    // Left broad curve
    broadLeafPath.cubicTo(
      -leafWidth * 0.68,
      -leafLen * 0.35,
      -leafWidth * 0.58,
      -leafLen * 0.78,
      0,
      -leafLen,
    );
    // Right broad curve
    broadLeafPath.cubicTo(
      leafWidth * 0.58,
      -leafLen * 0.78,
      leafWidth * 0.68,
      -leafLen * 0.35,
      0,
      0,
    );
    broadLeafPath.close();

    final Paint broadLeafFill = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF3B4E3E), // Deep dark olive base
              Color(0xFF5E7360), // Rich olive midtone
              Color(0xFF8CA38E), // Soft sage highlight tip
            ],
            stops: [0.0, 0.55, 1.0],
          ).createShader(
            Rect.fromLTWH(-leafWidth, -leafLen, leafWidth * 2, leafLen),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(broadLeafPath, broadLeafFill);

    // Outline for large leaf
    final Paint broadLeafOutline = Paint()
      ..color = const Color(0xFF28362A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(broadLeafPath, broadLeafOutline);

    // Center spine vein
    final Paint spinePaint = Paint()
      ..color = const Color(0xAA9EBA9F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final Path spinePath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(leafWidth * 0.04, -leafLen * 0.5, 0, -leafLen * 0.96);
    canvas.drawPath(spinePath, spinePaint);

    // Diagonal side veins
    final Paint sideVeinPaint = Paint()
      ..color = const Color(0x35FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 5; i++) {
      final double t = i * 0.16;
      final double yPos = -leafLen * t;
      canvas.drawLine(
        Offset(0, yPos),
        Offset(-leafWidth * 0.32, yPos - leafLen * 0.08),
        sideVeinPaint,
      );
      canvas.drawLine(
        Offset(0, yPos),
        Offset(leafWidth * 0.32, yPos - leafLen * 0.08),
        sideVeinPaint,
      );
    }
    canvas.restore();

    // ==========================================
    // 3. THIN OLIVE BRANCH (LEFT SIDE)
    // ==========================================
    final Paint stemPaint = Paint()
      ..color = const Color(0xFF4A5F4E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.035
      ..strokeCap = StrokeCap.round;

    final Path stemPath = Path();
    final Offset stemStart = center + Offset(-radius * 0.1, radius * 0.45);
    final Offset stemControl = center + Offset(-radius * 0.4, -radius * 0.1);
    final Offset stemEnd = center + Offset(-radius * 0.35, -radius * 0.55);

    stemPath.moveTo(stemStart.dx, stemStart.dy);
    stemPath.quadraticBezierTo(
      stemControl.dx,
      stemControl.dy,
      stemEnd.dx,
      stemEnd.dy,
    );
    canvas.drawPath(stemPath, stemPaint);

    // Draw small leaves along thin stem
    final Paint leafFillPaint = Paint()..style = PaintingStyle.fill;
    final Paint leafStrokePaint = Paint()
      ..color = const Color(0xFF2C3B2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    void drawLeaf(Offset pos, double angleRad, double leafSize) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angleRad);

      final Path leafPath = Path();
      leafPath.moveTo(0, 0);
      leafPath.quadraticBezierTo(
        -leafSize * 0.25,
        -leafSize * 0.4,
        0,
        -leafSize,
      );
      leafPath.quadraticBezierTo(leafSize * 0.25, -leafSize * 0.4, 0, 0);

      leafFillPaint.shader =
          const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF3B4D3F), Color(0xFF6E8672), Color(0xFF90A894)],
          ).createShader(
            Rect.fromLTWH(-leafSize * 0.3, -leafSize, leafSize * 0.6, leafSize),
          );

      canvas.drawPath(leafPath, leafFillPaint);
      canvas.drawPath(leafPath, leafStrokePaint);

      final Paint veinPaint = Paint()
        ..color = const Color(0x60FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        const Offset(0, 0),
        Offset(0, -leafSize * 0.95),
        veinPaint,
      );

      canvas.restore();
    }

    Offset getPointOnStem(double t) {
      final double x =
          (1 - t) * (1 - t) * stemStart.dx +
          2 * (1 - t) * t * stemControl.dx +
          t * t * stemEnd.dx;
      final double y =
          (1 - t) * (1 - t) * stemStart.dy +
          2 * (1 - t) * t * stemControl.dy +
          t * t * stemEnd.dy;
      return Offset(x, y);
    }

    double getAngleOnStem(double t) {
      final Offset d =
          (stemControl - stemStart) * (2 * (1 - t)) +
          (stemEnd - stemControl) * (2 * t);
      return math.atan2(d.dy, d.dx);
    }

    drawLeaf(
      getPointOnStem(0.98),
      getAngleOnStem(0.98) - math.pi / 2.2,
      radius * 0.32,
    );
    drawLeaf(
      getPointOnStem(0.90),
      getAngleOnStem(0.90) + math.pi / 2.1,
      radius * 0.28,
    );
    drawLeaf(
      getPointOnStem(0.80),
      getAngleOnStem(0.80) - math.pi / 2.3,
      radius * 0.33,
    );
    drawLeaf(
      getPointOnStem(0.68),
      getAngleOnStem(0.68) + math.pi / 1.9,
      radius * 0.31,
    );
    drawLeaf(
      getPointOnStem(0.55),
      getAngleOnStem(0.55) - math.pi / 2.0,
      radius * 0.35,
    );
    drawLeaf(
      getPointOnStem(0.40),
      getAngleOnStem(0.40) + math.pi / 2.2,
      radius * 0.32,
    );
    drawLeaf(
      getPointOnStem(0.28),
      getAngleOnStem(0.28) - math.pi / 2.0,
      radius * 0.30,
    );
    drawLeaf(
      getPointOnStem(0.15),
      getAngleOnStem(0.15) + math.pi / 2.3,
      radius * 0.25,
    );

    // ==========================================
    // 4. OLIVES
    // ==========================================
    void drawOlive(Offset pos, double size, double rotateRad) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rotateRad);

      final Paint oliveStemPaint = Paint()
        ..color = const Color(0xFF4A5F4E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(
        const Offset(0, 0),
        Offset(0, -size * 0.7),
        oliveStemPaint,
      );

      canvas.translate(0, size * 0.4);

      final Rect oliveRect = Rect.fromCenter(
        center: const Offset(0, 0),
        width: size * 0.75,
        height: size * 1.15,
      );
      final Paint olivePaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 0.85,
          colors: const [
            Color(0xFFDFD09E),
            Color(0xFF9E8A4A),
            Color(0xFF6B5B2A),
          ],
          stops: const [0.0, 0.65, 1.0],
        ).createShader(oliveRect)
        ..style = PaintingStyle.fill;

      canvas.drawOval(oliveRect, olivePaint);

      final Paint oliveOutline = Paint()
        ..color = const Color(0x40000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawOval(oliveRect, oliveOutline);

      canvas.restore();
    }

    final Offset olive1Pos = getPointOnStem(0.48);
    drawOlive(
      olive1Pos + Offset(radius * 0.05, radius * 0.05),
      radius * 0.20,
      -0.15,
    );

    final Offset olive2Pos = getPointOnStem(0.32);
    drawOlive(
      olive2Pos + Offset(-radius * 0.08, radius * 0.1),
      radius * 0.19,
      0.25,
    );
  }

  @override
  bool shouldRepaint(covariant LogoPainter oldDelegate) => false;
}
