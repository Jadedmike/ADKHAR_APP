import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../managers/favorites_manager.dart';
import 'single_dhikr_page.dart';

/// The Favorites Screen for the "ذكر" application.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF161A15) : const Color(0xFFF8F4EC);
    final gradientColors = isDark
        ? const [Color(0xFF1D221C), Color(0xFF161A15), Color(0xFF111410)]
        : const [Color(0xFFFAF7F0), Color(0xFFF8F4EC), Color(0xFFEFE9DC)];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Stack(
          children: [
            // 1. Background Texture Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  gradient: RadialGradient(
                    center: const Alignment(-0.6, -0.6),
                    radius: 1.3,
                    colors: gradientColors,
                  ),
                ),
              ),
            ),

            // 2. Corner Background Ornaments
            Positioned.fill(
              child: Opacity(
                opacity: 0.32,
                child: Image.asset(
                  'assets/images/gold.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.42,
                child: Image.asset(
                  'assets/images/olivebranches.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // 3. Main Content Canvas
            SafeArea(
              bottom: false,
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: FavoritesManager.favoriteDhikrs,
                builder: (context, favorites, child) {
                  return LayoutBuilder(
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
                                // Screen Header
                                Text(
                                  'المفضلة',
                                  style: TextStyle(
                                    fontFamily: 'Fustat',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  favorites.isEmpty
                                      ? 'لا توجد أذكار مضافة'
                                      : 'قائمة الأذكار والأدعية المحفوظة (${favorites.length})',
                                  style: TextStyle(
                                    fontFamily: 'Fustat',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Empty State or Favorites List
                                if (favorites.isEmpty)
                                  _buildEmptyState(constraints.maxHeight)
                                else
                                  _buildFavoritesList(favorites),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // 4. Floating Rounded Bottom Navigation Bar
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: const FloatingBottomNavBar(selectedIndex: 0),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty State Illustration & Message
  Widget _buildEmptyState(double maxHeight) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: maxHeight - 220,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x0A000000),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Olive / Logo Illustration Badge
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1.5),
            ),
            child: Image.asset(
              'assets/images/logo2.png',
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 22),

          // Main Empty Message Text
          Text(
            'لا توجد أذكار في المفضلة حتى الآن',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 10),

          // Subtitle Guidance
          Text(
            'يمكنك إضافة الأذكار إلى المفضلة بالضغط على رمز القلب عند قراءة الأذكار للوصول إليها بسهولة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// List of Favorite Dhikr Cards
  Widget _buildFavoritesList(List<Map<String, dynamic>> favorites) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: favorites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final dhikr = favorites[index];
        final String categoryName = (dhikr['categoryTitle'] ?? dhikr['category'] ?? 'أذكار عامة') as String;
        final String text = dhikr['text'] as String? ?? '';
        final int count = (dhikr['count'] ?? dhikr['requiredCount'] ?? 1) as int;

        return InkWell(
          onTap: () {
            // Open SingleDhikrPage for the selected favorite item
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SingleDhikrPage(
                  categoryTitle: categoryName,
                  dhikrList: favorites,
                  initialIndex: index,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(22),
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
            child: Stack(
              children: [
                // Corner Watermark Olive Branch Graphic
                Positioned(
                  right: 0,
                  top: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(22)),
                    child: Opacity(
                      opacity: 0.14,
                      child: Image.asset(
                        'assets/images/olivebranches.png',
                        width: 75,
                        height: 75,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Category Tag & Favorite Remove Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category Pill Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1),
                          ),
                          child: Text(
                            categoryName,
                            style: TextStyle(
                              fontFamily: 'Fustat',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                            ),
                          ),
                        ),

                        // Favorite Heart Button (Removes from favorites)
                        InkWell(
                          onTap: () {
                            FavoritesManager.removeFavorite(context, dhikr);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Icon(
                            Icons.favorite_rounded,
                            size: 22,
                            color: isDark ? const Color(0xFFC9A15B) : const Color(0xFFC5A059),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // First 1 or 2 lines of Dhikr text
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F),
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bottom Row: Repetition Count & Navigation Arrow
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF0E8DA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.repeat_rounded,
                                size: 14,
                                color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'التكرار: $count ${count == 1 ? 'مرة واحدة' : 'مرات'}',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
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
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
