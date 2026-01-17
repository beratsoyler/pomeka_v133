import 'package:flutter/material.dart';

class ScrollableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final bool enableScroll;
  final Axis scrollDirection;
  final double? fadeWidth;
  final EdgeInsetsGeometry? padding;

  const ScrollableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
    this.textAlign,
    this.enableScroll = true,
    this.scrollDirection = Axis.horizontal,
    this.fadeWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : double.infinity;
        final painter = TextPainter(
          text: TextSpan(text: text, style: baseStyle),
          maxLines: maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: maxWidth);

        final isOverflowing =
            painter.didExceedMaxLines || painter.size.width > maxWidth;

        Widget content = Text(
          text,
          style: baseStyle,
          maxLines: maxLines,
          textAlign: textAlign,
          softWrap: false,
          overflow: TextOverflow.visible,
        );

        if (!enableScroll || !isOverflowing) {
          final normal = Tooltip(message: text, child: content);
          return padding == null ? normal : Padding(padding: padding!, child: normal);
        }

        Widget scrollView = SingleChildScrollView(
          scrollDirection: scrollDirection,
          child: Tooltip(message: text, child: content),
        );

        if (fadeWidth != null &&
            scrollDirection == Axis.horizontal &&
            fadeWidth! > 0) {
          scrollView = ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                (bounds.width - fadeWidth!) / bounds.width,
                1.0
              ],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: scrollView,
          );
        }

        return padding == null
            ? scrollView
            : Padding(padding: padding!, child: scrollView);
      },
    );
  }
}
