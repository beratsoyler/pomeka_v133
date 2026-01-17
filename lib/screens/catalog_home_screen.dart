import 'dart:async';

import 'package:flutter/material.dart';

import '../localization/app_locale.dart';
import '../models/formula_meta.dart';
import '../registry/formula_registry.dart';
import '../search/formula_search.dart';
import '../services/formula_storage.dart';
import '../widgets/category_card.dart';
import '../widgets/formula_card.dart';
import 'category_screen.dart';
import 'calculators.dart';

class CatalogHomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const CatalogHomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<CatalogHomeScreen> createState() => _CatalogHomeScreenState();
}

class _CatalogHomeScreenState extends State<CatalogHomeScreen> {
  final FormulaStorage _storage = FormulaStorage();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<String> _recentIds = [];
  List<String> _favoriteIds = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadStorage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStorage() async {
    final recent = await _storage.loadRecent();
    final favorites = await _storage.loadFavorites();
    if (!mounted) return;
    setState(() {
      _recentIds = recent;
      _favoriteIds = favorites;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() => _query = value);
    });
  }

  Future<void> _openFormula(String id) async {
    final formula = FormulaRegistry.findById(id);
    if (formula == null) return;
    await _storage.recordRecent(id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: formula.builder),
    );
    _loadStorage();
  }

  Future<void> _toggleFavorite(String id) async {
    final isFavorite = await _storage.toggleFavorite(id);
    if (!mounted) return;
    setState(() {
      if (isFavorite) {
        _favoriteIds.insert(0, id);
      } else {
        _favoriteIds.remove(id);
      }
    });
  }

  List<Widget> _buildFormulaCards(List<String> ids,
      {bool showFavoriteControl = true}) {
    final formulas = ids
        .map(FormulaRegistry.findById)
        .whereType()
        .toList();
    return formulas.map((formula) {
      final isFavorite = _favoriteIds.contains(formula.id);
      return SizedBox(
        width: 180,
        child: FormulaCard(
          formula: formula,
          isFavorite: isFavorite,
          onTap: () => _openFormula(formula.id),
          onToggleFavorite:
              showFavoriteControl ? () => _toggleFavorite(formula.id) : null,
          showFavoriteControl: showFavoriteControl,
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allFormulas = FormulaRegistry.enabledFormulas();
    final categories = [...FormulaRegistry.categories]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final hasQuery = _query.trim().isNotEmpty;
    final results = FormulaSearch.filter(
      formulas: allFormulas,
      query: _query,
      localize: AppLocale.t,
    );

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/pomeka-png-1757403926.png', height: 32),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const HistoryScreen()))),
          Switch(value: widget.isDarkMode, onChanged: widget.onThemeChanged),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStorage,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: AppLocale.t('search_formulas'),
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            if (hasQuery) ...[
              _SectionHeader(title: AppLocale.t('search_results')),
              const SizedBox(height: 12),
              if (results.isEmpty)
                Text(
                  AppLocale.t('no_results'),
                  style: TextStyle(color: Colors.grey[600]),
                )
              else
                _FormulaGrid(
                  formulas: results,
                  favorites: _favoriteIds,
                  onTap: _openFormula,
                  onToggleFavorite: _toggleFavorite,
                ),
            ] else ...[
              _SectionHeader(title: AppLocale.t('recent_formulas')),
              const SizedBox(height: 12),
              if (_recentIds.isEmpty)
                Text(
                  AppLocale.t('no_recent'),
                  style: TextStyle(color: Colors.grey[600]),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _buildFormulaCards(_recentIds),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionHeader(title: AppLocale.t('favorite_formulas')),
              const SizedBox(height: 12),
              if (_favoriteIds.isEmpty)
                Text(
                  AppLocale.t('no_favorites'),
                  style: TextStyle(color: Colors.grey[600]),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _buildFormulaCards(_favoriteIds),
                  ),
                ),
              const SizedBox(height: 24),
              _SectionHeader(title: AppLocale.t('categories')),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final count =
                          FormulaRegistry.countForCategory(category.id);
                      return CategoryCard(
                        category: category,
                        count: count,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(category: category),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FormulaGrid extends StatelessWidget {
  final List<FormulaMeta> formulas;
  final List<String> favorites;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onToggleFavorite;

  const _FormulaGrid({
    required this.formulas,
    required this.favorites,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: formulas.length,
          itemBuilder: (context, index) {
            final formula = formulas[index];
            final isFavorite = favorites.contains(formula.id);
            return FormulaCard(
              formula: formula,
              isFavorite: isFavorite,
              onTap: () => onTap(formula.id),
              onToggleFavorite: () => onToggleFavorite(formula.id),
            );
          },
        );
      },
    );
  }
}
