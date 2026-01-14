import '../models/formula_meta.dart';

class FormulaSearch {
  static List<FormulaMeta> filter({
    required List<FormulaMeta> formulas,
    required String query,
    required String Function(String key) localize,
  }) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return formulas;
    }
    return formulas.where((formula) {
      final title = localize(formula.titleKey).toLowerCase();
      final tags = formula.tags.join(' ').toLowerCase();
      return title.contains(normalized) || tags.contains(normalized);
    }).toList();
  }
}
