import 'package:flutter/material.dart';

import '../../data/formulas_seed.dart';
import '../../main.dart';
import '../../models/formula.dart';
import '../../models/formula_category.dart';
import '../../widgets/search_bar.dart';
import 'formula_detail_screen.dart';

class CategoryFormulasScreen extends StatefulWidget {
  final FormulaCategory category;

  const CategoryFormulasScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryFormulasScreen> createState() => _CategoryFormulasScreenState();
}

class _CategoryFormulasScreenState extends State<CategoryFormulasScreen> {
  String _query = '';

  List<Formula> get _formulas {
    return formulasSeed
        .where((formula) => formula.categoryId == widget.category.id)
        .where((formula) {
      if (_query.trim().isEmpty) return true;
      final query = _query.toLowerCase();
      final inTitle = formula.title.toLowerCase().contains(query);
      final inDesc = formula.description.toLowerCase().contains(query);
      final inTags = formula.tags.any((tag) => tag.toLowerCase().contains(query));
      return inTitle || inDesc || inTags;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _formulas;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.title),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            FormulaSearchBar(
              hintText: AppLocale.t('search_formulas'),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final formula = results[index];
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FormulaDetailScreen(formula: formula),
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.12),
                              child: Icon(formula.icon ?? widget.category.icon,
                                  color:
                                      Theme.of(context).colorScheme.primary),
                            ),
                            title: Text(formula.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              formula.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off,
              size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(AppLocale.t('no_results'),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
