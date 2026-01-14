import 'package:flutter/material.dart';

import '../data/formulas_seed.dart';
import '../models/formula.dart';
import '../models/formula_category.dart';
import '../widgets/category_tile.dart';
import '../widgets/formula_list_item.dart';
import '../widgets/formula_search_bar.dart';
import 'category_screen.dart';
import 'formula_detail_screen.dart';

class FormulaHomeScreen extends StatefulWidget {
  const FormulaHomeScreen({super.key});

  @override
  State<FormulaHomeScreen> createState() => _FormulaHomeScreenState();
}

class _FormulaHomeScreenState extends State<FormulaHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Formula> _filteredFormulas() {
    if (_query.isEmpty) {
      return [];
    }
    final normalizedQuery = _normalize(_query);
    return formulasSeed.where((formula) {
      final haystack = _normalize(
        '${formula.name} ${formula.description} ${formula.tags.join(' ')}',
      );
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFormulas = _filteredFormulas();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formüller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border),
            tooltip: 'Favoriler',
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: FormulaSearchBar(
              controller: _searchController,
              hintText: 'Formül ara (örn: Genleşme, Debi, Basınç...)',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _CategoryGrid(
                    categories: formulaCategories,
                    onTap: (category) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryScreen(category: category),
                      ),
                    ),
                  )
                : filteredFormulas.isEmpty
                    ? const _EmptyState()
                    : _FormulaResults(
                        formulas: filteredFormulas,
                      ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<FormulaCategory> categories;
  final ValueChanged<FormulaCategory> onTap;

  const _CategoryGrid({
    required this.categories,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 900
            ? 3
            : width > 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryTile(
              category: category,
              count: categoryFormulaCount(category.id),
              onTap: () => onTap(category),
            );
          },
        );
      },
    );
  }
}

class _FormulaResults extends StatelessWidget {
  final List<Formula> formulas;

  const _FormulaResults({required this.formulas});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: formulas.length,
      itemBuilder: (context, index) {
        final formula = formulas[index];
        return FormulaListItem(
          formula: formula,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormulaDetailScreen(formula: formula),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            'Sonuç bulunamadı.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}

String _normalize(String input) {
  return input
      .replaceAll('İ', 'i')
      .replaceAll('I', 'i')
      .replaceAll('ı', 'i')
      .replaceAll('Ş', 's')
      .replaceAll('ş', 's')
      .replaceAll('Ğ', 'g')
      .replaceAll('ğ', 'g')
      .replaceAll('Ü', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('Ö', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('Ç', 'c')
      .replaceAll('ç', 'c')
      .toLowerCase()
      .replaceAll('i̇', 'i');
}
