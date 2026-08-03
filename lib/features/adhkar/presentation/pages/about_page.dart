import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';

/// The About App Screen for the "ذكر" application.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161A15) : const Color(0xFFF8F4EC);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Fullscreen Fixed Viewport Background & Ornaments
            const AppBackground(),

            // 3. Main Content Layout Canvas
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 18,
                          right: 18,
                          top: 14,
                          bottom: 95, // Space for floating bottom nav bar
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Header Row (Back Button & Title)
                            _buildHeader(context),

                            const SizedBox(height: 24),

                            // App Logo
                            Image.asset(
                              'assets/images/logo2.png',
                              width: 135,
                              height: 135,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 16),

                            // App Name
                            Text(
                              'مع الرسول ﷺ من الصباح إلى المساء',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFF6F1E7)
                                    : AppColors.primaryLight,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Version Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F241D)
                                    : const Color(0xFFF0E8DA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFEADFCF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'الإصدار 1.0.0',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFC9A15B)
                                      : const Color(0xFF4E5B4E),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Description Card
                            _buildDescriptionCard(context),

                            const SizedBox(height: 18),

                            // Build & Metadata Info Card
                            _buildMetadataCard(context),

                            const SizedBox(height: 32),

                            // Bottom Copyright Notice
                            Text(
                              '© 2026 All Rights Reserved.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF8E998B)
                                    : const Color(0xFF889189),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Floating Rounded Bottom Navigation Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: const FloatingBottomNavBar(selectedIndex: 4),
            ),
          ],
        ),
      ),
    );
  }

  /// Header Bar with Back Button & Screen Title
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF353E32)
                    : const Color(0xFFEADFCF),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x20000000)
                      : const Color(0x0A000000),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'عن التطبيق',
          style: TextStyle(
            fontFamily: 'Fustat',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
          ),
        ),
      ],
    );
  }

  /// Description Card Container
  Widget _buildDescriptionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x10000000),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        'تطبيق بسيط يهدف إلى تسهيل قراءة الأذكار والأدعية اليومية بتصميم هادئ وتجربة استخدام مريحة.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Fustat',
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF424942),
          height: 1.7,
        ),
      ),
    );
  }

  /// Metadata Info Card (Version, Build Number, Last Update)
  Widget _buildMetadataCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x10000000),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            context: context,
            label: 'الإصدار (Version)',
            value: '1.0.0',
          ),
          Divider(
            height: 20,
            color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0),
          ),
          _buildInfoRow(
            context: context,
            label: 'رقم البناء (Build Number)',
            value: '1',
          ),
          Divider(
            height: 20,
            color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0),
          ),
          _buildInfoRow(
            context: context,
            label: 'آخر تحديث (Last Update)',
            value: 'أغسطس 2026',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '• $label',
          style: TextStyle(
            fontFamily: 'Fustat',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Fustat',
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F),
          ),
        ),
      ],
    );
  }
}
