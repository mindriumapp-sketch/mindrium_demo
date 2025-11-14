import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutor_design.dart';
import 'package:gad_app_team/features/5th_treatment/week5_consequence_detail.dart';

/// 💬 5주차 - 불안 직면 VS 회피 (1단계: 시나리오 소개)
class Week5ConsequenceScreen extends StatelessWidget {
  const Week5ConsequenceScreen({super.key});

  final String _description =
      '수업 중에도 쉽게 피로를 느끼고, 가슴이 갑갑하거나 속이 울렁거리는 증상이 가끔 나타납니다. 집중력도 눈에 띄게 떨어져서 수업 자료를 준비하다가도 멍하니 시간을 보내는 일이 잦아졌습니다.';

  @override
  Widget build(BuildContext context) {
    return AbcActivateDesign(
      appBarTitle: '5주차 - 불안 직면 VS 회피 (1)',
      scenarioImage: 'assets/image/scenario_3.png',
      descriptionText: _description,
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week5ConsequenceDetailScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
