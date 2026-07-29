import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global Favorites Manager for persisting and managing favorite Dhikrs and Duas.
class FavoritesManager {
  static const String _keyFavorites = 'favorite_dhikrs';

  /// ValueNotifier holding the current list of favorite items.
  static final ValueNotifier<List<Map<String, dynamic>>> favoriteDhikrs =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  /// Load favorites from local storage on app startup.
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_keyFavorites);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> parsed = json.decode(jsonString);
        favoriteDhikrs.value =
            parsed.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
  }

  /// Helper to extract text identifier from a Dhikr or Dua map.
  static String getItemText(Map<String, dynamic> dhikr) {
    return (dhikr['text'] ?? dhikr['content'] ?? dhikr['dhikr'] ?? dhikr['title'] ?? '')
        .toString()
        .trim();
  }

  /// Checks if a Dhikr or Dua is in the favorites list.
  static bool isFavorite(Map<String, dynamic> dhikr) {
    final text = getItemText(dhikr);
    if (text.isEmpty) return false;
    return favoriteDhikrs.value.any((item) => getItemText(item) == text);
  }

  /// Checks if a Dhikr by raw text is in the favorites list.
  static bool isFavoriteText(String text) {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return false;
    return favoriteDhikrs.value.any((item) => getItemText(item) == cleanText);
  }

  /// Toggles favorite state for a given Dhikr/Dua item, persists to storage, and shows feedback.
  static Future<bool> toggleFavorite(BuildContext? context, Map<String, dynamic> dhikr,
      {bool showSnackBar = true}) async {
    final String text = getItemText(dhikr);
    if (text.isEmpty) return false;

    final currentList = List<Map<String, dynamic>>.from(favoriteDhikrs.value);
    final index = currentList.indexWhere((item) => getItemText(item) == text);
    bool isNowFavorite = false;

    if (index >= 0) {
      currentList.removeAt(index);
      isNowFavorite = false;
    } else {
      currentList.add(Map<String, dynamic>.from(dhikr));
      isNowFavorite = true;
    }

    favoriteDhikrs.value = currentList;

    if (context != null && showSnackBar) {
      showFavoriteSnackBar(context, isNowFavorite);
    }

    await _saveToPrefs();

    return isNowFavorite;
  }

  /// Removes an item directly from favorites.
  static Future<void> removeFavorite(BuildContext? context, Map<String, dynamic> dhikr,
      {bool showSnackBar = true}) async {
    final String text = getItemText(dhikr);
    if (text.isEmpty) return;

    final currentList = List<Map<String, dynamic>>.from(favoriteDhikrs.value);
    currentList.removeWhere((item) => getItemText(item) == text);

    favoriteDhikrs.value = currentList;

    if (context != null && showSnackBar) {
      showFavoriteSnackBar(context, false);
    }

    await _saveToPrefs();
  }

  /// Displays floating SnackBar feedback after adding or removing a favorite.
  static void showFavoriteSnackBar(BuildContext context, bool isAdded) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdded ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: const Color(0xFFC5A059),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              isAdded ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة',
              style: const TextStyle(
                fontFamily: 'Fustat',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFDF9),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4E5B4E),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFEADFCF), width: 1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Writes current favorite items list to SharedPreferences.
  static Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = json.encode(favoriteDhikrs.value);
      await prefs.setString(_keyFavorites, jsonString);
    } catch (_) {}
  }
}
