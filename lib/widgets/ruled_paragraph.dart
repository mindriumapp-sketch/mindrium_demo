import 'package:flutter/material.dart';

/// 줄노트 스타일 문단: 각 줄 아래에 고정 폭(lineWidth)의 밑줄을 가운데 정렬로 그림
/// 4주차 등등 상상해 보세요/생각해 보세요/떠올려 보세요 같은 카드 본문 내용에 들어가는 디자인 요소 (선택)
class RuledParagraph extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final Color lineColor;
  final double lineThickness;
  final double lineGapBelow;
  final EdgeInsets padding;
  final double? lineWidth;

  const RuledParagraph({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.lineColor = const Color(0xFFE5EEF9),
    this.lineThickness = 1.0,
    this.lineGapBelow = 6.0,
    this.padding = EdgeInsets.zero,
    this.lineWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final layoutWidth = (lineWidth != null)
            ? lineWidth!.clamp(0, c.maxWidth - padding.horizontal).toDouble()
            : (c.maxWidth - padding.horizontal);

        final tp = TextPainter(
          text: TextSpan(text: text, style: style),
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
          maxLines: null,
        )..layout(maxWidth: layoutWidth);

        final height = tp.height + padding.vertical + lineThickness + lineGapBelow;

        return CustomPaint(
          size: Size(c.maxWidth, height),
          painter: _RuledParagraphPainter(
            tp: tp,
            textAlign: textAlign,
            lineColor: lineColor,
            lineThickness: lineThickness,
            lineGapBelow: lineGapBelow,
            padding: padding,
            fixedLineWidth: lineWidth,
          ),
        );
      },
    );
  }
}

class _RuledParagraphPainter extends CustomPainter {
  final TextPainter tp;
  final TextAlign textAlign;
  final Color lineColor;
  final double lineThickness;
  final double lineGapBelow;
  final EdgeInsets padding;
  final double? fixedLineWidth;

  _RuledParagraphPainter({
    required this.tp,
    required this.textAlign,
    required this.lineColor,
    required this.lineThickness,
    required this.lineGapBelow,
    required this.padding,
    required this.fixedLineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textOffset = Offset((size.width - tp.width) / 2, padding.top);
    tp.paint(canvas, textOffset);

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineThickness
      ..style = PaintingStyle.stroke;

    final metrics = tp.computeLineMetrics();
    for (final m in metrics) {
      final y = padding.top + m.baseline + lineGapBelow;
      final double lineW = fixedLineWidth ?? m.width;
      final double left = (size.width - lineW) / 2;
      final double right = left + lineW;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RuledParagraphPainter old) {
    return tp.text != old.tp.text ||
        lineColor != old.lineColor ||
        lineThickness != old.lineThickness ||
        lineGapBelow != old.lineGapBelow ||
        padding != old.padding ||
        textAlign != old.textAlign ||
        fixedLineWidth != old.fixedLineWidth;
  }
}