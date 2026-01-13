import 'package:flutter/material.dart';

import '../../data/formulas_seed.dart';
import '../../models/formula.dart';
import '../../models/formula_category.dart';
import '../../widgets/search_bar.dart';
import '../../main.dart';
import 'category_formulas_screen.dart';
import 'formula_detail_screen.dart';

class FormulasHomeScreen extends StatefulWidget {
  const FormulasHomeScreen({super.key});

  @override
  State<FormulasHomeScreen> createState() => _FormulasHomeScreenState();
}

class _FormulasHomeScreenState extends State<FormulasHomeScreen> {
  String _searchQuery = '';

  List<Formula> get _filteredFormulas {
    if (_searchQuery.trim().isEmpty) {
      return const [];
    }
    final query = _searchQuery.toLowerCase();
    return formulasSeed.where((formula) {
      final inTitle = formula.title.toLowerCase().contains(query);
      final inDesc = formula.description.toLowerCase().contains(query);
      final inTags = formula.tags.any((tag) => tag.toLowerCase().contains(query));
      return inTitle || inDesc || inTags;
    }).toList();
  }

  List<Formula> get _recentFormulas {
    final recents = formulasSeed
        .where((f) => f.lastUsedAt != null)
        .toList()
      ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return recents.take(4).toList();
  }

  void _openFormula(Formula formula) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormulaDetailScreen(formula: formula),
      ),
    );
  }

  void _openCategory(FormulaCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryFormulasScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredFormulas;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t('formulas')),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: () {},
            tooltip: AppLocale.t('favorites'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            FormulaSearchBar(
              hintText: AppLocale.t('search_formulas'),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _searchQuery.trim().isEmpty
                  ? _buildCategoryView(context)
                  : _buildSearchResults(results),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 2;
        return ListView(
          children: [
            if (_recentFormulas.isNotEmpty) ...[
              Text(
                AppLocale.t('recent_formulas'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentFormulas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final formula = _recentFormulas[index];
                    return SizedBox(
                      width: 220,
                      child: _FormulaCard(
                        formula: formula,
                        category: _categoryFor(formula),
                        onTap: () => _openFormula(formula),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              AppLocale.t('categories'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: formulaCategories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final category = formulaCategories[index];
                return InkWell(
                  onTap: () => _openCategory(category),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary.withValues(
                                    alpha: 0.12,
                                  ),
                          child: Icon(category.icon,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults(List<Formula> results) {
    if (results.isEmpty) {
      return _EmptyState(
        title: AppLocale.t('no_results'),
        subtitle: AppLocale.t('no_results_hint'),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final formula = results[index];
        return _FormulaCard(
          formula: formula,
          category: _categoryFor(formula),
          onTap: () => _openFormula(formula),
        );
      },
    );
  }

  FormulaCategory _categoryFor(Formula formula) {
    return formulaCategories.firstWhere((c) => c.id == formula.categoryId);
  }
}

class _FormulaCard extends StatelessWidget {
  final Formula formula;
  final FormulaCategory category;
  final VoidCallback onTap;

  const _FormulaCard({
    required this.formula,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(formula.icon ?? category.icon,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(formula.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          formula.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            category.title,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
