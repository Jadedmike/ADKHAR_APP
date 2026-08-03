import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_page_transitions.dart';
import '../../../../core/utils/arabic_search_helper.dart';
import '../../../../shared/widgets/animated_card_tap.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/staggered_list_fade_item.dart';
import '../managers/favorites_manager.dart';
import 'single_dhikr_page.dart';

/// Representation of an indexed Dhikr or Dua item for global searching.
class SearchableDhikrItem {
  final Map<String, dynamic> rawData;
  final String categoryTitle;
  final String jsonAssetPath;
  final List<Map<String, dynamic>> fullCategoryList;
  final int indexInCategory;
  final String title;
  final String text;
  final String source;
  final int count;

  SearchableDhikrItem({
    required this.rawData,
    required this.categoryTitle,
    required this.jsonAssetPath,
    required this.fullCategoryList,
    required this.indexInCategory,
    required this.title,
    required this.text,
    required this.source,
    required this.count,
  });
}

/// Global Search Page for the "ذكر" application.
/// Performs instant diacritic-insensitive search across all Dhikr and Dua JSON files.
class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<SearchableDhikrItem> _allIndexedItems = [];
  List<SearchableDhikrItem> _searchResults = [];
  bool _isLoading = true;
  String _currentQuery = '';

  final List<Map<String, String>> _jsonSources = [
    {'path': 'assets/json/morning.json', 'alt': 'assets/json/adhkar_morning.json', 'title': 'أذكار الصباح'},
    {'path': 'assets/json/evening.json', 'alt': 'assets/json/adhkar_evening.json', 'title': 'أذكار المساء'},
    {'path': 'assets/json/after_prayer.json', 'alt': '', 'title': 'أذكار بعد الصلاة'},
    {'path': 'assets/json/sleep.json', 'alt': '', 'title': 'أذكار النوم'},
    {'path': 'assets/json/travel.json', 'alt': '', 'title': 'أذكار السفر'},
    {'path': 'assets/json/quran_duas.json', 'alt': '', 'title': 'أدعية من القرآن الكريم'},
    {'path': 'assets/json/prophetic_duas.json', 'alt': '', 'title': 'أدعية من السنة النبوية'},
    {'path': 'assets/json/forgiveness_duas.json', 'alt': '', 'title': 'أدعية الاستغفار والتوبة'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllJsonData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadAllJsonData() async {
    final List<SearchableDhikrItem> indexed = [];

    for (final source in _jsonSources) {
      final String path = source['path']!;
      final String altPath = source['alt']!;
      final String categoryTitle = source['title']!;

      String? jsonString;
      try {
        jsonString = await rootBundle.loadString(path);
      } catch (_) {
        if (altPath.isNotEmpty) {
          try {
            jsonString = await rootBundle.loadString(altPath);
          } catch (_) {}
        }
      }

      if (jsonString == null || jsonString.isEmpty) continue;

      try {
        final List<dynamic> parsed = json.decode(jsonString);
        final List<Map<String, dynamic>> categoryList =
            parsed.map((e) => Map<String, dynamic>.from(e)).toList();

        for (int i = 0; i < categoryList.length; i++) {
          final item = categoryList[i];
          final String text = (item['text'] ?? item['content'] ?? item['dhikr'] ?? '').toString();
          final String title = (item['title'] ?? '').toString();
          final String itemSource = (item['source'] ?? '').toString();
          final int count = (item['count'] is int)
              ? item['count'] as int
              : (int.tryParse(item['count']?.toString() ?? '') ?? 1);

          indexed.add(
            SearchableDhikrItem(
              rawData: item,
              categoryTitle: categoryTitle,
              jsonAssetPath: path,
              fullCategoryList: categoryList,
              indexInCategory: i,
              title: title,
              text: text,
              source: itemSource,
              count: count,
            ),
          );
        }
      } catch (_) {
        // Continue loading other files if one fails
      }
    }

    if (mounted) {
      setState(() {
        _allIndexedItems = indexed;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _currentQuery = query;
      if (query.trim().isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = _allIndexedItems.where((item) {
          return ArabicSearchHelper.matches(item.text, query) ||
              ArabicSearchHelper.matches(item.title, query) ||
              ArabicSearchHelper.matches(item.categoryTitle, query) ||
              ArabicSearchHelper.matches(item.source, query);
        }).toList();
      }
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

            // 3. Main Content Area
            SafeArea(
              child: Column(
                children: [
                  // Top Search Header Bar
                  _buildSearchHeader(context),

                  const SizedBox(height: 12),

                  // Results Content List / Loader / Empty State
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                            ),
                          )
                        : _buildMainContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header with Back Button and Search Bar Input Field
  Widget _buildSearchHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 18, right: 18, top: 12),
      child: Row(
        children: [
          // Back Button
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 44,
              height: 44,
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

          const SizedBox(width: 12),

          // Instant Search Input Field
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? (isDark ? const Color(0xFFC9A15B) : const Color(0xFFC5A059))
                      : (isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF)),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0x20000000) : const Color(0x0C000000),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F),
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث في الأذكار والأدعية...',
                        hintStyle: TextStyle(
                          fontFamily: 'Fustat',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF9EA69F),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  // Clear Search Button
                  if (_currentQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders either Initial Prompt, Empty State, or Results List
  Widget _buildMainContent() {
    final cleanQuery = _currentQuery.trim();

    // 1. Initial State before user types
    if (cleanQuery.isEmpty) {
      return _buildInitialPromptState();
    }

    // 2. No Results State
    if (_searchResults.isEmpty) {
      return _buildEmptyResultsState();
    }

    // 3. Search Results List
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
          child: Text(
            'نتائج البحث (${_searchResults.length})',
            style: const TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF707973),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 18, right: 18, bottom: 24, top: 4),
            physics: const BouncingScrollPhysics(),
            itemCount: _searchResults.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return StaggeredListFadeItem(
                index: index,
                child: _buildSearchResultCard(_searchResults[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Initial state prompt encouraging user to search
  Widget _buildInitialPromptState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? const Color(0x20000000) : const Color(0x0A000000),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo2.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ابحث في جميع الأذكار والأدعية',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 17.5,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اكتب كلمة أو نصاً للبحث في أذكار الصباح والمساء وأدعية القرآن والسنة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Fustat',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Premium Empty State: "لم يتم العثور على نتائج"
  Widget _buildEmptyResultsState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
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
              // Logo Badge
              Container(
                width: 86,
                height: 86,
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

              // Exact required text
              Text(
                'لم يتم العثور على نتائج',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'جرب البحث بكلمات أخرى أو التأكد من كتابة الكلمات بشكل صحيح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fustat',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dhikr Card matching the exact card design of CategoryListPage
  Widget _buildSearchResultCard(SearchableDhikrItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final TextStyle defaultTextTextStyle = TextStyle(
      fontFamily: 'Fustat',
      fontSize: 15.5,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF1E281F),
      height: 1.6,
    );

    final TextStyle highlightTextTextStyle = TextStyle(
      fontFamily: 'Fustat',
      fontSize: 15.5,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF7A5816),
      backgroundColor: isDark ? const Color(0xFF524222) : const Color(0xFFF0E3C4),
      height: 1.6,
    );

    final TextStyle defaultTitleTextStyle = TextStyle(
      fontFamily: 'Fustat',
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
    );

    final TextStyle highlightTitleTextStyle = TextStyle(
      fontFamily: 'Fustat',
      fontSize: 15,
      fontWeight: FontWeight.bold,
      color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF7A5816),
      backgroundColor: isDark ? const Color(0xFF524222) : const Color(0xFFF0E3C4),
    );

    return AnimatedCardTap(
      onTap: () {
        // Opens the Reading Screen (SingleDhikrPage)
        Navigator.of(context).push(
          AppPageRoute.create(
            SingleDhikrPage(
              categoryTitle: item.categoryTitle,
              dhikrList: item.fullCategoryList,
              initialIndex: item.indexInCategory,
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
                // Top Row: Category Badge & Favorite Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF7F2E8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF), width: 1),
                      ),
                      child: Text(
                        '${item.categoryTitle} • #${item.indexInCategory + 1}',
                        style: TextStyle(
                          fontFamily: 'Fustat',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E),
                        ),
                      ),
                    ),

                    // Favorite Button
                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: FavoritesManager.favoriteDhikrs,
                      builder: (context, favorites, child) {
                        final bool isFav = FavoritesManager.isFavoriteText(item.text);
                        return InkWell(
                          onTap: () {
                            FavoritesManager.toggleFavorite(context, {
                              ...item.rawData,
                              'categoryTitle': item.categoryTitle,
                              'text': item.text,
                              'count': item.count,
                              'source': item.source,
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

                // Item Title (if available)
                if (item.title.isNotEmpty) ...[
                  RichText(
                    text: TextSpan(
                      children: ArabicSearchHelper.buildHighlightSpans(
                        text: item.title,
                        query: _currentQuery,
                        defaultStyle: defaultTitleTextStyle,
                        highlightStyle: highlightTitleTextStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Dhikr / Dua Text with Search Highlighting
                RichText(
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: ArabicSearchHelper.buildHighlightSpans(
                      text: item.text,
                      query: _currentQuery,
                      defaultStyle: defaultTextTextStyle,
                      highlightStyle: highlightTextTextStyle,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bottom Row: Count Pill & Chevron
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
                            'التكرار: ${item.count} ${item.count == 1 ? 'مرة واحدة' : 'مرات'}',
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
  }
}
