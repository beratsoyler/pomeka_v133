import 'package:flutter/material.dart';

import '../models/formula.dart';

class FormulaDetailScreen extends StatelessWidget {
  final Formula formula;

  const FormulaDetailScreen({super.key, required this.formula});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formula.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formula.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              formula.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _Section(
              title: 'Formül',
              child: Text(formula.formulaText),
            ),
            _Section(
              title: 'Değişkenler',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final variable in formula.variables)
                    Text('• ${variable.name} (${variable.unit})'),
                ],
              ),
            ),
            _Section(
              title: 'Örnek',
              child: Text(formula.example),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Geri Dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
