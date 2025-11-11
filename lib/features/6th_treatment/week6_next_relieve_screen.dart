import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ApplyDesign, buildRelieveResultCard
import 'week6_relieve_slider_screen.dart';

/// 🌊 Mindrium 스타일 6주차 - 불안 완화 단계 (다음 단계 안내)
class Week6NextRelieveScreen extends StatefulWidget {
  final String selectedBehavior;
  final String behaviorType; // 'face' 또는 'avoid'
  final double sliderValue;
  final List<String>? remainingBehaviors;
  final List<String> allBehaviorList;

  const Week6NextRelieveScreen({
    super.key,
    required this.selectedBehavior,
    required this.behaviorType,
    required this.sliderValue,
    this.remainingBehaviors,
    required this.allBehaviorList,
  });

  @override
  State<Week6NextRelieveScreen> createState() => _Week6NextRelieveScreenState();
}

class _Week6NextRelieveScreenState extends State<Week6NextRelieveScreen> {
  bool _showMainText = true;

  // ✅ 노란 하이라이트 박스
  Widget _highlightedText(String text) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF59D).withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  static const TextStyle _bodyStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
    height: 1.6,
    letterSpacing: 0.1,
    fontFamily: 'Noto Sans KR',
  );

  /// ✅ 메인 문장 (하이라이트 포함)
  Widget _buildMainRichLine({required bool isFace}) {
    final String highlight = isFace ? '직면하는 행동' : '회피하는 행동';
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: _bodyStyle,
        children: [
          TextSpan(
            text: '방금 보셨던 "${widget.selectedBehavior}"(이)라는 행동을\n불안을 ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _highlightedText(highlight),
          ),
          const TextSpan(text: '이라고 선택하셨네요.'),
        ],
      ),
    );
  }

  /// ✅ buildRelieveResultCard와 동일 톤의 래퍼(부분 하이라이트용)
  /// - 상단 이름/구분선
  /// - AnimatedSwitcher(메인: RichText 하이라이트 / 서브: 일반 텍스트)
  /// - 하단 아이콘
  Widget _relieveResultCardRich({
    required String userName,
    required bool showMainText,
    required Widget mainRich,
    required String subText,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 🧜 이름 표시 (원본 함수와 동일)
        Text(
          '$userName님',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5B3EFF),
            fontFamily: 'Noto Sans KR',
          ),
        ),
        const SizedBox(height: 20),

        // 💠 포인트 구분선 (원본 함수와 동일)
        Container(
          width: 48,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF5B3EFF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 40),

        // ✨ 전환되는 안내문 (여기만 RichText 지원)
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: showMainText
              ? KeyedSubtree(
            key: const ValueKey('mainRich'),
            child: mainRich,
          )
              : Text(
            subText,
            key: const ValueKey('subText'),
            style: _bodyStyle,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 서브 문장(일반 텍스트)
    const String subText = '그 행동이 단기적으로 불안을 얼마나 완화할 수 있을지 함께 살펴볼게요.';

    return ApplyDesign(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      cardTitle: '불안 완화 단계',
      onBack: () => Navigator.pop(context),
      onNext: () {
        if (_showMainText) {
          setState(() => _showMainText = false);
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => Week6RelieveSliderScreen(
                selectedBehavior: widget.selectedBehavior,
                behaviorType: widget.behaviorType,
                remainingBehaviors: widget.remainingBehaviors,
                allBehaviorList: widget.allBehaviorList,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      },

      /// 💠 카드 본문
      child: _relieveResultCardRich(
        userName: userName,
        showMainText: _showMainText,
        mainRich: _buildMainRichLine(isFace: widget.behaviorType == 'face'),
        subText: subText,
      ),
    );
  }
}
