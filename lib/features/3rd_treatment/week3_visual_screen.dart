// lib/features/3rd_treatment/week3_visual_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/top_btm_card.dart';        // ApplyDoubleCard
import 'package:gad_app_team/widgets/custom_popup_design.dart'; // 완료 팝업
import 'package:gad_app_team/widgets/thought_card.dart';        // ThoughtCard / ThoughtType
import 'package:gad_app_team/widgets/detail_popup.dart';        // 자세히 보기 팝업

class Week3VisualScreen extends StatefulWidget {
  final List<String> previousChips;    // 도움이 되지 않는 생각
  final List<String> alternativeChips; // 도움이 되는 생각

  const Week3VisualScreen({
    super.key,
    required this.previousChips,
    required this.alternativeChips,
  });

  @override
  State<Week3VisualScreen> createState() => _Week3VisualScreenState();
}

class _Week3VisualScreenState extends State<Week3VisualScreen> {
  void _showFinishDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomPopupDesign(
          title: '수고하셨습니다!',
          message: '오늘도 자기이해와 긍정적 자기대화를 \n실천했어요.',
          positiveText: '홈으로 돌아가기',
          negativeText: null,
          onNegativePressed: null,
          onPositivePressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/home', (route) => false);
          },
        );
      },
    );
  }

  // 공통: 전체 칩 자세히 보기
  void _showChipsPopup({
    required String title,
    required List<String> chips,
    required ThoughtType thoughtType,
  }) {
    showDialog(
      context: context,
      builder: (_) => DetailPopup(
        title: title,
        positiveText: '돌아가기',
        negativeText: null,
        onPositivePressed: () => Navigator.pop(context),
        child: chips.isEmpty
            ? const Text(
          '입력된 항목이 없어요.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.5,
            color: Color(0xFF356D91),
          ),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: chips.map((text) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ThoughtBubble(
                text: text,
                type: thoughtType,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // 상단 패널: 도움이 되는 생각
  Widget _buildTopPanel() {
    return _buildThoughtSection(
      title: '도움이 되는 생각',
      chips: widget.alternativeChips,
      thoughtType: ThoughtType.helpful,
    );
  }

  // 하단 패널: 도움이 되지 않는 생각
  Widget _buildBottomPanel() {
    return _buildThoughtSection(
      title: '도움이 되지 않는 생각',
      chips: widget.previousChips,
      thoughtType: ThoughtType.unhelpful,
    );
  }

  /// chips가 3개 초과일 때는 3개만 보여주고 '자세히 보기'
  Widget _buildThoughtSection({
    required String title,
    required List<String> chips,
    required ThoughtType thoughtType,
  }) {
    final bool needMore = chips.length > 3;
    final List<String> preview = needMore ? chips.sublist(0, 3) : chips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ThoughtCard(
          title: title,
          pills: preview,
          thoughtType: thoughtType,
          titleSize: 18,
          titleWeight: FontWeight.w600,
        ),
        if (needMore) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => _showChipsPopup(
                title: title,
                chips: chips,
                thoughtType: thoughtType,
              ),
              child: const Text(
                '자세히 보기',
                style: TextStyle(
                  color: Color(0xFF626262),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDoubleCard(
      appBarTitle: '3주차 - Self Talk',
      topChild: _buildTopPanel(),
      bottomChild: _buildBottomPanel(),
      onBack: () => Navigator.pop(context),
      onNext: _showFinishDialog,
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
