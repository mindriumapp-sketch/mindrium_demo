import 'package:flutter/material.dart';

enum ChoiceType { healthy, anxious, other, another }

class ChoiceCardButton extends StatelessWidget {
  final ChoiceType type;
  final VoidCallback onPressed;
  final String? othText;
  final String? anoText;
  final double? height;

  const ChoiceCardButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.othText,
    this.anoText,
    this.height = 42,
  });

  String? get _text {
    switch (type) {
      case ChoiceType.healthy:
        return '불안을 직면하는 행동';
      case ChoiceType.anxious:
        return '불안을 회피하는 행동';
      case ChoiceType.other:
        return othText;
      case ChoiceType.another:
        return anoText;
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case ChoiceType.healthy:
        return const Color(0xFF329CF1);
      case ChoiceType.anxious:
        return const Color(0xFFFDB0B5);
      case ChoiceType.other:
        return const Color(0xFF329CF1);
      case ChoiceType.another:
        return const Color(0xFFFDB0B5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(50),
            child: Center(
              child: Text(
                _text!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
