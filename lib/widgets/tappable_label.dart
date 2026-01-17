import 'package:flutter/material.dart';

class TappableLabel extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign? textAlign;
  final EdgeInsetsGeometry? padding;
  final bool enableTooltip;

  const TappableLabel({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 2,
    this.textAlign,
    this.padding,
    this.enableTooltip = true,
  });

  Future<void> _showFullTextDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: SelectableText(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final painter = TextPainter(
          text: TextSpan(text: text, style: baseStyle),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: maxWidth);

        final isOverflowing = painter.didExceedMaxLines;
        Widget content = Text(
          text,
          style: baseStyle,
          maxLines: maxLines,
          textAlign: textAlign,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
        );

        if (enableTooltip && isOverflowing) {
          content = Tooltip(message: text, child: content);
        }

        if (isOverflowing) {
          content = GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _showFullTextDialog(context),
            child: content,
          );
        }

        return padding == null
            ? content
            : Padding(padding: padding!, child: content);
      },
    );
  }
}
