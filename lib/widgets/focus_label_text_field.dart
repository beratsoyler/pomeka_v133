import 'dart:async';

import 'package:flutter/material.dart';

class FocusLabelTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final Widget? labelWidget;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final String? suffixText;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final TextStyle? style;
  final int? maxLines;

  const FocusLabelTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.labelWidget,
    this.keyboardType,
    this.prefixIcon,
    this.suffixText,
    this.onChanged,
    this.enabled = true,
    this.style,
    this.maxLines = 1,
  });

  @override
  State<FocusLabelTextField> createState() => _FocusLabelTextFieldState();
}

class _FocusLabelTextFieldState extends State<FocusLabelTextField> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeOverlay();
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
    setState(() {});
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ) ??
        const TextStyle(fontWeight: FontWeight.w600);

    const double horizontalPadding = 16;
    const double verticalPadding = 8;
    const double bubbleHorizontalPadding = 12;
    const double bubbleVerticalPadding = 8;
    const double gap = 8;

    final maxWidth = media.size.width - horizontalPadding * 2;
    final textPainter = TextPainter(
      text: TextSpan(text: widget.labelText, style: textStyle),
      textDirection: Directionality.of(context),
      maxLines: 3,
    )..layout(maxWidth: maxWidth - bubbleHorizontalPadding * 2);

    final bubbleHeight = textPainter.size.height + bubbleVerticalPadding * 2;
    final renderOffset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final availableAbove = renderOffset.dy - media.padding.top;
    final availableBelow = media.size.height -
        media.padding.bottom -
        (renderOffset.dy + size.height);
    final placeBelow =
        availableBelow > bubbleHeight + gap || availableBelow > availableAbove;

    final desiredTop = placeBelow
        ? renderOffset.dy + size.height + gap
        : renderOffset.dy - bubbleHeight - gap;
    final minTop = media.padding.top + verticalPadding;
    final maxTop =
        media.size.height - media.padding.bottom - bubbleHeight - verticalPadding;
    final clampedTop = desiredTop.clamp(minTop, maxTop);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: horizontalPadding,
          right: horizontalPadding,
          top: clampedTop,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: bubbleHorizontalPadding,
                  vertical: bubbleVerticalPadding,
                ),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: theme.brightness == Brightness.dark ? 0.2 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  widget.labelText,
                  maxLines: 3,
                  softWrap: true,
                  style: textStyle,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), _removeOverlay);
  }

  void _removeOverlay() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocused = _focusNode.hasFocus;
    final focusColor = theme.colorScheme.primary.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isFocused ? focusColor : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        enabled: widget.enabled,
        style: widget.style,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          label: widget.labelWidget ??
              Text(
                widget.labelText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          prefixIcon: widget.prefixIcon,
          suffixText: widget.suffixText,
        ),
      ),
    );
  }
}
