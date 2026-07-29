import 'package:flutter/material.dart';
import '../../features/adhkar/presentation/pages/azkar_categories_page.dart';
import '../../features/adhkar/presentation/pages/duas_page.dart';
import '../../features/adhkar/presentation/pages/favorites_page.dart';
import '../../features/adhkar/presentation/pages/home_page.dart';
import '../../features/adhkar/presentation/pages/settings_page.dart';

/// Floating Bottom Navigation Bar supporting dynamic Light/Dark color themes.
class FloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const FloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final navItems = [
      {'label': 'المفضلة', 'icon': Icons.favorite_border_rounded},
      {'label': 'الأدعية', 'icon': Icons.back_hand_outlined},
      {'label': 'الرئيسية', 'icon': Icons.home_rounded},
      {'label': 'الأذكار', 'icon': Icons.grid_view_rounded},
      {'label': 'الإعدادات', 'icon': Icons.settings_outlined},
    ];

    final bgColor = isDark ? const Color(0xFF1F241D) : const Color(0xFFFFFDF9);
    final borderColor = isDark ? const Color(0xFF353E32) : const Color(0xFFEADFCF);
    final selectedPillColor = isDark ? const Color(0xFF2E362C) : const Color(0xFFF0E8DA);
    final selectedTextColor = isDark ? const Color(0xFFC9A15B) : const Color(0xFF4E5B4E);
    final unselectedTextColor = isDark ? const Color(0xFF7E8A63) : const Color(0xFF707973);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x14000000),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = index == selectedIndex;
          final item = navItems[index];

          if (isSelected) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selectedPillColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: selectedTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: selectedTextColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return InkWell(
            onTap: () {
              if (index == selectedIndex) return;

              Widget targetPage;
              switch (index) {
                case 0:
                  targetPage = const FavoritesPage();
                  break;
                case 1:
                  targetPage = const DuasPage();
                  break;
                case 2:
                  targetPage = const HomePage();
                  break;
                case 3:
                  targetPage = const AzkarCategoriesPage();
                  break;
                case 4:
                  targetPage = const SettingsPage();
                  break;
                default:
                  return;
              }
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, anim1, anim2) => targetPage,
                  transitionDuration: Duration.zero,
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: unselectedTextColor,
                    size: 20,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontFamily: 'Fustat',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: unselectedTextColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
