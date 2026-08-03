import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_page_transitions.dart';
import '../../../../shared/widgets/animated_card_tap.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../../../../shared/widgets/staggered_list_fade_item.dart';
import '../managers/favorites_manager.dart';
import 'azkar_categories_page.dart';
import 'single_dhikr_page.dart';

/// The Category List Screen for the "ذكر" application.
/// Displays ALL Dhikrs belonging to the selected category loaded dynamically from JSON.
/// Flow: Home -> Azkar Categories -> Category List -> Single Dhikr.
class CategoryListPage extends StatefulWidget {
  final String categoryTitle;
  final String jsonAssetPath;

  const CategoryListPage({
    super.key,
    required this.categoryTitle,
    required this.jsonAssetPath,
  });

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  List<Map<String, dynamic>> _dhikrItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDhikrJson();
  }

  Future<void> _loadDhikrJson() async {
    final String requestedPath = widget.jsonAssetPath;
    final List<String> candidatePaths = [
      requestedPath,
      if (requestedPath.contains('morning')) 'assets/json/adhkar_morning.json',
      if (requestedPath.contains('morning')) 'assets/json/morning.json',
      if (requestedPath.contains('evening')) 'assets/json/adhkar_evening.json',
      if (requestedPath.contains('evening')) 'assets/json/evening.json',
    ];

    for (final path in candidatePaths) {
      try {
        final String jsonString = await rootBundle.loadString(path);
        final List<dynamic> parsedJson = json.decode(jsonString);
        if (parsedJson.isNotEmpty) {
          setState(() {
            _dhikrItems = parsedJson.map((e) => Map<String, dynamic>.from(e)).toList();
            _isLoading = false;
          });
          return;
        }
      } catch (_) {
        // Try next candidate path
      }
    }

    // Fallback default list if specific JSON is unavailable
    setState(() {
      _dhikrItems = [
        {
          "id": 1,
          "text":
              "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.",
          "count": 1,
          "source": "صحيح مسلم"
        },
        {
          "id": 2,
          "text":
              "اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.",
          "count": 1,
          "source": "سنن الترمذي"
        },
        {
          "id": 3,
          "text":
              "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.",
          "count": 3,
          "source": "صحيح مسلم"
        },
      ];
      _isLoading = false;
    });
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

            // 3. Main Content Scrollable List
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
                          bottom: 105, // Space for bottom navbar
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header (Back button, Category Title, Count Badge)
                            _buildHeader(context),

                            const SizedBox(height: 20),

                            // Dhikr List
                            if (_isLoading)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 60),
                                  child: CircularProgressIndicator(
                                    color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                                  ),
                                ),
                              )
                            else
                              _buildDhikrList(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // 4. Floating Rounded Bottom Navigation Bar
            const Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: FloatingBottomNavBar(selectedIndex: 3),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with Back button, Category title & subtitle
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        // Back Button
        InkWell(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AzkarCategoriesPage()),
              );
            }
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
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF4E5B4E),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Title & Count Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.categoryTitle,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'قائمة الأذكار (${_dhikrItems.length})',
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build list of Dhikr Cards in exact order from JSON
  Widget _buildDhikrList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dhikrItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = _dhikrItems[index];
        final String text = (item['text'] ?? item['content'] ?? item['dhikr'] ?? item['title'] ?? '') as String;
        final int count = (item['count'] is int)
            ? item['count'] as int
            : (int.tryParse(item['count']?.toString() ?? '') ?? 1);

        return StaggeredListFadeItem(
          index: index,
          child: AnimatedCardTap(
            onTap: () {
              Navigator.of(context).push(
                AppPageRoute.create(
                  SingleDhikrPage(
                    categoryTitle: widget.categoryTitle,
                    dhikrList: _dhikrItems,
                    initialIndex: index,
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
            child: Stack(
              children: [
                // Corner Watermark Olive Leaf Graphic
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
                    // Top Row: Dhikr Number badge & Favorite button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dhikr Number Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1),
                          ),
                          child: Text(
                            'ذِكْر #${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Fustat',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                            ),
                          ),
                        ),

                        // Favorite Button
                        ValueListenableBuilder<List<Map<String, dynamic>>>(
                          valueListenable: FavoritesManager.favoriteDhikrs,
                          builder: (context, favorites, child) {
                            final bool isFav = FavoritesManager.isFavorite(item);
                            return InkWell(
                              onTap: () {
                                FavoritesManager.toggleFavorite(context, {
                                  ...item,
                                  'categoryTitle': widget.categoryTitle,
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: isFav
                                      ? const Color(0xFFC9A15B)
                                      : (isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973)),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // First one or two lines of Dhikr text
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

                    // Bottom Row: Repetition Count Pill
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
        ),
      );
      },
    );
  }
}
