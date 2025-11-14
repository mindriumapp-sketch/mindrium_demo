import 'package:flutter/material.dart';
import 'package:gad_app_team/features/value_start.dart';
import 'package:gad_app_team/features/5th_treatment/week5_guide_screen.dart';

class Week5Screen extends StatelessWidget {
  const Week5Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueStartScreen(
      weekNumber: 5,
      weekTitle: '불안 직면과 회피에 대해 알아보겠습니다.',
      weekDescription:
          '이번 주차에서는 불안을 직면하는 것과 회피하는 것의 차이점을 배워보겠습니다. 성인 여성의 상황을 예시로 살펴볼게요.',
      nextPageBuilder: () => const Week5GuideScreen(),
    );
  }
}
