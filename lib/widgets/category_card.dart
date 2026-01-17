import 'package:flutter/material.dart';

import '../localization/app_locale.dart';
import '../models/category_meta.dart';
import 'readable_text.dart';

class CategoryCard extends StatelessWidget {
  final CategoryMeta category;
  final int count;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 150;
            final padding = compact ? 12.0 : 16.0;
            final iconSize = compact ? 36.0 : 48.0;
            final titleStyle = TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 13 : 14,
            );
            final subtitleStyle = TextStyle(
              fontSize: compact ? 11 : 12,
              color: Colors.grey[500],
            );
            final titleSpacing = compact ? 6.0 : 12.0;
            final subtitleSpacing = compact ? 3.0 : 6.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    fit: FlexFit.loose,
                    child: Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(category.icon, color: color),
                    ),
                  ),
                  SizedBox(height: titleSpacing),
                  Expanded(
                    child: ReadableText(
                      text: AppLocale.t(category.titleKey),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: titleStyle,
                    ),
                  ),
                  SizedBox(height: subtitleSpacing),
                  ReadableText(
                    text: '$count ${AppLocale.t('formulas')}',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: subtitleStyle,
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
