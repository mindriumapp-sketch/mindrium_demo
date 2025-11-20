import 'package:flutter/material.dart';

/// ✅ 완전 독립형 NavigationButtons 위젯
class NavigationButtons extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  const NavigationButtons({
    super.key,
    this.leftLabel = '이전',
    this.rightLabel = '다음',
    this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 내부 전용 팔레트 / 사이즈 정의
    const Color blueMain = Color(0xFF33A4F0);
    // const Color blueLight = Color(0xFF5DADEC);
    const Color white = Colors.white;
    const Color grey = Color(0xFF9E9E9E);
    const Color grey300 = Color(0xFFE0E0E0);
    const double fontSize = 15;
    const double borderRadius = 12;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      color: Colors.transparent,
      child: Row(
        children: [
          /// ⬅ 이전 버튼 (화이트 배경 + 블루 테두리)
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: onBack == null ? grey300 : blueMain,
                  width: 1.4,
                ),
                backgroundColor: white,
                foregroundColor: onBack == null ? grey : blueMain,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(leftLabel),
            ),
          ),

          const SizedBox(width: 12),

          /// ➡ 다음 버튼 (메인 블루)
          Expanded(
            child: FilledButton(
              onPressed: onNext,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (onNext == null || states.contains(WidgetState.disabled)) {
                    return grey300;
                  }
                  return blueMain;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                  states,
                ) {
                  if (onNext == null || states.contains(WidgetState.disabled)) {
                    return grey;
                  }
                  return white;
                }),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16),
                ),
                textStyle: WidgetStateProperty.all(
                  const TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                elevation: WidgetStateProperty.all(0),
              ),
              child: Text(rightLabel),
            ),
          ),
        ],
      ),
    );
  }
}
