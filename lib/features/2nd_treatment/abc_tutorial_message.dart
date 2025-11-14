import 'package:flutter/material.dart';

/// 💬 Mindrium ABC 튜토리얼 인라인 안내 메시지
///
/// 각 단계에서 [tutorialStep] 값에 따라 다른 텍스트를 표시.
/// 내부에서 자동으로 텍스트를 매칭해 표시합니다.
class AbcTutorialMessage extends StatelessWidget {
  final int tutorialStep;

  const AbcTutorialMessage({super.key, required this.tutorialStep});

  /// 🔢 튜토리얼 단계별 문구 정의
  String _messageForStep(int step) {
    switch (step) {
      case 0:
        return "위의 ‘자전거를 타려고 함’ 칩을 눌러 선택해보세요!";
      case 1:
        return "선택한 뒤 아래의 ‘다음’ 버튼을 눌러주세요!";
      case 2:
        return "입력한 내용을 선택하고\n‘다음’ 버튼을 눌러주세요!";
      case 3:
        return "위의 ‘넘어질까봐 두려움’ 칩을 눌러 선택해보세요!";
      case 4:
        return "선택한 뒤 아래의 ‘다음’ 버튼을 눌러주세요!";
      case 5:
        return "위의 ‘자전거를 타지 않았어요’ 칩을 눌러 선택해보세요!";
      case 6:
        return "선택한 뒤 ‘확인’ 버튼을 눌러주세요!";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _messageForStep(tutorialStep);
    if (text.isEmpty) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
