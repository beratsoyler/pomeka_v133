import 'package:shared_preferences/shared_preferences.dart';

class FormulaStorage {
  static const String _recentKey = 'recent_formulas';
  static const String _favoriteKey = 'favorite_formulas';
  static const int _recentLimit = 10;

  Future<List<String>> loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentKey) ?? [];
  }

  Future<List<String>> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoriteKey) ?? [];
  }

  Future<void> recordRecent(String formulaId) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_recentKey) ?? [];
    items.remove(formulaId);
    items.insert(0, formulaId);
    if (items.length > _recentLimit) {
      items.removeRange(_recentLimit, items.length);
    }
    await prefs.setStringList(_recentKey, items);
  }

  Future<bool> toggleFavorite(String formulaId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteKey) ?? [];
    if (favorites.contains(formulaId)) {
      favorites.remove(formulaId);
      await prefs.setStringList(_favoriteKey, favorites);
      return false;
    }
    favorites.insert(0, formulaId);
    await prefs.setStringList(_favoriteKey, favorites);
    return true;
  }

  Future<bool> isFavorite(String formulaId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteKey) ?? [];
    return favorites.contains(formulaId);
  }
}
