import 'package:flutter/material.dart';

import '../data/formulas_seed.dart';
import '../models/formula.dart';
import '../models/formula_category.dart';
import '../widgets/formula_list_item.dart';
import '../widgets/formula_search_bar.dart';
import 'formula_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final FormulaCategory category;

  const CategoryScreen({super.key, required this.category});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Formula> _filteredFormulas() {
    final formulas = formulasSeed
        .where((formula) => formula.categoryId == widget.category.id)
        .toList();
    if (_query.isEmpty) {
      return formulas;
    }
    final normalizedQuery = _normalize(_query);
    return formulas.where((formula) {
      final haystack = _normalize(
        '${formula.name} ${formula.description} ${formula.tags.join(' ')}',
      );
      return haystack.contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formulas = _filteredFormulas();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FormulaSearchBar(
              controller: _searchController,
              hintText: 'Formül ara (örn: Genleşme, Debi, Basınç...)',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: formulas.isEmpty
                ? const _EmptyState()
                : ListView.builder(
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
                  ),
          ),
        ],
      ),
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
