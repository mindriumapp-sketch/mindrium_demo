// lib/features/6th_treatment/week6_visual_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/top_btm_card.dart';        // ✅ ApplyDoubleCard
import 'package:gad_app_team/widgets/thought_card.dart';        // ✅ ThoughtCard
import 'package:gad_app_team/widgets/custom_popup_design.dart'; // ✅ (팝업 UI)
import 'package:gad_app_team/utils/edu_progress.dart';

class Week6VisualScreen extends StatefulWidget {
  final List<String> previousChips;     // 불안을 회피하는 행동
  final List<String> alternativeChips;  // 불안을 직면하는 행동

  const Week6VisualScreen({
    super.key,
    required this.previousChips,
    required this.alternativeChips,
  });

  @override
  State<Week6VisualScreen> createState() => _Week6VisualScreenState();
}

class _Week6VisualScreenState extends State<Week6VisualScreen> {
  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomPopupDesign(
        title: '수고하셨습니다!',
        message: '오늘도 불안을 직면하고 회피하는 행동을 구분하는 실습을 마쳤어요!',
        positiveText: '홈으로 돌아가기',
        negativeText: null, // 단일 버튼
        onPositivePressed: () async {
          //await EduProgress.markWeekDone(6);
          // 1) 팝업 닫고
          Navigator.of(context, rootNavigator: true).pop();
          // 2) 홈으로 이동
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
        onNegativePressed: null,
        // backgroundAsset: null,
        // iconAsset: null,
      ),
    );
  }

  // 상단 패널: 불안을 회피하는 행동 (previousChips)
  Widget _buildTopPanel() {
    return ThoughtCard(
      title: '불안을 회피하는 행동',
      pills: widget.previousChips,
      thoughtType: ThoughtType.unhelpful, // ✅ 회피 = unhelpful
      titleSize: 18,
      titleWeight: FontWeight.w600,
    );
  }

  // 하단 패널: 불안을 직면하는 행동 (alternativeChips)
  Widget _buildBottomPanel() {
    return ThoughtCard(
      title: '불안을 직면하는 행동',
      pills: widget.alternativeChips,
      thoughtType: ThoughtType.helpful, // ✅ 직면 = helpful
      titleSize: 18,
      titleWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDoubleCard(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      topChild: _buildTopPanel(),
      bottomChild: _buildBottomPanel(),

      // ✅ Week5와 동일한 UX: 이전(뒤로가기) / 다음(완료 팝업)
      onBack: () => Navigator.pop(context),
      onNext: _showFinishDialog,

      // 스타일 옵션 (Week5와 동일)
      pagePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      panelsGap: 24,
      panelPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      panelRadius: 20,
      maxWidth: 980,
      topcardColor: Colors.white,
      btmcardColor: Colors.white,
    );
  }
}