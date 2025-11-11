import 'package:flutter/material.dart';
import 'package:gad_app_team/features/value_start.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_guide_screen.dart';

class Week3Screen extends StatelessWidget {
  const Week3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueStartScreen(
      weekNumber: 3,
      weekTitle: '자기 대화(Self Talk) 기법을 익혀보겠습니다.',
      weekDescription:
          '이번 주차에서는 부정적인 자기 대화를 긍정적으로 바꾸는 방법을 배워보겠습니다. 성인 여성의 상황을 예시로 살펴볼게요.',
      nextPageBuilder: () => const Week3GuideScreen(),
    );
  }
}
