import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutor_design.dart'; // ✅ AbcActivateDesign == TutorDesign
import 'package:gad_app_team/features/2nd_treatment/abc_consequence_screen.dart';

/// 🌊 ABC 모델 - B단계 (Belief)
/// AbcActivateDesign (TutorDesign) 스타일 적용
class AbcBeliefScreen extends StatelessWidget {
  const AbcBeliefScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const descriptionText =
        "막 자전거에 올라타서 페달을 밟으려는 순간, 균형이 살짝 흔들렸고 "
        "‘넘어질 것 같아…’ 라는 생각이 들었어요.\n"
        "예전에 자전거 타다 넘어져서 다쳤던 기억이 갑자기 떠올랐고, "
        "그때의 아픔이 다시 느껴지는 것 같았어요.";

    return AbcActivateDesign(
      appBarTitle: '2주차 - ABC 모델',
      descriptionText: descriptionText,
      scenarioImage: 'assets/image/belief.png', // ✅ 이미지 복구
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AbcConsequenceScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
