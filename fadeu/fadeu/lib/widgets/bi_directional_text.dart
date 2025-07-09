import 'package:flutter/material.dart';

/// A widget that handles bidirectional text properly, especially useful for
/// displaying mixed LTR/RTL content like translations in different languages.
class BiDirectionalText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool forceLTR;

  const BiDirectionalText(
    this.text, {
    Key? key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
    this.forceLTR = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the text contains any RTL characters
    final bool hasRtl = _hasRtlCharacters(text);
    final TextDirection textDirection = forceLTR || !hasRtl 
        ? TextDirection.ltr 
        : TextDirection.rtl;

    return Directionality(
      textDirection: textDirection,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        overflow: overflow,
        maxLines: maxLines,
        textDirection: textDirection,
      ),
    );
  }

  // Helper method to detect RTL characters
  bool _hasRtlCharacters(String text) {
    final rtlRegex = RegExp(
      r'[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]',
      unicode: true,
    );
    return rtlRegex.hasMatch(text);
  }
}
