import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutor_design.dart';
import 'package:gad_app_team/features/5th_treatment/week5_guide_detail.dart';

/// 🌊 Mindrium 스타일 - 5주차 불안 직면 VS 회피 (사례 소개 1단계)
class Week5GuideScreen extends StatelessWidget {
  const Week5GuideScreen({super.key});

  String get _description =>
      '이 여성은 34살의 초등학교 교사입니다. 그녀는 최근 6개월 동안, 거의 매일 특별한 이유 없이 불안하고 걱정이 많아졌다고 말합니다. 예를 들어, 수업 준비를 할 때마다 혹시 실수를 해서 학부모나 학교 측의 불만을 살까 봐 걱정이 됩니다.';

  @override
  Widget build(BuildContext context) {
    return AbcActivateDesign(
      appBarTitle: '5주차 - 불안 직면 VS 회피 (1)',
      scenarioImage: 'assets/image/scenario_1.png',
      descriptionText: _description,
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week5GuideDetailScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
