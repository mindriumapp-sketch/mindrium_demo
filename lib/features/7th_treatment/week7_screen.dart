import 'package:flutter/material.dart';
import 'package:gad_app_team/features/value_start.dart';
import 'package:gad_app_team/features/7th_treatment/week7_add_display_screen.dart';

class Week7Screen extends StatelessWidget {
  const Week7Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueStartScreen(
      weekNumber: 7,
      weekTitle: '생활 습관을 개선해보겠습니다.',
      weekDescription:
          '이번 주차에서는 일상생활에서 \n불안을 관리할 수 있는 생활 습관을 개선해보겠습니다. \nTo do list를 통해 체계적으로 관리해보세요.',
      nextPageBuilder: () => const Week7AddDisplayScreen(),
    );
  }
}
