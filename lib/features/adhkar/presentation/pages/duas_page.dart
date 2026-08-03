import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_page_transitions.dart';
import '../../../../shared/widgets/animated_card_tap.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../../shared/widgets/staggered_list_fade_item.dart';
import 'category_list_page.dart';
import 'global_search_page.dart';

/// The Duas Screen for the "ذكر" application.
class DuasPage extends StatefulWidget {
  const DuasPage({super.key});

  @override
  State<DuasPage> createState() => _DuasPageState();
}

class _DuasPageState extends State<DuasPage> {
  final List<Map<String, dynamic>> _duaCategories = [
    {
      'title': 'أدعية من القرآن الكريم',
      'desc': 'مجموعة مباركة من دعوات الأنبياء والصالحين في القرآن',
      'icon': Icons.menu_book_outlined,
      'jsonPath': 'assets/json/quran_duas.json',
    },
    {
      'title': 'أدعية من السنة النبوية',
      'desc': 'الأدعية المأثورة عن النبي ﷺ في مختلف الأحوال',
      'icon': Icons.synagogue_outlined,
      'jsonPath': 'assets/json/prophetic_duas.json',
    },
    {
      'title': 'أدعية الاستغفار والتوبة',
      'desc': 'أدعية طلب العفو والرحمة والمغفرة',
      'icon': Icons.auto_awesome_outlined,
      'jsonPath': 'assets/json/forgiveness_duas.json',
    },
    {
      'title': 'أدعية الرزق والبركة',
      'desc': 'سؤال الله البركة في العمر والمال والعمل',
      'icon': Icons.volunteer_activism_outlined,
      'jsonPath': 'assets/json/quran_duas.json',
    },
    {
      'title': 'أدعية الوالدين والذرية',
      'desc': 'دعوات بر الوالدين وصلاح الأولاد والذرية',
      'icon': Icons.family_restroom_outlined,
      'jsonPath': 'assets/json/quran_duas.json',
    },
    {
      'title': 'أدعية السفر والركوب',
      'desc': 'أدعية ركوب الدابة والدخول والخروج في السفر',
      'icon': Icons.flight_takeoff_outlined,
      'jsonPath': 'assets/json/travel.json',
    },
    {
      'title': 'أدعية الشفاء والعافية',
      'desc': 'دعاء عيادة المريض وسؤال الله الصحة والعافية',
      'icon': Icons.health_and_safety_outlined,
      'jsonPath': 'assets/json/prophetic_duas.json',
    },
  ];

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

            // 3. Main Full-Height Scrollable Layout
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
                          bottom: 95,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'الأدعية',
                                      style: TextStyle(
                                        fontFamily: 'Fustat',
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'أدعية خاشعة ومستجابة من الكتاب والسنة',
                                      style: TextStyle(
                                        fontFamily: 'Fustat',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                                      ),
                                    ),
                                  ],
                                ),

                                // Search Button
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      AppPageRoute.create(const GlobalSearchPage()),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1.2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark ? const Color(0x20000000) : const Color(0x0A000000),
                                          blurRadius: 10,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      size: 20,
                                      color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Duas Categories List
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _duaCategories.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final item = _duaCategories[index];
                                return StaggeredListFadeItem(
                                  index: index,
                                  child: AnimatedCardTap(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        AppPageRoute.create(
                                          CategoryListPage(
                                            categoryTitle: item['title'] as String,
                                            jsonAssetPath: item['jsonPath'] as String,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0), width: 1.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark ? const Color(0x20000000) : const Color(0x0C000000),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1),
                                            ),
                                            child: Icon(
                                              item['icon'] as IconData,
                                              size: 24,
                                              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['title'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Fustat',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  item['desc'] as String,
                                                  style: TextStyle(
                                                    fontFamily: 'Fustat',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_left_rounded,
                                            size: 20,
                                            color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Floating Bottom Navigation Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: const FloatingBottomNavBar(selectedIndex: 1),
            ),
          ],
        ),
      ),
    );
  }
}
