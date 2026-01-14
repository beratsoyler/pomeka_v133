class FormulaVariable {
  final String name;
  final String unit;

  const FormulaVariable({
    required this.name,
    required this.unit,
  });
}

class Formula {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String description;
  final String formulaText;
  final List<FormulaVariable> variables;
  final List<String> tags;
  final String example;

  const Formula({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.formulaText,
    required this.variables,
    required this.tags,
    required this.example,
  });
}
