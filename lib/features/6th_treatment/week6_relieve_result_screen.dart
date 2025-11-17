import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'week6_relieve_slider_screen.dart';
import 'week6_behavior_classification_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ApplyDesign 위젯 import

class Week6RelieveResultScreen extends StatefulWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double sliderValue; // 슬라이더 값
  final bool isLongTerm; // 단기/장기 구분
  final double? shortTermValue; // 단기 슬라이더 값 (장기일 때만 사용)
  final List<String>? remainingBehaviors; // 남은 행동 목록
  final List<String> allBehaviorList; // 전체 행동 목록
  final List<Map<String, dynamic>>? mismatchedBehaviors; // 일치하지 않은 행동들

  const Week6RelieveResultScreen({
    super.key,
    required this.selectedBehavior,
    required this.behaviorType,
    required this.sliderValue,
    this.isLongTerm = false,
    this.shortTermValue,
    this.remainingBehaviors,
    required this.allBehaviorList,
    this.mismatchedBehaviors,
  });

  @override
  State<Week6RelieveResultScreen> createState() =>
      _Week6RelieveResultScreenState();
}

class _Week6RelieveResultScreenState extends State<Week6RelieveResultScreen> {
  bool _showMainText = true;

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 🎯 문장 구성 로직
    String mainText;
    String subText;
    bool isHighRelief = widget.sliderValue == 10;
    String timePeriod = widget.isLongTerm ? '장기' : '단기';

    if (widget.behaviorType == 'face') {
      if (isHighRelief) {
        mainText =
            '방금 보셨던 "${widget.selectedBehavior}"(이)라는 행동을 하게 되면\n$timePeriod적으로 불안이 많이 완화된다고 생각하시는군요.';
      } else {
        mainText =
            '방금 보셨던 "${widget.selectedBehavior}"(이)라는 행동을 하게 되면\n$timePeriod적으로 불안이 적게 완화된다고 생각하시는군요.';
      }
      subText =
          widget.isLongTerm
              ? '잘 따라오고 계십니다! 이제 위 행동이 어떤 유형에 속하는지 알아보겠습니다.'
              : '이번에는 위 행동이 장기적으로 얼마나 불안을 완화할 수 있는지 알아볼게요!';
    } else {
      if (isHighRelief) {
        mainText =
            '방금 보셨던 "${widget.selectedBehavior}"(이)라는 행동을 하게 되면\n$timePeriod적으로 불안이 많이 완화된다고 생각하시는군요.';
      } else {
        mainText =
            '방금 보셨던 "${widget.selectedBehavior}"(이)라는 행동을 하게 되면\n$timePeriod적으로 불안이 적게 완화된다고 생각하시는군요.';
      }
      subText =
          widget.isLongTerm
              ? '잘 따라오고 계십니다! 이제 위 행동이 어떤 유형에 속하는지 알아보겠습니다.'
              : '이번에는 위 행동이 장기적으로 얼마나 불안을 완화할 수 있는지 알아볼게요!';
    }

    // 🌊 ApplyDesign으로 전체 감싸기
    return ApplyDesign(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      cardTitle: '불안 완화 결과',
      onBack: () => Navigator.pop(context),
      onNext: () {
        if (_showMainText) {
          setState(() => _showMainText = false);
        } else {
          if (widget.isLongTerm && widget.shortTermValue != null) {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week6BehaviorClassificationScreen(
                      selectedBehavior: widget.selectedBehavior,
                      behaviorType: widget.behaviorType,
                      shortTermValue: widget.shortTermValue!,
                      longTermValue: widget.sliderValue,
                      remainingBehaviors: widget.remainingBehaviors,
                      allBehaviorList: widget.allBehaviorList,
                      mismatchedBehaviors: widget.mismatchedBehaviors,
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          } else {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week6RelieveSliderScreen(
                      selectedBehavior: widget.selectedBehavior,
                      behaviorType: widget.behaviorType,
                      isLongTerm: true,
                      shortTermValue: widget.sliderValue,
                      remainingBehaviors: widget.remainingBehaviors,
                      allBehaviorList: widget.allBehaviorList,
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        }
      },

      /// 💠 카드 안 내용 전달 (디자인 위젯 내부 child)
      child: buildRelieveResultCard(
        userName: userName,
        mainText: mainText,
        subText: subText,
        showMainText: _showMainText,
      ),
    );
  }
}
