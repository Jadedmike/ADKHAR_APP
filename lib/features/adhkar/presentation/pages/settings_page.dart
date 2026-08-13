import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_page.dart';
import 'contact_us_page.dart';
import 'privacy_policy_page.dart';
import '../../../../config/theme/app_assets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_page_transitions.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../managers/settings_manager.dart';

/// The Settings Screen for the "ذكر" application.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // General Settings State
  String _selectedLanguage = 'العربية';

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

            // 3. Main Scrollable Settings Canvas
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
                          bottom: 105,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Title & Subtitle
                            Text(
                              'الإعدادات',
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFF6F1E7)
                                    : AppColors.primaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'تخصيص الخيارات العامة والتنبيهات والقراءة',
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

                            // Section 1: GENERAL (عام)
                            _buildSectionGroup(
                              title: 'عام',
                              children: [
                                _buildDropdownTile(
                                  icon: Icons.language_rounded,
                                  title: 'اللغة',
                                  value: _selectedLanguage,
                                  options: const [
                                    'العربية',
                                    'English',
                                    'Türkçe',
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedLanguage = val);
                                    }
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<String>(
                                  valueListenable:
                                      SettingsManager.themeModeOption,
                                  builder: (context, currentThemeOpt, child) {
                                    return _buildDropdownTile(
                                      icon: Icons.palette_outlined,
                                      title: 'المظهر',
                                      value: currentThemeOpt,
                                      options: const [
                                        'فاتح',
                                        'داكن',
                                        'تكيّف حسب النظام',
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          SettingsManager.setThemeModeOption(
                                            val,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<String>(
                                  valueListenable:
                                      SettingsManager.fontSizeOption,
                                  builder: (context, currentFontSize, child) {
                                    return _buildDropdownTile(
                                      icon: Icons.format_size_rounded,
                                      title: 'حجم الخط',
                                      value: currentFontSize,
                                      options: const [
                                        'صغير',
                                        'متوسط',
                                        'كبير',
                                        'كبير جداً',
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          SettingsManager.setFontSizeOption(
                                            val,
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Section 2: READING (القراءة)
                            _buildSectionGroup(
                              title: 'القراءة',
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable: SettingsManager.keepScreenOn,
                                  builder: (context, keepScreenOn, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.phone_android_rounded,
                                      title: 'إبقاء الشاشة مفعلة أثناء القراءة',
                                      value: keepScreenOn,
                                      onChanged: (val) =>
                                          SettingsManager.setKeepScreenOn(val),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      SettingsManager.showTranslation,
                                  builder: (context, showTranslation, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.translate_rounded,
                                      title: 'إظهار الترجمة (إن وجدت)',
                                      value: showTranslation,
                                      onChanged: (val) =>
                                          SettingsManager.setShowTranslation(
                                            val,
                                          ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: SettingsManager.showSource,
                                  builder: (context, showSource, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.menu_book_rounded,
                                      title: 'إظهار المصدر والترخريج',
                                      value: showSource,
                                      onChanged: (val) =>
                                          SettingsManager.setShowSource(val),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable: SettingsManager.copySource,
                                  builder: (context, copySource, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.copy_rounded,
                                      title: 'نسخ المصدر عند نسخ الذكر',
                                      value: copySource,
                                      onChanged: (val) =>
                                          SettingsManager.setCopySource(val),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      SettingsManager.rememberLastPosition,
                                  builder: (context, rememberLast, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.bookmark_added_outlined,
                                      title: 'تذكر آخر موضع قراءة',
                                      value: rememberLast,
                                      onChanged: (val) =>
                                          SettingsManager.setRememberLastPosition(
                                            val,
                                          ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      SettingsManager.vibrationOption,
                                  builder: (context, vibration, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.vibration_rounded,
                                      title: 'تفعيل الاهتزاز عند التسبيح',
                                      value: vibration,
                                      onChanged: (val) =>
                                          SettingsManager.setVibrationOption(
                                            val,
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Section 3: NOTIFICATIONS (التنبيهات)
                            _buildSectionGroup(
                              title: 'التنبيهات',
                              children: [
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      SettingsManager.morningReminder,
                                  builder: (context, morning, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.wb_sunny_outlined,
                                      title: 'تنبيه أذكار الصباح',
                                      value: morning,
                                      onChanged: (val) =>
                                          SettingsManager.setMorningReminder(
                                            val,
                                          ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      SettingsManager.eveningReminder,
                                  builder: (context, evening, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.nights_stay_outlined,
                                      title: 'تنبيه أذكار المساء',
                                      value: evening,
                                      onChanged: (val) =>
                                          SettingsManager.setEveningReminder(
                                            val,
                                          ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                ValueListenableBuilder<bool>(
                                  valueListenable:
                                      SettingsManager.dailyReminder,
                                  builder: (context, daily, child) {
                                    return _buildSwitchTile(
                                      icon: Icons.access_alarm_rounded,
                                      title: 'التذكير اليومي للأدعية',
                                      value: daily,
                                      onChanged: (val) =>
                                          SettingsManager.setDailyReminder(val),
                                    );
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Section 4: ABOUT (حول التطبيق)
                            _buildSectionGroup(
                              title: 'حول التطبيق',
                              children: [
                                _buildActionTile(
                                  icon: Icons.info_outline_rounded,
                                  title: 'عن التطبيق',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppPageRoute.create(const AboutPage()),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                _buildActionTile(
                                  icon: Icons.privacy_tip_outlined,
                                  title: 'سياسة الخصوصية',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppPageRoute.create(
                                        const PrivacyPolicyPage(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                _buildActionTile(
                                  icon: Icons.mail_outline_rounded,
                                  title: 'تواصل معنا',
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppPageRoute.create(
                                        const ContactUsPage(),
                                      ),
                                    );
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                _buildActionTile(
                                  icon: Icons.star_border_rounded,
                                  title: 'تقييم التطبيق',
                                  onTap: () async {
                                    const String appPackageName = '';
                                    if (appPackageName.isNotEmpty) {
                                      final Uri playStoreUri = Uri.parse(
                                        'market://details?id=$appPackageName',
                                      );
                                      final Uri webPlayStoreUri = Uri.parse(
                                        'https://play.google.com/store/apps/details?id=$appPackageName',
                                      );
                                      try {
                                        if (await canLaunchUrl(playStoreUri)) {
                                          await launchUrl(
                                            playStoreUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        } else {
                                          await launchUrl(
                                            webPlayStoreUri,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );
                                        }
                                        return;
                                      } catch (_) {}
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'سيصبح التقييم متاحًا بعد نشر التطبيق.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Fustat',
                                            ),
                                          ),
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                Divider(
                                  height: 22,
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFF3ECE0),
                                ),
                                _buildActionTile(
                                  icon: Icons.share_outlined,
                                  title: 'مشاركة التطبيق',
                                  onTap: () async {
                                    const String appLink =
                                        'سيتم إضافة رابط التطبيق بعد نشره.';
                                    final String shareText =
                                        'جرّب تطبيق "مع الرسول ﷺ من الصباح إلى المساء"\n\n'
                                        'تطبيق مجاني للأذكار والأدعية اليومية بتصميم بسيط وأنيق.\n\n'
                                        '$appLink';
                                    try {
                                      await Share.share(shareText);
                                    } catch (_) {}
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // Informational Card (صدقة جارية)
                            _buildInformationalDuaCard(),

                            const SizedBox(height: 22),

                            // Section 5: CHARITY CARD (صدقة جارية / Share Application)
                            _buildCharityCard(),
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

  /// Section Card Group Container
  Widget _buildSectionGroup({
    required String title,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x20000000)
                    : const Color(0x0A000000),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Switch Option Tile
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F241D)
                      : const Color(0xFFF7F2E8),
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
                  size: 20,
                  color: isDark
                      ? const Color(0xFFC9A15B)
                      : const Color(0xFF4E5B4E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fustat',
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFF6F1E7)
                        : const Color(0xFF1E281F),
                  ),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: isDark
              ? const Color(0xFFC9A15B)
              : const Color(0xFF4E5B4E),
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Dropdown Selection Tile
  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F241D)
                    : const Color(0xFFF7F2E8),
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
                size: 20,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: isDark
                  ? const Color(0xFF1F241D)
                  : const Color(0xFFFFFDF9),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
              onChanged: onChanged,
              items: options.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(
                    opt,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      color: isDark
                          ? const Color(0xFFF6F1E7)
                          : const Color(0xFF1E281F),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  /// Action Arrow Tile
  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F241D)
                      : const Color(0xFFF7F2E8),
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
                  size: 20,
                  color: isDark
                      ? const Color(0xFFC9A15B)
                      : const Color(0xFF4E5B4E),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
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
          Icon(
            Icons.chevron_left_rounded,
            size: 20,
            color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
          ),
        ],
      ),
    );
  }

  /// Read-only Informational Card (صدقة جارية)
  Widget _buildInformationalDuaCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'صدقة جارية',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'نسأل الله أن يجعل هذا العمل صدقةً جاريةً عن روح المرحوم والد سلمى الحيحي الحسن الحيحي ، وأن يتقبله صدقةً عن سلمى الحيحي، وأن ينفع به كل من قرأ ذكرًا أو دعا بدعاء.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Premium Charity Card (صدقة جارية)
  Widget _buildCharityCard() {
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
      child: Stack(
        children: [
          // Corner Gold Arch Graphic Overlay
          Positioned(
            left: 0,
            top: 0,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                AppAssets.gold,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volunteer_activism_rounded,
                    color: isDark
                        ? const Color(0xFFC9A15B)
                        : const Color(0xFFC5A059),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'صدقة جارية',
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFF6F1E7)
                          : AppColors.primaryLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                'انشر التطبيق ليكون لك أجر كل من قرأ ذكراً أو دعاءً بسببه.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFD8CEBE)
                      : const Color(0xFF707973),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 16),

              // Share Button Inside Card
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFFC9A15B)
                        : const Color(0xFF4E5B4E),
                    foregroundColor: isDark
                        ? const Color(0xFF161A15)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text(
                    'مشاركة التطبيق',
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
