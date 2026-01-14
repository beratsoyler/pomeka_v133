import 'package:flutter/material.dart';

import '../localization/app_locale.dart';
import '../models/formula_meta.dart';

class FormulaCard extends StatelessWidget {
  final FormulaMeta formula;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final bool showFavoriteControl;

  const FormulaCard({
    super.key,
    required this.formula,
    required this.isFavorite,
    required this.onTap,
    this.onToggleFavorite,
    this.showFavoriteControl = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final iconWidget = formula.assetPath != null
        ? Image.asset(formula.assetPath!, width: 32, height: 32)
        : Icon(formula.icon ?? Icons.calculate, color: color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: showFavoriteControl
                    ? IconButton(
                        icon: Icon(
                          isFavorite ? Icons.star : Icons.star_border,
                          color: isFavorite ? Colors.amber : Colors.grey,
                        ),
                        tooltip: AppLocale.t('favorite_formulas'),
                        onPressed: onToggleFavorite,
                      )
                    : const SizedBox(height: 40),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocale.t(formula.titleKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
