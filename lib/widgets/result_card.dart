import 'package:flutter/material.dart';

import 'tappable_label.dart';

class ResultCard extends StatelessWidget {
  final List<ResultRow> rows;

  const ResultCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0052FF), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0052FF).withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .expand((row) => [row, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const ResultRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0052FF),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TappableLabel(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: valueStyle),
      ],
    );
  }
}
