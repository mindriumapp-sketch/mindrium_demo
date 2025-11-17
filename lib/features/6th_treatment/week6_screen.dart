import 'package:flutter/material.dart';
import 'package:gad_app_team/features/value_start.dart';
import 'package:gad_app_team/features/6th_treatment/week6_abc_screen.dart';

class Week6Screen extends StatelessWidget {
  const Week6Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueStartScreen(
      weekNumber: 6,
      weekTitle: '불안 직면과 회피를 실습해보겠습니다.',
      weekDescription:
          '이번 주차에서는 걱정일기를 통해 불안을 직면하는 방법과 회피하는 방법을 실습해보겠습니다. 작성하신 걱정일기의 내용을 살펴볼게요.',
      nextPageBuilder: () => const Week6AbcScreen(),
    );
  }
}
