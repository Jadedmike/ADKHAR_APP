import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../config/theme/app_assets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/dhikr_copy_helper.dart';
import '../../../../core/utils/dhikr_share_helper.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/floating_bottom_nav_bar.dart';
import '../managers/favorites_manager.dart';
import '../managers/settings_manager.dart';
import 'azkar_categories_page.dart';

/// The Single Dhikr Screen for the "ذكر" application.
class SingleDhikrPage extends StatefulWidget {
  final String categoryTitle;
  final List<Map<String, dynamic>>? dhikrList;
  final int initialIndex;
  final double initialScrollOffset;
  final String? jsonAssetPath;

  const SingleDhikrPage({
    super.key,
    this.categoryTitle = 'أذكار الصباح',
    this.dhikrList,
    this.initialIndex = 0,
    this.initialScrollOffset = 0.0,
    this.jsonAssetPath,
  });

  @override
  State<SingleDhikrPage> createState() => _SingleDhikrPageState();
}

class _SingleDhikrPageState extends State<SingleDhikrPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  int _counter = 0;
  bool _isCompleted = false;
  bool _isSectionCompleted = false;
  late final ScrollController _scrollController;

  // Default fallback Dhikr dataset if none passed
  final List<Map<String, dynamic>> _defaultDhikrList = [
    {
      'text':
          'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ لاَ إِلَهَ إِلاَّ اللَّهُ، وَحْدَهُ لاَ شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ.',
      'count': 1,
      'source': 'صحيح مسلم',
    },
    {
      'text':
          'اللَّهُمَّ بِكَ أَصْبَحْنَا، وَبِكَ أَمْسَيْنَا، وَبِكَ نَحْيَا، وَبِكَ نَمُوتُ، وَإِلَيْكَ النُّشُورُ.',
      'count': 1,
      'source': 'سنن الترمذي',
    },
    {
      'text':
          'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ: عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ.',
      'count': 3,
      'source': 'صحيح مسلم - حصن المسلم',
    },
    {
      'text':
          'اللَّهُمَّ عَاِفِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، اللَّهُمَّ عَافِنِي فِي بَصَرِي، لاَ إِلَهَ إِلاَّ أَنْتَ.',
      'count': 3,
      'source': 'سنن أبي داود',
    },
    {
      'text':
          'حَسْبِيَ اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ عَلَيْهِ تَوَكَّلْتُ وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ.',
      'count': 7,
      'source': 'ابن السني - حصن المسلم',
    },
  ];

  List<Map<String, dynamic>> get _activeList {
    if (widget.dhikrList != null && widget.dhikrList!.isNotEmpty) {
      return widget.dhikrList!;
    }
    return _defaultDhikrList;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentIndex = widget.initialIndex;
    if (_currentIndex >= _activeList.length) {
      _currentIndex = 0;
    }
    _applyWakelock(SettingsManager.keepScreenOn.value);
    SettingsManager.keepScreenOn.addListener(_onKeepScreenOnChanged);

    if (widget.initialScrollOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(widget.initialScrollOffset);
        }
      });
    }

    _scrollController.addListener(_saveCurrentPosition);
    _saveCurrentPosition();
  }

  void _saveCurrentPosition() {
    SettingsManager.saveLastReadingPosition(
      categoryTitle: widget.categoryTitle,
      jsonAssetPath: widget.jsonAssetPath,
      index: _currentIndex,
      scrollOffset: _scrollController.hasClients
          ? _scrollController.offset
          : widget.initialScrollOffset,
    );
  }

  void _onKeepScreenOnChanged() {
    _applyWakelock(SettingsManager.keepScreenOn.value);
  }

  Future<void> _applyWakelock(bool keepOn) async {
    try {
      if (keepOn) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveCurrentPosition();
    _scrollController.removeListener(_saveCurrentPosition);
    _scrollController.dispose();
    SettingsManager.keepScreenOn.removeListener(_onKeepScreenOnChanged);
    _applyWakelock(false);
    super.dispose();
  }

  bool _isCounterPulsing = false;

  void _incrementCounter() {
    if (SettingsManager.vibrationOption.value) {
      HapticFeedback.lightImpact();
    }
    final currentDhikr = _activeList[_currentIndex];
    final int target =
        (currentDhikr['count'] ?? currentDhikr['requiredCount'] ?? 1) as int;

    setState(() {
      _counter++;
      _isCounterPulsing = true;
      if (_counter >= target) {
        _isCompleted = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _isCounterPulsing = false;
        });
      }
    });
  }

  void _decrementCounter() {
    setState(() {
      if (_counter > 0) {
        _counter--;
        _isCompleted = false;
      }
    });
  }

  void _nextDhikr() {
    setState(() {
      if (_currentIndex < _activeList.length - 1) {
        _currentIndex++;
        _counter = 0;
        _isCompleted = false;
      } else {
        // Reached the end of the section
        _isSectionCompleted = true;
      }
    });
  }

  void _previousDhikr() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _counter = 0;
        _isCompleted = false;
        _isSectionCompleted = false;
      }
    });
  }

  void _restartSection() {
    setState(() {
      _currentIndex = 0;
      _counter = 0;
      _isCompleted = false;
      _isSectionCompleted = false;
    });
  }

  void _copyToClipboard(BuildContext context, Map<String, dynamic> dhikr) {
    DhikrCopyHelper.copyToClipboard(context, dhikr);
  }

  void _showFontSizeBottomSheet(BuildContext context) {
    final List<Map<String, String>> options = [
      {'label': 'صغير', 'desc': 'حجم خط مناسب للشاشات الصغيرة'},
      {'label': 'متوسط', 'desc': 'الحجم الافتراضي والقراءة المريحة'},
      {'label': 'كبير', 'desc': 'حجم خط واضح وسهل القراءة'},
      {'label': 'كبير جداً', 'desc': 'أكبر حجم خط لتسهيل القراءة للجميع'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        final isDark = Theme.of(modalContext).brightness == Brightness.dark;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 12,
              bottom: 28,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF353E32)
                      : const Color(0xFFEADFCF),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Indicator Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3E483B)
                        : const Color(0xFFD6C8B4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const SizedBox(height: 16),

                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_size_rounded,
                          color: isDark
                              ? const Color(0xFFC9A15B)
                              : const Color(0xFF4E5B4E),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'حجم خط القراءة',
                          style: TextStyle(
                            fontFamily: 'Fustat',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFF6F1E7)
                                : const Color(0xFF4E5B4E),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(modalContext),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? const Color(0xFFD8CEBE)
                              : const Color(0xFF707973),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Options List
                ValueListenableBuilder<String>(
                  valueListenable: SettingsManager.fontSizeOption,
                  builder: (context, currentOption, child) {
                    return Column(
                      children: options.map((opt) {
                        final String label = opt['label']!;
                        final String desc = opt['desc']!;
                        final bool isSelected = currentOption == label;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              SettingsManager.setFontSizeOption(label);
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (isDark
                                          ? const Color(0xFF2E362C)
                                          : const Color(0xFFF0E8DA))
                                    : (isDark
                                          ? const Color(0xFF1F241D)
                                          : const Color(0xFFF7F2E8)),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? (isDark
                                            ? const Color(0xFFC9A15B)
                                            : const Color(0xFFC5A059))
                                      : (isDark
                                            ? const Color(0xFF353E32)
                                            : const Color(0xFFEADFCF)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: 'Fustat',
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? (isDark
                                                    ? const Color(0xFFC9A15B)
                                                    : const Color(0xFF4E5B4E))
                                              : (isDark
                                                    ? const Color(0xFFF6F1E7)
                                                    : const Color(0xFF1E281F)),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontFamily: 'Fustat',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? const Color(0xFFD8CEBE)
                                              : const Color(0xFF707973),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: isDark
                                          ? const Color(0xFFC9A15B)
                                          : const Color(0xFFC5A059),
                                      size: 22,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDhikr = _activeList[_currentIndex];
    final totalCount = _activeList.length;
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

            // 3. Main Full-Screen Layout Canvas
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 18,
                          right: 18,
                          top: 10,
                          bottom: 95, // Space for bottom navbar
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // TOP BAR: Left Back Button, Center Position Badge ("1 من 45"), Right Bookmark & Share
                            _buildTopBar(context, totalCount),

                            const SizedBox(height: 12),

                            // MAIN CONTENT CARD (Expands vertically to occupy available height naturally)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 160,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeIn,
                                switchOutCurve: Curves.easeOut,
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                key: ValueKey<String>(
                                  _isSectionCompleted
                                      ? 'completed'
                                      : 'dhikr_$_currentIndex',
                                ),
                                child: _isSectionCompleted
                                    ? _buildCompletionCard(context)
                                    : _buildMainDhikrCard(currentDhikr),
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
              child: const FloatingBottomNavBar(selectedIndex: 3),
            ),
          ],
        ),
      ),
    );
  }

  /// TOP BAR
  Widget _buildTopBar(BuildContext context, int totalCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back Button (RTL back arrow)
        InkWell(
          onTap: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AzkarCategoriesPage(),
                ),
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

        // Center: Position Badge ("1 من 45")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F241D) : const Color(0xFFF0E8DA),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF),
              width: 1.2,
            ),
          ),
          child: Text(
            _isSectionCompleted
                ? 'مكتمل'
                : '${_currentIndex + 1} من $totalCount',
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : const Color(0xFF4E5B4E),
            ),
          ),
        ),

        // Right: Bookmark & Share Buttons
        Row(
          children: [
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: FavoritesManager.favoriteDhikrs,
              builder: (context, favorites, child) {
                final currentDhikr = _activeList[_currentIndex];
                final isFav = FavoritesManager.isFavorite(currentDhikr);
                return InkWell(
                  onTap: () {
                    FavoritesManager.toggleFavorite(context, {
                      ...currentDhikr,
                      'categoryTitle': widget.categoryTitle,
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF262D24)
                          : const Color(0xFFFFFDF9),
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
                      isFav
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: isFav
                          ? const Color(0xFFC9A15B)
                          : (isDark
                                ? const Color(0xFFD8CEBE)
                                : const Color(0xFF4E5B4E)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () =>
                  _copyToClipboard(context, _activeList[_currentIndex]),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262D24)
                      : const Color(0xFFFFFDF9),
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
                  Icons.copy_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFD8CEBE)
                      : const Color(0xFF4E5B4E),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () =>
                  DhikrShareHelper.shareDhikr(_activeList[_currentIndex]),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262D24)
                      : const Color(0xFFFFFDF9),
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
                  Icons.share_outlined,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFD8CEBE)
                      : const Color(0xFF4E5B4E),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _showFontSizeBottomSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262D24)
                      : const Color(0xFFFFFDF9),
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
                  Icons.format_size_rounded,
                  size: 20,
                  color: isDark
                      ? const Color(0xFFD8CEBE)
                      : const Color(0xFF4E5B4E),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// MAIN DHIKR CARD - Full Height & Balanced Layout
  Widget _buildMainDhikrCard(Map<String, dynamic> currentDhikr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x0F000000),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Corner Olive Branch Watermark
          Positioned(
            right: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(26),
              ),
              child: Opacity(
                opacity: 0.16,
                child: Image.asset(
                  AppAssets.oliveBranches,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Dhikr Text Section (Centered vertically in top/upper area)
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: AnimatedOpacity(
                    opacity: _isCompleted ? 0.75 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: ValueListenableBuilder<String>(
                      valueListenable: SettingsManager.fontSizeOption,
                      builder: (context, fontSizeOpt, child) {
                        return Text(
                          (currentDhikr['text'] ??
                                  currentDhikr['content'] ??
                                  currentDhikr['dhikr'] ??
                                  '')
                              as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fustat',
                            fontSize: SettingsManager.dhikrFontSize,
                            fontWeight: FontWeight.bold,
                            color: _isCompleted
                                ? (isDark
                                      ? const Color(0xFF7E8A63)
                                      : const Color(0xFF4E5B4E))
                                : (isDark
                                      ? const Color(0xFFF6F1E7)
                                      : const Color(0xFF1E281F)),
                            height: 1.85,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Lower Section Group (Golden Divider, Counter, Next Button, Source Chip)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 2. Golden Center Rosette Divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 85,
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
                            size: 15,
                            color: isDark
                                ? const Color(0xFFC9A15B)
                                : const Color(0xFFC5A059),
                          ),
                        ),
                        Container(
                          width: 85,
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

                    if (currentDhikr.containsKey('count') ||
                        currentDhikr.containsKey('requiredCount')) ...[
                      const SizedBox(height: 22),

                      // 3. Counter Section (-) 0 (+)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Minus Button (-)
                          InkWell(
                            onTap: _decrementCounter,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F241D)
                                    : const Color(0xFFF7F2E8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFEADFCF),
                                  width: 1.2,
                                ),
                              ),
                              child: Icon(
                                Icons.remove_rounded,
                                size: 22,
                                color: isDark
                                    ? const Color(0xFFD8CEBE)
                                    : const Color(0xFF4E5B4E),
                              ),
                            ),
                          ),

                          const SizedBox(width: 32),

                          AnimatedScale(
                            scale: _isCounterPulsing ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontFamily: 'Fustat',
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: _isCompleted
                                    ? (isDark
                                          ? const Color(0xFFC9A15B)
                                          : const Color(0xFFC5A059))
                                    : (isDark
                                          ? const Color(0xFFF6F1E7)
                                          : AppColors.primaryLight),
                              ),
                              child: Text('$_counter'),
                            ),
                          ),

                          const SizedBox(width: 32),

                          // Plus Button (+)
                          InkWell(
                            onTap: _incrementCounter,
                            borderRadius: BorderRadius.circular(22),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2E362C)
                                    : const Color(0xFF4E5B4E),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x224E5B4E),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                size: 24,
                                color: isDark
                                    ? const Color(0xFFC9A15B)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 4. Navigation Buttons (السابق / التالي)
                    Row(
                      children: [
                        if (_currentIndex > 0) ...[
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 52,
                              child: OutlinedButton(
                                onPressed: _previousDhikr,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark
                                        ? const Color(0xFF353E32)
                                        : const Color(0xFFEADFCF),
                                    width: 1.4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                ),
                                child: Text(
                                  'السابق',
                                  style: TextStyle(
                                    fontFamily: 'Fustat',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? const Color(0xFFD8CEBE)
                                        : const Color(0xFF4E5B4E),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _nextDhikr,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? const Color(0xFF2E362C)
                                    : const Color(0xFF4E5B4E),
                                foregroundColor: isDark
                                    ? const Color(0xFFC9A15B)
                                    : Colors.white,
                                elevation: 4,
                                shadowColor: const Color(0x334E5B4E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                              ),
                              child: Text(
                                'التالي',
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xFFC9A15B)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 5. Source Chip
                    ValueListenableBuilder<bool>(
                      valueListenable: SettingsManager.showSource,
                      builder: (context, showSource, child) {
                        if (!showSource) return const SizedBox.shrink();
                        final String sourceText =
                            (currentDhikr['source'] ??
                                    currentDhikr['reference'])
                                as String? ??
                            'حصن المسلم';
                        if (sourceText.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1F241D)
                                    : const Color(0xFFF7F2E8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF353E32)
                                      : const Color(0xFFEADFCF),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                sourceText,
                                style: TextStyle(
                                  fontFamily: 'Fustat',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFFD8CEBE)
                                      : const Color(0xFF707973),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// COMPLETION CARD - Full Height & Centered Message
  Widget _buildCompletionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262D24) : const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark ? const Color(0xFF353E32) : const Color(0xFFF3ECE0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x20000000) : const Color(0x0F000000),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
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
              Icons.check_circle_outline_rounded,
              color: isDark ? const Color(0xFFC9A15B) : const Color(0xFFC5A059),
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'تقبل الله منك، لقد أتممت هذا القسم.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF6F1E7) : AppColors.primaryLight,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'نسأل الله أن يجعلها في ميزان حسناتك وطمأنينة لقلبك.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fustat',
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFD8CEBE) : const Color(0xFF707973),
            ),
          ),

          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _restartSection,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF353E32)
                            : const Color(0xFF4E5B4E),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: Text(
                      'إعادة القراءة',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFD8CEBE)
                            : const Color(0xFF4E5B4E),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const AzkarCategoriesPage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4E5B4E),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'العودة للأذكار',
                      style: TextStyle(
                        fontFamily: 'Fustat',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
