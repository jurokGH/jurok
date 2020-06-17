import 'package:flutter/material.dart';

///Я пока отколючил отладочные принты здесь
const bool bPrintTextDebug=false;

class LimitSizeText extends StatelessWidget
{
  final String text;
  final TextAlign textAlign;
  final TextStyle style;
  final String template;
  final TextStyle templateStyle;

  LimitSizeText({
    @required this.text,
    this.textAlign,
    @required this.style,
    this.template,
    this.templateStyle
  });

  Size _textSize(String str, TextStyle style)
  {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: str, style: style), maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: textAlign == null ? TextAlign.center : textAlign)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  double maxFontSize(String text, TextStyle style, Size size)
  {
    for (double fontSize = style.fontSize; fontSize > 0; fontSize--)
    {
      Size textSize = _textSize(text, style.copyWith(fontSize: fontSize));
      bool fit = textSize.width <= size.width && textSize.height <= size.height;
      //print('textSize1 - $fontSize - $textSize - $size');
      if (fit)
        return fontSize;
    }
    // TODO
    return 1;
  }

  Widget _builder(BuildContext context, BoxConstraints constraints)
  {
    final double fontSize = maxFontSize(template == null ? text : template,
        templateStyle == null ? style : templateStyle,
        constraints.biggest);

    if ((fontSize < style.fontSize)&bPrintTextDebug)
      debugPrint('LimitSizeText limit to $fontSize from ${style.fontSize}');

    return Text(text,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      //style: widget.textStyle
      style: fontSize < style.fontSize ? style.copyWith(fontSize: fontSize) : style,
      textScaleFactor: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: _builder
    );
  }
}
