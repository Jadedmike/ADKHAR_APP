import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'single_dhikr_page.dart';
import '../managers/settings_manager.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_radius.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_scaffold.dart';

/// The Splash Screen of the Adhkar application.
/// Refined to match the reference design with high visual precision.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color calligraphicColor = isDark
        ? AppColors.primaryDark
        : AppColors.primaryLight;
    final Color sloganColor = isDark
        ? AppColors.goldDark
        : const Color(0xFFC5A059);
    final Color subtitleColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xFF424942);

    return AppScaffold(
      wrapWithSafeArea: false,
      body: Stack(
        children: [
          // 1. Warm Beige Background with Soft Texture Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161A15)
                    : const Color(0xFFF7F2E8),
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.6),
                  radius: 1.3,
                  colors: isDark
                      ? [
                          const Color(0xFF1D221C),
                          const Color(0xFF161A15),
                          const Color(0xFF111410),
                        ]
                      : [
                          const Color(0xFFFAF7F0),
                          const Color(0xFFF7F2E8),
                          const Color(0xFFEFE9DC),
                        ],
                ),
              ),
            ),
          ),

          // 2. Soft Diagonal Light Rays from Upper-Left Corner
          Positioned.fill(
            child: CustomPaint(painter: LightRaysPainter(isDark: isDark)),
          ),

          // 3. Gold Arches Corner Ornaments (Slightly lighter / 65% opacity)
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.45 : 0.65,
              child: Image.asset('assets/images/gold.png', fit: BoxFit.cover),
            ),
          ),

          // 4. Olive Branches Corner Ornaments
          Positioned.fill(
            child: Image.asset(
              'assets/images/olivebranches.png',
              fit: BoxFit.cover,
            ),
          ),

          // 5. Main Content Stack
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Spacer(flex: 2),

                              // Main Logo Asset (Enlarged ~15%)
                              Image.asset(
                                'assets/images/logo2.png',
                                width: 305,
                                height: 305,
                                fit: BoxFit.contain,
                              ),

                              const SizedBox(height: 0),

                              // Main Title: "ذِكْر" (Exact font family & typography preserved)
                              Text(
                                'ذِكْر',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 54,
                                  color: calligraphicColor,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 10),

                              // Wider Golden Divider with Center Ornament
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 90,
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0x00C5A059),
                                          sloganColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Image.asset(
                                      'assets/images/gold.png',
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Container(
                                    width: 90,
                                    height: 1.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          sloganColor,
                                          const Color(0x00C5A059),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Subtitle: "أذكار وأدعية تصنع السكينة"
                              Text(
                                'أذكار وأدعية تصنع السكينة',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: subtitleColor,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const SizedBox(height: 18),

                              // Slogan: "مع الرسول ﷺ من الصباح إلى المساء"
                              Text(
                                'مع الرسول ﷺ من الصباح إلى المساء',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: sloganColor,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              const Spacer(flex: 3),

                              // CTA Button ("ابدأ")
                              Container(
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.borderRound,
                                  boxShadow: [
                                    BoxShadow(
                                      color: calligraphicColor.withValues(
                                        alpha: 0.28,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  height: 52,
                                  child: AppButton(
                                    text: 'ابدأ',
                                    isFullWidth: true,
                                    borderRadius: AppRadius.borderRound,
                                    onPressed: () {
                                      final lastPosition =
                                          SettingsManager.getLastReadingPosition();
                                      if (lastPosition != null &&
                                          SettingsManager
                                              .rememberLastPosition
                                              .value) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SingleDhikrPage(
                                                  categoryTitle: lastPosition
                                                      .categoryTitle,
                                                  jsonAssetPath: lastPosition
                                                      .jsonAssetPath,
                                                  initialIndex:
                                                      lastPosition.index,
                                                  initialScrollOffset:
                                                      lastPosition.scrollOffset,
                                                ),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomePage(),
                                          ),
                                        );
                                      }
                                    },
                                    icon: CustomPaint(
                                      size: const Size(18, 18),
                                      painter: const OliveLeafButtonIconPainter(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(flex: 1),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints subtle diagonal light rays coming from the upper-left corner
class LightRaysPainter extends CustomPainter {
  final bool isDark;

  const LightRaysPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Color beamColor = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : Colors.white.withValues(alpha: 0.38);

    final Paint paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          beamColor,
          beamColor.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.95],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width * 0.75, 0);
    path.lineTo(size.width, size.height * 0.45);
    path.lineTo(0, size.height * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant LightRaysPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}

/// A custom painter to draw the small olive leaf icon inside the button
class OliveLeafButtonIconPainter extends CustomPainter {
  final Color color;

  const OliveLeafButtonIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;
    final double h = size.height;

    final Paint stemPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(w * 0.25, h * 0.75),
      Offset(w * 0.75, h * 0.25),
      stemPaint,
    );

    void drawSmallLeaf(
      Canvas canvas,
      Offset pos,
      double angle,
      double leafSize,
    ) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      final Path leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-leafSize * 0.28, -leafSize * 0.4, 0, -leafSize)
        ..quadraticBezierTo(leafSize * 0.28, -leafSize * 0.4, 0, 0);

      canvas.drawPath(leaf, paint);
      canvas.restore();
    }

    drawSmallLeaf(canvas, Offset(w * 0.75, h * 0.25), math.pi / 4, 7.5);
    drawSmallLeaf(canvas, Offset(w * 0.5, h * 0.5), -math.pi / 5.5, 6.5);
    drawSmallLeaf(canvas, Offset(w * 0.5, h * 0.5), math.pi / 1.5, 6.5);
  }

  @override
  bool shouldRepaint(covariant OliveLeafButtonIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
