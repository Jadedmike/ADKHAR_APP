import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../../shared/widgets/glass_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/screen_header.dart';

/// The Contact Us Screen for the "ذكر" application.
class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  static const String _contactEmail = 'a.xiondigital.j@gmail.com';

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(scheme: 'mailto', path: _contactEmail);
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

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

            // 3. Main Content Scrollable Canvas
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row (Back Button & Title)
                            _buildHeader(context),

                            const SizedBox(height: 28),

                            // Main Contact Card
                            _buildContactCard(context),
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
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: const FloatingBottomNavBar(selectedIndex: 4),
            ),
          ],
        ),
      ),
    );
  }

  /// Header Bar with Back Button & Screen Title
  Widget _buildHeader(BuildContext context) {
    return ScreenHeader(
      title: 'تواصل معنا',
      trailing: GlassIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        size: 42,
        iconSize: 18,
        borderRadius: BorderRadius.circular(16),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Main Contact Card
  Widget _buildContactCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFFC5A059),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFFC5A059),
              size: 32,
            ),
          ),

          const SizedBox(height: 20),

          // Message Text
          Text(
            'إذا واجهت أي مشكلة أو لديك اقتراح لتحسين التطبيق، يسعدنا التواصل معك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF424942),
              height: 1.7,
            ),
          ),

          const SizedBox(height: 24),

          // Email Display Container
          Directionality(
            textDirection: TextDirection.ltr,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F241D)
                    : const Color(0xFFF7F2E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF353E32)
                      : const Color(0xFFEADFCF),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.alternate_email_rounded,
                    size: 18,
                    color: isDark
                        ? const Color(0xFFC9A15B)
                        : const Color(0xFF4E5B4E),
                  ),
                  const SizedBox(width: 10),
                  SelectableText(
                    _contactEmail,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF6F1E7)
                          : const Color(0xFF1E281F),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Single Send Email Button
          GlassButton(
            height: 52,
            isFullWidth: true,
            borderRadius: BorderRadius.circular(26),
            label: 'إرسال بريد إلكتروني',
            icon: const Icon(Icons.send_rounded, size: 20),
            borderColor: isDark
                ? const Color(0xFFC9A15B).withValues(alpha: 0.5)
                : const Color(0xFFC5A059).withValues(alpha: 0.5),
            textColor: isDark
                ? const Color(0xFFC9A15B)
                : const Color(0xFF333E32),
            iconColor: isDark
                ? const Color(0xFFC9A15B)
                : const Color(0xFF333E32),
            onPressed: _launchEmail,
          ),
        ],
      ),
    );
  }
}
