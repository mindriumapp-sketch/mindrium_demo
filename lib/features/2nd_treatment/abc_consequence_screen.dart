import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutor_design.dart'; // ✅ 방금 주신 디자인 파일
import 'package:gad_app_team/features/2nd_treatment/abc_practice_screen.dart';

/// 🌊 5주차 - 불안 직면 VS 회피 (AbcActivateDesign 적용)
class AbcConsequenceScreen extends StatelessWidget {
  const AbcConsequenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AbcActivateDesign(
      appBarTitle: '2주차 - ABC 모델',
      scenarioImage: 'assets/image/consequence.png', // ✅ 시각 자료 (원하시는 걸로 교체 가능)
      descriptionText:
          '걱정이 많아지면서 신체적으로도 여러 증상이 나타났습니다.\n'
          '평소에는 느끼지 못했던 어깨와 목의 뻐근함이 거의 매일 지속되고,\n'
          '마치 온몸에 힘이 들어간 것처럼 긴장된 상태가 계속됩니다.',

      /// 🔙 뒤로가기
      onBack: () => Navigator.pop(context),

      /// ⏭ 다음 페이지 이동
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AbcPracticeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
