import 'package:flutter/material.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_input_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/common/constants.dart';

/// 🌊 Mindrium ApplyDesign 스타일로 통합된 ABC 연습 화면
class AbcPracticeScreen extends StatelessWidget {
  const AbcPracticeScreen({super.key});

  void _goNext(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) =>
                const AbcInputScreen(isExampleMode: true, showGuide: false),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const String titleText = '한번 연습해볼까요?';
    const String descriptionText =
        '방금 본 자전거 예시 상황에 몰입해 보면서\nABC 모델 연습을 해볼 거예요.';

    return ApplyDesign(
      appBarTitle: '2주차 - ABC 모델',
      cardTitle: titleText,
      onBack: () => Navigator.pop(context),
      onNext: () => _goNext(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.psychology_alt, size: 64, color: AppColors.indigo),
          SizedBox(height: 28),
          Text(
            descriptionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
