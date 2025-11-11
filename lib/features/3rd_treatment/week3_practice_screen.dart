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
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week3ClassificationScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      /// 🧩 기능쪽에서만 본문 정의
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Icon(Icons.edit_note_rounded, size: 72, color: Color(0xFF3F51B5)),
          SizedBox(height: 32),
          Text(
            '방금 본 여성의 예시 상황에 몰입해 보면서\n'
            '도움이 되는 생각과 도움이 되지 않는 생각을 구분하는 연습을 해볼 거예요.',
            style: TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 18,
              height: 1.6,
              color: Color(0xFF333333),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
