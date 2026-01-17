class FormulaTransferData {
  final String sourceFormulaId;
  final String targetFormulaId;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const FormulaTransferData({
    required this.sourceFormulaId,
    required this.targetFormulaId,
    required this.createdAt,
    required this.data,
  });
}
