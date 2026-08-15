import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../managers/settings_manager.dart';

/// Dedicated Tasbeeh Screen for the "ذكر" application.
/// Minimal, elegant, focused strictly on digital Tasbeeh counting without any Adhkar or Quran text.
class TasbeehPage extends StatefulWidget {
  const TasbeehPage({super.key});

  @override
  State<TasbeehPage> createState() => _TasbeehPageState();
}

class _TasbeehPageState extends State<TasbeehPage> {
  int _counter = 0;
  int _todayTotal = 0;
  bool _isCounterPulsing = false;

  static const String _keyTodayCount = 'tasbeeh_today_count';
  static const String _keyTodayDate = 'tasbeeh_today_date';

  @override
  void initState() {
    super.initState();
    _loadTodayCount();
  }

  Future<void> _loadTodayCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month}-${now.day}';
      final savedDate = prefs.getString(_keyTodayDate) ?? '';

      if (savedDate == dateStr) {
        setState(() {
          _todayTotal = prefs.getInt(_keyTodayCount) ?? 0;
        });
      } else {
        await prefs.setString(_keyTodayDate, dateStr);
        await prefs.setInt(_keyTodayCount, 0);
        setState(() {
          _todayTotal = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTodayCount, _todayTotal);
    } catch (_) {}
  }

  void _incrementCounter() {
    if (SettingsManager.vibrationOption.value) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _counter++;
      _todayTotal++;
      _isCounterPulsing = true;
    });
    _saveProgress();

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _isCounterPulsing = false;
        });
      }
    });
  }

  Future<void> _resetCounter() async {
    if (SettingsManager.vibrationOption.value) {
      HapticFeedback.mediumImpact();
    }
    setState(() {
      _counter = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161A15) : const Color(0xFFF7F2E8);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // Fullscreen Fixed Viewport Background & Ornaments
            const AppBackground(),

            // 3. Main Content Scrollable Area
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top Header Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: _buildHeader(context),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 10,
                        bottom: 90, // Bottom nav padding
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large Digital Counter Card
                          _buildCounterCard(context),

                          const SizedBox(height: 36),

                          // Large Circular Tap Button
                          _buildTapButton(context),

                          const SizedBox(height: 32),

                          // Today's Total Count Label
                          _buildTodayLabel(context),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Floating Rounded Bottom Navigation Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: const FloatingBottomNavBar(selectedIndex: 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Header Bar
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Small Reset Button (Physical Right side in RTL)
        Row(
          children: [
            Text(
              'المسبحة',
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF6F1E7)
                    : AppColors.primaryLight,
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _resetCounter,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFFC5A059),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'تصفير',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFD8CEBE)
                            : const Color(0xFF4E5B4E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Back Button (Physical Left side in RTL)
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

  /// Digital Counter Card
  Widget _buildCounterCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x28000000) : const Color(0x10000000),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'عدد التكرار الحالي',
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedScale(
            scale: _isCounterPulsing ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: Text(
              '$_counter',
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFF6F1E7)
                    : AppColors.primaryLight,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Golden Rosette Divider
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? const Color(0x00C9A15B)
                          : const Color(0x00C5A059),
                      isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFFC5A059),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: isDark
                      ? const Color(0xFFC9A15B)
                      : const Color(0xFFC5A059),
                ),
              ),
              Container(
                width: 60,
                height: 1.2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark
                          ? const Color(0xFFC9A15B)
                          : const Color(0xFFC5A059),
                      isDark
                          ? const Color(0x00C9A15B)
                          : const Color(0x00C5A059),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Large Circular Tap Button
  Widget _buildTapButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _incrementCounter,
        customBorder: const CircleBorder(),
        splashColor: isDark ? const Color(0x33C9A15B) : const Color(0x33C5A059),
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
            border: Border.all(
              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFFC5A059),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x35000000)
                    : const Color(0x18000000),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 42,
                color: isDark
                    ? const Color(0xFFC9A15B)
                    : const Color(0xFF4E5B4E),
              ),
              const SizedBox(height: 6),
              Text(
                'اضغط للتسبيح',
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFF6F1E7)
                      : const Color(0xFF4E5B4E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Today's Total Count Label
  Widget _buildTodayLabel(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 18,
            color: isDark ? const Color(0xFFC9A15B) : const Color(0xFFC5A059),
          ),
          const SizedBox(width: 8),
          Text(
            'إجمالي التسبيح اليوم: $_todayTotal',
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
            ),
          ),
        ],
      ),
    );
  }
}
