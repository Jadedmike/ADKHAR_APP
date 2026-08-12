import 'package:flutter/material.dart';

class CalligraphyPainter extends CustomPainter {
  final Color color;

  const CalligraphyPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Helper to draw bold path with fill and outline stroke
    void drawBoldPath(Path path) {
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }

    final double scaleX = size.width / 200.0;
    final double scaleY = size.height / 120.0;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double offsetX = (size.width - 200.0 * scale) / 2;
    final double offsetY = (size.height - 120.0 * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // ==========================================
    // 1. LETTER ذ (Thal) - BOLD HEAVY WEIGHT
    // ==========================================
    final Path thalPath = Path();
    thalPath.moveTo(136, 80);
    thalPath.cubicTo(148, 80, 163, 66, 168, 44);
    thalPath.cubicTo(171, 35, 165, 34, 160, 38);
    thalPath.cubicTo(153, 44, 139, 62, 130, 72);
    thalPath.cubicTo(124, 78, 116, 80, 108, 80);
    thalPath.lineTo(108, 88);
    thalPath.cubicTo(122, 88, 130, 85, 136, 80);
    thalPath.close();
    drawBoldPath(thalPath);

    // Dot above ذ (Thal) - bold rotated diamond
    final Path thalDot = Path();
    thalDot.moveTo(148, 22);
    thalDot.lineTo(155, 15);
    thalDot.lineTo(162, 22);
    thalDot.lineTo(155, 29);
    thalDot.close();
    canvas.drawPath(thalDot, fillPaint);

    // Kasrah (ِ) under ذ - bold stroke
    final Path kasrah = Path();
    kasrah.moveTo(134, 94);
    kasrah.lineTo(124, 104);
    kasrah.lineTo(120, 101);
    kasrah.lineTo(130, 91);
    kasrah.close();
    drawBoldPath(kasrah);

    // ==========================================
    // 2. LETTER ك (Kaf) - BOLD HEAVY WEIGHT
    // ==========================================
    final Path kafPath = Path();
    kafPath.moveTo(114, 78);
    kafPath.cubicTo(119, 58, 121, 38, 116, 22);
    kafPath.cubicTo(114, 15, 108, 12, 105, 16);
    kafPath.cubicTo(108, 24, 108, 48, 100, 72);
    kafPath.cubicTo(96, 82, 85, 84, 74, 84);
    kafPath.lineTo(74, 91);
    kafPath.cubicTo(90, 91, 106, 87, 114, 78);
    kafPath.close();
    drawBoldPath(kafPath);

    // Upper stroke of Kaf (Kashida) - Bold sweep
    final Path kafUpper = Path();
    kafUpper.moveTo(112, 22);
    kafUpper.cubicTo(128, 17, 148, 9, 166, 4);
    kafUpper.cubicTo(171, 3, 171, 1, 166, 2);
    kafUpper.cubicTo(145, 7, 125, 14, 108, 20);
    kafUpper.close();
    drawBoldPath(kafUpper);

    // Inside 'Hamza/Kaf' S-stroke
    final Path kafInnerS = Path();
    kafInnerS.moveTo(96, 46);
    kafInnerS.cubicTo(101, 44, 105, 46, 103, 51);
    kafInnerS.cubicTo(100, 56, 93, 58, 95, 63);
    kafInnerS.cubicTo(97, 66, 102, 64, 103, 62);
    kafInnerS.lineTo(105, 64);
    kafInnerS.cubicTo(102, 68, 94, 70, 92, 65);
    kafInnerS.cubicTo(90, 60, 95, 55, 93, 50);
    kafInnerS.cubicTo(91, 47, 92, 46, 96, 46);
    kafInnerS.close();
    drawBoldPath(kafInnerS);

    // Dammah (ُ) above Kaf - Bold calligraphic loop
    final Path dammah = Path();
    dammah.moveTo(106, 12);
    dammah.cubicTo(111, 8, 116, 10, 114, 16);
    dammah.cubicTo(112, 22, 104, 26, 96, 27);
    dammah.cubicTo(93, 27, 93, 25, 97, 23);
    dammah.cubicTo(103, 20, 106, 16, 106, 12);
    dammah.close();
    drawBoldPath(dammah);

    // ==========================================
    // 3. LETTER ر (Ra) - BOLD HEAVY WEIGHT
    // ==========================================
    final Path raPath = Path();
    raPath.moveTo(76, 84);
    raPath.cubicTo(64, 84, 53, 90, 45, 99);
    raPath.cubicTo(36, 109, 25, 116, 12, 118);
    raPath.cubicTo(8, 119, 8, 116, 12, 114);
    raPath.cubicTo(24, 110, 35, 101, 42, 91);
    raPath.cubicTo(52, 79, 66, 76, 76, 76);
    raPath.close();
    drawBoldPath(raPath);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CalligraphyPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
