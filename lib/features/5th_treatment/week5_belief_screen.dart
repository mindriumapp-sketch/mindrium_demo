import 'package:flutter/material.dart';
import 'package:gad_app_team/features/5th_treatment/week5_consequence_screen.dart';
import 'package:gad_app_team/widgets/tutor_design.dart';

/// 🌊 Mindrium 스타일 - 5주차 불안 직면 VS 회피 화면
class Week5BeliefScreen extends StatelessWidget {
  const Week5BeliefScreen({super.key});

  String get _description =>
      '걱정이 많아지면서 신체적으로도 여러 증상이 나타났습니다.\n'
          '평소에는 느끼지 못했던 어깨와 목의 뻐근함이 거의 매일 지속되고,\n'
          '마치 온몸에 힘이 들어간 것처럼 긴장된 상태가 계속됩니다.\n'
          '밤에는 잠들기까지 1시간 이상 걸릴 때도 있고,\n'
          '한밤중에 자주 깨거나 자고 나서도 개운하지 않다고 느낍니다.';
  @override
  Widget build(BuildContext context) {
    return AbcActivateDesign(
      appBarTitle: '5주차 - 불안 직면 VS 회피',
      scenarioImage: 'assets/image/scenario_2.png',
      descriptionText: _description,
      memoHeightFactor: 0.75,

      /// ⬅️ 네비게이션
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week5ConsequenceScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
