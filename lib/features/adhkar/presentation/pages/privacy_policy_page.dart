import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';

/// The Privacy Policy Screen for the "ذكر" application.
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161A15) : const Color(0xFFF8F4EC);

    final List<Map<String, dynamic>> policySections = [
      {
        'title': 'عدم جمع البيانات الشخصية',
        'desc':
            'نلتزم في تطبيق "ذكر" بعدم جمع أو طلب أو استخراج أي بيانات شخصية غير ضرورية أو معلومات حساسة خاصة بالمستخدم.',
        'icon': Icons.security_rounded,
      },
      {
        'title': 'التخزين المحلي للبيانات',
        'desc':
            'تُحفظ جميع إعدادات التطبيق والمفضلة ومواضع القراءة محلياً على ذاكرة جهازك فقط ولا يتم رفعها أو مشاركتها مع أي خوادم خارجية.',
        'icon': Icons.folder_special_rounded,
      },
      {
        'title': 'استخدام التنبيهات والإشعارات',
        'desc':
            'تُستخدم التنبيهات والإشعارات محلياً فقط للتذكير بأذكار الصباح والمساء والأدعية اليومية حسب تفضيلاتك الإختيارية.',
        'icon': Icons.notifications_none_rounded,
      },
      {
        'title': 'حماية البيانات وعدم بيعها',
        'desc':
            'لا نبيع ولا نتبادل ولا نُشارك أي معلومات أو بيانات خاصة بالمستخدمين مع أي أطراف ثالثة أو شركات إعلانية تحت أي ظرف.',
        'icon': Icons.verified_user_rounded,
      },
      {
        'title': 'التواصل والدعم الفني',
        'desc':
            'يسعدنا دائماً استلام أسئلتك واستفساراتك المتعلقة بسياسة الخصوصية واستخدام التطبيق عبر وسائل التواصل المتاحة.',
        'icon': Icons.mail_outline_rounded,
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Fullscreen Fixed Viewport Background & Ornaments
            const AppBackground(),

            // 3. Main Scrollable Content Canvas
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

                            const SizedBox(height: 18),

                            // Subtitle Description
                            Text(
                              'نلتزم بحماية خصوصيتك وضمان تجربة استخدام آمنة وموثوقة.',
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFD8CEBE)
                                    : const Color(0xFF707973),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // List of Privacy Cards
                            ...policySections.map((sec) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _buildPolicyCard(
                                  context: context,
                                  title: sec['title'] as String,
                                  desc: sec['desc'] as String,
                                  icon: sec['icon'] as IconData,
                                ),
                              );
                            }),

                            const SizedBox(height: 20),

                            // Bottom Copyright Notice
                            Center(
                              child: Text(
                                '© 2026 All Rights Reserved.',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF8E998B)
                                      : const Color(0xFF889189),
                                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Title Text (Physical Right)
        Expanded(
          child: Text(
            'سياسة الخصوصية',
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Back Button (Physical Left)
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
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E),
            ),
          ),
        ),
      ],
    );
  }

  /// Individual Policy Section Card
  Widget _buildPolicyCard({
    required BuildContext context,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x0C000000),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF353E32)
                    : const Color(0xFFEADFCF),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fustat',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFF6F1E7)
                        : const Color(0xFF1E281F),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: TextStyle(
                    fontFamily: 'Fustat',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFD8CEBE)
                        : const Color(0xFF555F56),
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
