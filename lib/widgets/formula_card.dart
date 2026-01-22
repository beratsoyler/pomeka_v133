import 'package:flutter/material.dart';

import '../localization/app_locale.dart';
import '../models/formula_meta.dart';
import 'readable_text.dart';

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 180;
            final padding = compact ? 12.0 : 16.0;
            final iconSize = compact ? 36.0 : 48.0;
            final titleSpacing = compact ? 6.0 : 12.0;
            final titleStyle = TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 14,
            );
            final favoriteSize = compact ? 32.0 : 40.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: showFavoriteControl
                        ? IconButton(
                            constraints: BoxConstraints.tightFor(
                              width: favoriteSize,
                              height: favoriteSize,
                            ),
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite ? Colors.amber : Colors.grey,
                            ),
                            tooltip: AppLocale.t('favorite_formulas'),
                            onPressed: onToggleFavorite,
                          )
                        : SizedBox(height: favoriteSize),
                  ),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: iconWidget),
                    ),
                  ),
                  SizedBox(height: titleSpacing),
                  Expanded(
                    child: ReadableText(
                      text: AppLocale.t(formula.titleKey),
                      maxLines: 2,
                      style: titleStyle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
