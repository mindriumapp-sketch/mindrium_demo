import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutor_design.dart';
import 'package:gad_app_team/features/5th_treatment/week5_practice_screen.dart';

/// 💬 5주차 - 불안 직면 VS 회피 (2단계: 시나리오 후반부)
class Week5ConsequenceDetailScreen extends StatelessWidget {
  const Week5ConsequenceDetailScreen({super.key});

  final String _description =
      '점점 친구들을 만나는 것도 부담스럽게 느껴지고, 주말에도 집에만 있으려는 경우가 많아졌습니다. 동료나 가족과 대화를 나눌 때도 예민하게 반응하거나 감정 기복이 커졌다는 이야기를 듣게 되었습니다.';

  @override
  Widget build(BuildContext context) {
    return AbcActivateDesign(
      appBarTitle: '5주차 - 불안 직면 VS 회피 (2)',
      scenarioImage: 'assets/image/scenario_3.png',
      descriptionText: _description,
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week5PracticeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
