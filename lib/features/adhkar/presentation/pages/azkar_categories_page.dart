import 'package:flutter/material.dart';
import '../../../../config/theme/app_assets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_page_transitions.dart';
import '../../../../shared/widgets/animated_card_tap.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../../shared/widgets/staggered_list_fade_item.dart';
import 'category_list_page.dart';
import 'global_search_page.dart';

/// The Azkar Categories Screen of the Adhkar ("ذكر") application.
class AzkarCategoriesPage extends StatefulWidget {
  const AzkarCategoriesPage({super.key});

  @override
  State<AzkarCategoriesPage> createState() => _AzkarCategoriesPageState();
}

class _AzkarCategoriesPageState extends State<AzkarCategoriesPage> {
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
                          top: 16,
                          bottom: 105, // Space for floating bottom navbar
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header App Bar (Title & Subtitle)
                            _buildHeader(),

                            const SizedBox(height: 20),

                            // List of 10 Category Cards
                            _buildCategoriesList(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Floating Rounded Bottom Navigation Bar (Selected: الأذكار)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
              child: const FloatingBottomNavBar(selectedIndex: 3),
            ),
          ],
        ),
      ),
    );
  }

  /// Header App Bar (Title & Subtitle + Search Icon)
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Button (Physical Right)
        InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const GlobalSearchPage()),
            );
          },
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
              Icons.search_rounded,
              size: 20,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E),
            ),
          ),
        ),

        // Title & Subtitle Column (Physical Left)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأذكار',
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
              'اختر القسم الذي ترغب بقراءته',
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFD8CEBE)
                    : const Color(0xFF707973),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Category List (10 Large Rounded Cards)
  Widget _buildCategoriesList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'أذكار الصباح',
        'desc': 'أذكار وأدعية يبدأ بها المسلم يومه',
        'icon': Icons.wb_sunny_outlined,
        'jsonPath': AppAssets.jsonAdhkarMorning,
      },
      {
        'title': 'أذكار المساء',
        'desc': 'حصن المسلم وتحصينه في المساء',
        'icon': Icons.nights_stay_outlined,
        'jsonPath': AppAssets.jsonAdhkarEvening,
      },
      {
        'title': 'أذكار بعد الصلاة',
        'desc': 'الأدعية والأذكار الواردة عقب الصلاة',
        'icon': Icons.mosque_outlined,
        'jsonPath': AppAssets.jsonAfterPrayer,
      },
      {
        'title': 'أذكار النوم',
        'desc': 'أذكار الطهارة والاستلقاء للنوم',
        'icon': Icons.bedtime_outlined,
        'jsonPath': AppAssets.jsonSleep,
      },
      {
        'title': 'أذكار المنزل',
        'desc': 'أذكار الدخول والخروج من المنزل',
        'icon': Icons.other_houses_outlined,
        'jsonPath': AppAssets.jsonHome,
      },
      {
        'title': 'أذكار السفر',
        'desc': 'دعاء ركوب الدابة وأدعية السفر',
        'icon': Icons.flight_takeoff_outlined,
        'jsonPath': AppAssets.jsonTravel,
      },
      {
        'title': 'أذكار الطعام',
        'desc': 'أذكار ما قبل وبعد الطعام والشراب',
        'icon': Icons.restaurant_outlined,
        'jsonPath': AppAssets.jsonFood,
      },
      {
        'title': 'أذكار اللباس',
        'desc': 'دعاء لبس الثوب الجديد وخلعه',
        'icon': Icons.checkroom_outlined,
        'jsonPath': AppAssets.jsonClothing,
      },
      {
        'title': 'أذكار المسجد',
        'desc': 'أدعية الذهاب إلى المسجد والدخول والخروج',
        'icon': Icons.synagogue_outlined,
        'jsonPath': AppAssets.jsonMosque,
      },
      {
        'title': 'جميع الأذكار',
        'desc': 'تصفح كافة أذكار وأدعية الكتاب والسنة',
        'icon': Icons.menu_book_outlined,
        'jsonPath': AppAssets.jsonMorning,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final category = categories[index];
        return StaggeredListFadeItem(
          index: index,
          child: AnimatedCardTap(
            onTap: () {
              Navigator.of(context).push(
                AppPageRoute.create(
                  CategoryListPage(
                    categoryTitle: category['title'] as String,
                    jsonAssetPath: category['jsonPath'] as String,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262D24)
                    : const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF353E32)
                      : const Color(0xFFF3ECE0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? const Color(0x20000000)
                        : const Color(0x0C000000),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Corner Watermark Olive Leaf Graphic
                  Positioned(
                    right: 0,
                    top: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(22),
                      ),
                      child: Opacity(
                        opacity: 0.14,
                        child: Image.asset(
                          AppAssets.oliveBranches,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      // Circular Icon Container
                      Container(
                        width: 48,
                        height: 48,
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
                          category['icon'] as IconData,
                          size: 24,
                          color: isDark
                              ? const Color(0xFFC9A15B)
                              : const Color(0xFF4E5B4E),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Title & Description Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFF6F1E7)
                                    : const Color(0xFF1E281F),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              category['desc'] as String,
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFFD8CEBE)
                                    : const Color(0xFF707973),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Navigation Chevron Arrow (RTL left pointing)
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1F241D)
                              : const Color(0xFFF7F2E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: isDark
                              ? const Color(0xFFD8CEBE)
                              : const Color(0xFF4E5B4E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
