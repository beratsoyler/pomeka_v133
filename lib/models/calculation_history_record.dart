class CalculationHistoryRecord {
  final String id;
  final String formulaId;
  final String formulaName;
  final DateTime createdAt;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final String? notes;

  const CalculationHistoryRecord({
    required this.id,
    required this.formulaId,
    required this.formulaName,
    required this.createdAt,
    required this.inputs,
    required this.outputs,
    this.notes,
  });

  factory CalculationHistoryRecord.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['createdAt'] ?? json['time'];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : null;
    final inputsRaw = json['inputs'];
    final outputsRaw = json['outputs'] ?? json['res'];
    return CalculationHistoryRecord(
      id: (json['id'] ?? createdAt?.microsecondsSinceEpoch ?? '')
          .toString(),
      formulaId: (json['formulaId'] ?? json['type'] ?? 'legacy').toString(),
      formulaName: (json['formulaName'] ?? json['type'] ?? 'Hesap')
          .toString(),
      createdAt: createdAt ?? DateTime.now(),
      inputs: inputsRaw is Map
          ? Map<String, dynamic>.from(inputsRaw)
          : {'Inputs': inputsRaw?.toString() ?? '-'},
      outputs: outputsRaw is Map
          ? Map<String, dynamic>.from(outputsRaw)
          : {'Result': outputsRaw?.toString() ?? '-'},
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{
      'id': id,
      'formulaId': formulaId,
      'formulaName': formulaName,
      'createdAt': createdAt.toIso8601String(),
      'inputs': inputs,
      'outputs': outputs,
    };
    if (notes != null && notes!.isNotEmpty) {
      data['notes'] = notes;
    }
    return data;
  }
}
