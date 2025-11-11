// File: week5_practice_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/features/5th_treatment/week5_classification_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ✅ ApplyDesign 사용

class Week5PracticeScreen extends StatelessWidget {
  const Week5PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '5주차 - 불안 직면 VS 회피',
      cardTitle: '한번 연습해볼까요?',
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week5ClassificationScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      /// 💬 카드 내부 내용
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12,),
          Text(
            '방금 본 여성의 예시 상황에 몰입해 보면서\n'
            '불안을 직면하는 행동(불안을 점차 감소시킬 수 있는 행동)과\n'
            '불안을 회피하는 행동(지속 시 불안을 증가시킬 수 있는 행동)을\n'
            '구분하는 연습을 해볼 거예요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF232323),
              fontFamily: 'Noto Sans KR',
            ),
          ),
          SizedBox(height: 12),

          // 💧 감정 포인트 시각 보조선
          Divider(
            height: 32,
            thickness: 1.2,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFE0E7F1),
          ),

          Text(
            '이제 불안에 대한 반응을 \n구체적으로 살펴볼까요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3D4C6C),
              fontFamily: 'Noto Sans KR',
            ),
          ),
        ],
      ),
    );
  }
}
