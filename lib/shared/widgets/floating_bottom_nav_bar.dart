import 'package:flutter/material.dart';
import '../../config/theme/app_page_transitions.dart';
import '../../features/adhkar/presentation/pages/azkar_categories_page.dart';
import '../../features/adhkar/presentation/pages/duas_page.dart';
import '../../features/adhkar/presentation/pages/favorites_page.dart';
import '../../features/adhkar/presentation/pages/home_page.dart';
import '../../features/adhkar/presentation/pages/settings_page.dart';

import 'magnetic_dock_nav_bar.dart';

/// Floating Bottom Navigation Bar supporting dynamic Light/Dark color themes
/// powered by [MagneticDockNavBar].
class FloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const FloatingBottomNavBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    const navItems = [
      AthkarNavItem(
        label: 'المفضلة',
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
      ),
      AthkarNavItem(
        label: 'الأدعية',
        icon: Icons.back_hand_outlined,
        activeIcon: Icons.back_hand_rounded,
      ),
      AthkarNavItem(
        label: 'الرئيسية',
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      AthkarNavItem(
        label: 'الأذكار',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
      ),
      AthkarNavItem(
        label: 'الإعدادات',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
      ),
    ];

    return MagneticDockNavBar(
      items: navItems,
      currentIndex: selectedIndex,
      onItemSelected: (index) {
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
        Navigator.of(context).pushReplacement(AppPageRoute.create(targetPage));
      },
    );
  }
}
