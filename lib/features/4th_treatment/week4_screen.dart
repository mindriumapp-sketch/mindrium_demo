import 'package:flutter/material.dart';
import 'package:gad_app_team/features/value_start.dart';
import 'package:gad_app_team/features/4th_treatment/week4_abc_screen.dart';

class Week4Screen extends StatefulWidget {
  final int loopCount;

  const Week4Screen({super.key, this.loopCount = 1});

  @override
  State<Week4Screen> createState() => _Week4ScreenState();
}

class _Week4ScreenState extends State<Week4Screen> {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    final int? sud = args['sud'] as int?;

    return ValueStartScreen(
      weekNumber: 4,
      weekTitle: '인지 왜곡을 찾아보겠습니다.',
      weekDescription:
          '이번 주차에서는 걱정일기를 통해 부정적인 사고 패턴인 인지 왜곡을 찾아보겠습니다. 작성하신 걱정일기의 내용을 살펴볼게요.',
      nextPageBuilder:
          () => Week4AbcScreen(
            abcId: abcId,
            sud: sud,
            loopCount: widget.loopCount,
          ),
    );
  }
}
