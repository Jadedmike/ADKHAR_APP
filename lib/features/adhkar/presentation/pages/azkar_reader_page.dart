import 'package:flutter/material.dart';
import 'single_dhikr_page.dart';

/// Alias for AzkarReaderPage pointing to SingleDhikrPage.
class AzkarReaderPage extends StatelessWidget {
  final String categoryTitle;

  const AzkarReaderPage({
    super.key,
    this.categoryTitle = 'أذكار الصباح',
  });

  @override
  Widget build(BuildContext context) {
    return SingleDhikrPage(categoryTitle: categoryTitle);
  }
}
