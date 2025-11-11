import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'week6_classfication_screen.dart';
import 'week6_finish_quiz_screen.dart';

class Week6BehaviorReflectionScreen extends StatefulWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double shortTermValue;
  final double longTermValue;
  final List<String>? remainingBehaviors;
  final List<String> allBehaviorList;
  final List<Map<String, dynamic>>? mismatchedBehaviors;

  const Week6BehaviorReflectionScreen({
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
  State<Week6BehaviorReflectionScreen> createState() =>
      _Week6BehaviorReflectionScreenState();
}

class _Week6BehaviorReflectionScreenState
    extends State<Week6BehaviorReflectionScreen> {
  bool _showMainText = true;
  late List<Map<String, dynamic>> _mismatchedBehaviors;

  @override
  void initState() {
    super.initState();
    _mismatchedBehaviors = List.from(widget.mismatchedBehaviors ?? []);

    // 실제 결과 계산
    bool isShortTermHigh = widget.shortTermValue == 10;
    bool isLongTermHigh = widget.longTermValue == 10;

    String actualResult;
    if (isShortTermHigh && !isLongTermHigh) {
      actualResult = '불안을 회피하는 행동';
    } else if (!isShortTermHigh && isLongTermHigh) {
      actualResult = '불안을 직면하는 행동';
    } else {
      actualResult = '중립적인 행동';
    }

    String userChoice =
        widget.behaviorType == 'face' ? '불안을 직면하는 행동' : '불안을 회피하는 행동';

    if (userChoice != actualResult) {
      _mismatchedBehaviors.insert(0, {
        'behavior': widget.selectedBehavior,
        'userChoice': userChoice,
        'actualResult': actualResult,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 슬라이더 값 기반 실제 결과
    bool isShortTermHigh = widget.shortTermValue == 10;
    bool isLongTermHigh = widget.longTermValue == 10;

    String actualResult;
    if (isShortTermHigh && !isLongTermHigh) {
      actualResult = '불안을 회피하는 행동';
    } else if (!isShortTermHigh && isLongTermHigh) {
      actualResult = '불안을 직면하는 행동';
    } else {
      actualResult = '중립적인 행동';
    }

    String userChoice =
        widget.behaviorType == 'face' ? '불안을 직면하는 행동' : '불안을 회피하는 행동';

    // 메인 문장
    String mainText;
    if (widget.behaviorType == 'avoid' && isShortTermHigh && !isLongTermHigh) {
      mainText =
          '방금 보셨던 "${widget.selectedBehavior}"(라)는 행동을 불안을 회피하는 행동으로 선택하셨는데, 실제로 이 행동은 불안을 회피하는 쪽에 가까워 보이네요.';
    } else if (widget.behaviorType == 'avoid' &&
        !isShortTermHigh &&
        isLongTermHigh) {
      mainText =
          '방금 보셨던 "${widget.selectedBehavior}"(라)는 행동을 불안을 회피하는 행동으로 선택하셨지만, 실제로는 불안을 직면하는 쪽에 가까워 보이네요.';
    } else if (widget.behaviorType == 'face' &&
        !isShortTermHigh &&
        isLongTermHigh) {
      mainText =
          '방금 보셨던 "${widget.selectedBehavior}"(라)는 행동을 불안을 직면하는 행동으로 선택하셨는데, 실제로 이 행동은 불안을 직면하는 쪽에 가까워 보이네요.';
    } else if (widget.behaviorType == 'face' &&
        isShortTermHigh &&
        !isLongTermHigh) {
      mainText =
          '방금 보셨던 "${widget.selectedBehavior}"(라)는 행동을 불안을 직면하는 행동으로 선택하셨지만, 실제로는 불안을 회피하는 쪽에 가까워 보이네요.';
    } else {
      mainText =
          '방금 보셨던 "${widget.selectedBehavior}"(라)는 행동을 불안을 $userChoice이라고 선택하셨네요.';
    }

    String subText = '이 행동이 과연 나에게 도움이 되는지 다시 한번 더 생각해보아요!';
    String? nextText;

    if (!_showMainText) {
      if (widget.remainingBehaviors != null &&
          widget.remainingBehaviors!.isNotEmpty) {
        nextText = '다음 행동도 계속 진행하겠습니다!';
      } else {
        nextText = '마지막 행동까지 완료했습니다! \n이제 마무리로 모든 행동들을 다시 한번 점검해볼까요?';
      }
    }

    return ApplyDesign(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      cardTitle: '행동 돌아보기',
      onBack: () => Navigator.pop(context),
      onNext: () {
        if (_showMainText) {
          setState(() => _showMainText = false);
        } else {
          if (widget.remainingBehaviors != null &&
              widget.remainingBehaviors!.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week6ClassificationScreen(
                      behaviorListInput: widget.remainingBehaviors!,
                      allBehaviorList: widget.allBehaviorList,
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week6FinishQuizScreen(
                      mismatchedBehaviors: _mismatchedBehaviors,
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        }
      },

      /// 💡 기능만 남긴 child
      child: buildRelieveResultCard(
        userName: userName,
        mainText: _showMainText ? mainText : nextText ?? subText,
        subText: subText,
        showMainText: _showMainText,
      ),
    );
  }
}
