import 'package:flutter/material.dart';

import '../localization/app_locale.dart';
import '../models/category_meta.dart';
import '../registry/formula_registry.dart';
import '../services/formula_storage.dart';
import '../widgets/formula_card.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryMeta category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final FormulaStorage _storage = FormulaStorage();
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final items = await _storage.loadFavorites();
    if (!mounted) return;
    setState(() => _favorites = items.toSet());
  }

  Future<void> _toggleFavorite(String id) async {
    final next = await _storage.toggleFavorite(id);
    if (!mounted) return;
    setState(() {
      if (next) {
        _favorites.add(id);
      } else {
        _favorites.remove(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formulas = FormulaRegistry.formulasForCategory(widget.category.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t(widget.category.titleKey)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
            ),
            itemCount: formulas.length,
            itemBuilder: (context, index) {
              final formula = formulas[index];
              final isFavorite = _favorites.contains(formula.id);
              return FormulaCard(
                formula: formula,
                isFavorite: isFavorite,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: formula.builder),
                ),
                onToggleFavorite: () => _toggleFavorite(formula.id),
              );
            },
          );
        },
      ),
    );
  }
}
