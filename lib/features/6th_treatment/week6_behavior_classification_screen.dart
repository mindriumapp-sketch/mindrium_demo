import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/features/6th_treatment/week6_behavior_reflection_screen.dart';

/// 🌊 Mindrium 스타일 6주차 행동 분류 결과 화면
/// 기존 Scaffold/Card 구조 → ApplyDesign 통합 버전
class Week6BehaviorClassificationScreen extends StatelessWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double shortTermValue; // 단기 슬라이더 값
  final double longTermValue; // 장기 슬라이더 값
  final List<String>? remainingBehaviors; // 남은 행동 목록
  final List<String> allBehaviorList; // 전체 행동 목록
  final List<Map<String, dynamic>>? mismatchedBehaviors; // 일치하지 않은 행동들

  const Week6BehaviorClassificationScreen({
    super.key,
    required this.selectedBehavior,
    required this.behaviorType,
    required this.shortTermValue,
    required this.longTermValue,
    this.remainingBehaviors,
    required this.allBehaviorList,
    this.mismatchedBehaviors,
  });

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 🔹 분류 로직
    bool isShortTermHigh = shortTermValue == 10;
    bool isLongTermHigh = longTermValue == 10;

    String mainText;
    if (isShortTermHigh && !isLongTermHigh) {
      mainText =
          '$userName님께서는, \n방금 보셨던 "$selectedBehavior"(라)는 행동에 대해 단기적으로는 완화되지만 장기적으로는 완화되지 않는다고 해주셨습니다.\n\n이런 행동은 보통 불안을 회피하는 행동에 가깝기 때문에, 일시적으로는 불안이 완화되어 편안함을 주지만 지속 시 불안을 해결하는 데 큰 도움이 되지 않을 수 있어요!';
    } else if (!isShortTermHigh && isLongTermHigh) {
      mainText =
          '$userName님께서는, \n방금 보셨던 "$selectedBehavior"(라)는 행동에 대해 단기적으로는 완화되지 않지만 장기적으로는 많이 완화된다고 해주셨습니다.\n\n이런 행동은 보통 불안을 직면하는 행동에 가깝기 때문에, 일시적으로 불안이 높아져서 처음에는 어려울 수 있지만 지속 시 불안을 해결하는 데 도움이 될 수 있어요!';
    } else if (isShortTermHigh && isLongTermHigh) {
      mainText =
          '$userName님께서는, \n방금 보셨던 "$selectedBehavior"(라)는 행동에 대해 단기적으로도 장기적으로도 불안이 완화된다고 해주셨습니다.\n\n하지만 안전장치에 의존하다 보면 실제 불안을 줄이는데 도움이 안될 수 있습니다.\n왜냐하면 뇌는 여전히 그 장치 없이는 불안하다고 배우게 되기 때문입니다.\n\n안전장치를 계속 사용하면 일시적으로는 편안함을 느낄 수 있지만, 궁극적으로는 안전장치 없이도 불안을 관리할 수 있는 능력을 기를 기회를 놓치게 될 수 있어요.\n이 행동이 정말 장기적으로도 도움이 되는지 다시 한번 생각해보는 시간을 가져보면 어떨까요?';
    } else {
      mainText =
          '$userName님께서는, \n방금 보셨던 "$selectedBehavior"(라)는 행동에 대해 단기적으로도 장기적으로도 불안이 완화되지 않는다고 해주셨습니다.\n\n그만큼 불안이 줄어들 기회를 주지 못했을 수 있어요. 오히려 불안을 유지시키거나 더 키웠을 수도 있습니다.\n\n이런 행동보다는 보다 효과적인 불안 관리 방법을 찾아서, 실제로 불안을 감소시킬 수 있는 다른 행동으로 바꿔보는 것은 어떨까요?';
    }

    // 🌊 ApplyDesign 사용
    return Stack(
      children: [
        ApplyDesign(
          appBarTitle: '6주차 - 불안 직면 VS 회피',
          cardTitle: '행동 분류 결과',
          onBack: () => Navigator.pop(context),
          onNext: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week6BehaviorReflectionScreen(
                  selectedBehavior: selectedBehavior,
                  behaviorType: behaviorType,
                  shortTermValue: shortTermValue,
                  longTermValue: longTermValue,
                  remainingBehaviors: remainingBehaviors,
                  allBehaviorList: allBehaviorList,
                  mismatchedBehaviors: mismatchedBehaviors,
                ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },

          /// 💠 기능 영역 (child)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Text(
                mainText,
                style: const TextStyle(
                  fontFamily: 'Noto Sans KR',
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.6,
                ),
                textAlign: TextAlign.left,
              ),

              const SizedBox(height: 24),
              const Text(
                '이제 이 행동을 다시 돌아보며,\n내가 느꼈던 감정과 변화에 대해 성찰해볼까요?',
                style: TextStyle(
                  fontFamily: 'Noto Sans KR',
                  fontSize: 14,
                  color: Color(0xFF5E5E5E),
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        // Padding(padding: EdgeInsetsGeometry.fromSTEB(0, 480, 0, 10),
        //   child: JellyfishBanner(
        //     message: '이제 이 행동을 다시 돌아보며,\n내가 느꼈던 감정과 변화에 대해 성찰해볼까요?',
        //   ),
        // )
      ],
    );
  }
}
