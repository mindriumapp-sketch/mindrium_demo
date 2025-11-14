// lib/widgets/choice_card_button.dart

import 'package:flutter/material.dart';

enum ChoiceType {
  healthy,
  anxious,
  helpful,   // Week3: 도움이 되는 생각
  unhelpful, // Week3: 도움이 되지 않는 생각
  other,
  another,
}

class ChoiceCardButton extends StatelessWidget {
  final ChoiceType type;
  final VoidCallback onPressed;
  final String? othText;
  final String? anoText;
  final double height; // nullable 제거: 항상 명확한 높이

  const ChoiceCardButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.othText,
    this.anoText,
    this.height = 54, // ✅ ThoughtBubble 과 비슷한 두께 (기본 54)
  });

  String get _text {
    switch (type) {
      case ChoiceType.healthy:
        return '불안을 직면하는 행동';
      case ChoiceType.anxious:
        return '불안을 회피하는 행동';
      case ChoiceType.helpful:
        return '도움이 되는 생각';
      case ChoiceType.unhelpful:
        return '도움이 되지 않는 생각';
      case ChoiceType.other:
        return othText ?? '';
      case ChoiceType.another:
        return anoText ?? '';
    }
  }

  Color get _backgroundColor {
    switch (type) {
      case ChoiceType.healthy:
      case ChoiceType.helpful:
      case ChoiceType.other:
        return const Color(0xFF329CF1); // 파랑
      case ChoiceType.anxious:
      case ChoiceType.unhelpful:
      case ChoiceType.another:
        return const Color(0xFFFDB0B5); // 핑크
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
          borderRadius: BorderRadius.circular(height / 2),
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
            borderRadius: BorderRadius.circular(height / 2),
            child: Center(
              child: Text(
                _text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  fontFamily: 'Noto Sans KR',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
