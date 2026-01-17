import 'package:flutter/material.dart';

class ResponsiveTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final double minFontSize;
  final TextAlign textAlign;

  const ResponsiveTitle({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
    this.minFontSize = 11,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final baseFontSize = baseStyle.fontSize ?? 14;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : double.infinity;

        bool fitsWithFont(double size) {
          final painter = TextPainter(
            text: TextSpan(text: text, style: baseStyle.copyWith(fontSize: size)),
            maxLines: maxLines,
            textAlign: textAlign,
            textDirection: Directionality.of(context),
          )..layout(maxWidth: maxWidth);
          return !painter.didExceedMaxLines;
        }

        double low = minFontSize;
        double high = baseFontSize;
        double best = minFontSize;

        for (int i = 0; i < 10; i++) {
          final mid = (low + high) / 2;
          if (fitsWithFont(mid)) {
            best = mid;
            low = mid;
          } else {
            high = mid;
          }
        }

        final effectiveStyle = baseStyle.copyWith(fontSize: best);
        final painter = TextPainter(
          text: TextSpan(text: text, style: effectiveStyle),
          maxLines: maxLines,
          textAlign: textAlign,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: maxWidth);
        final isOverflowing = painter.didExceedMaxLines;

        final textWidget = Text(
          text,
          style: effectiveStyle,
          maxLines: maxLines,
          softWrap: true,
          overflow: TextOverflow.clip,
          textAlign: textAlign,
        );

        if (!isOverflowing) {
          return textWidget;
        }

        return GestureDetector(
          onTap: () => _showFullText(context),
          onLongPress: () => _showFullText(context),
          child: textWidget,
        );
      },
    );
  }

  void _showFullText(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: SelectableText(
            text,
            style: style,
            textAlign: textAlign,
          ),
        );
      },
    );
  }
}
