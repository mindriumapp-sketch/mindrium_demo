import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_classification_screen.dart';

class Week3PracticeScreen extends StatelessWidget {
  const Week3PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '3주차 - Self Talk',
      cardTitle: '한번 연습해볼까요?',
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week3ClassificationScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      /// 💬 카드 내부 내용 (Week5 형식 참고)
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 12),
          Text(
            '방금 본 여성의 예시 상황에 몰입해 보면서\n'
                '도움이 되는 생각과\n'
                '도움이 되지 않는 생각을\n'
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
            '이제 생각의 방향을\n구체적으로 살펴볼까요?',
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
