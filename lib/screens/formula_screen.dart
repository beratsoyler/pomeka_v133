import 'package:flutter/material.dart';

import '../localization/app_locale.dart';
import '../screens/calculators.dart';
import '../services/formula_storage.dart';
import '../widgets/readable_text.dart';

class FormulaScreen extends StatefulWidget {
  final String formulaId;
  final String titleKey;
  final Widget child;

  const FormulaScreen({
    super.key,
    required this.formulaId,
    required this.titleKey,
    required this.child,
  });

  @override
  State<FormulaScreen> createState() => _FormulaScreenState();
}

class _FormulaScreenState extends State<FormulaScreen> {
  final FormulaStorage _storage = FormulaStorage();
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    _storage.recordRecent(widget.formulaId);
  }

  Future<void> _loadFavorite() async {
    final isFavorite = await _storage.isFavorite(widget.formulaId);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    final next = await _storage.toggleFavorite(widget.formulaId);
    if (!mounted) return;
    setState(() => _isFavorite = next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ReadableText(
          text: AppLocale.t(widget.titleKey),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: widget.child,
    );
  }
}
