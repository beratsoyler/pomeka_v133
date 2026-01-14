class CalculationResult {
  final String formulaId;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final DateTime timestamp;

  CalculationResult({
    required this.formulaId,
    required this.inputs,
    required this.outputs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'formulaId': formulaId,
      'inputs': inputs,
      'outputs': outputs,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory CalculationResult.fromJson(Map<String, dynamic> json) {
    return CalculationResult(
      formulaId: json['formulaId']?.toString() ?? '',
      inputs: Map<String, dynamic>.from(json['inputs'] ?? {}),
      outputs: Map<String, dynamic>.from(json['outputs'] ?? {}),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
    );
  }
}
