import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calculation_history_record.dart';

class CalculationHistoryService {
  static const String _storageKey = 'calculation_history';

  static Future<List<CalculationHistoryRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final records = raw
        .map((entry) => CalculationHistoryRecord.fromJson(
            jsonDecode(entry) as Map<String, dynamic>))
        .toList();
    return records.reversed.toList();
  }

  static Future<void> append(CalculationHistoryRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_storageKey, raw);
  }

  static Future<void> removeByIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? [];
    final kept = <String>[];
    for (final entry in raw) {
      final decoded = jsonDecode(entry) as Map<String, dynamic>;
      final record = CalculationHistoryRecord.fromJson(decoded);
      if (!ids.contains(record.id)) {
        kept.add(entry);
      }
    }
    await prefs.setStringList(_storageKey, kept);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
