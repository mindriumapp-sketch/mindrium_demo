// lib/features/5th_treatment/week5_confront_anxiety.dart

import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/chips_editor.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/5th_treatment/week5_visual_screen.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

// 👇 방금 썼던 더블 카드 레이아웃
import 'package:gad_app_team/widgets/top_btm_card.dart';

class Week5ConfrontAnxietyScreen extends StatefulWidget {
  final List<String> previousChips;

  const Week5ConfrontAnxietyScreen({
    super.key,
    required this.previousChips,
  });

  @override
  State<Week5ConfrontAnxietyScreen> createState() =>
      _Week5ConfrontAnxietyScreenState();
}

class _Week5ConfrontAnxietyScreenState
    extends State<Week5ConfrontAnxietyScreen> {
  final GlobalKey<ChipsEditorState> _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  // ───────── 상단 카드 내용 ─────────
  Widget _buildTopPanel() {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 4),
          Text(
            '다르게 생각해보기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263C69),
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            '불안을 직면하는 행동으로 생각해볼까요?',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w200,
              height: 1.45,
              color: Colors.black87,
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ───────── 하단 카드 내용 ─────────
  Widget _buildBottomPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipsEditor(
          key: _chipsKey,
          initial: const [],
          onChanged: _onChipsChanged,
          minHeight: 150,
          maxWidthFactor: 0.78,
          emptyIcon: const Icon(
            Icons.edit_note_rounded,
            size: 64,
            color: Colors.black45,
          ),
          emptyText: const Text(
            '여기에 입력한 내용이 표시됩니다',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
              fontFamily: 'Noto Sans KR',
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // ───────── 다음 화면 이동 (로직 그대로) ─────────
  void _goNext() {
    // 입력 중이면 확정
    _chipsKey.currentState?.unfocusAndCommit();
    final values = _chipsKey.currentState?.values ?? _chips;

    if (values.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week5VisualScreen(
          previousChips: widget.previousChips,
          alternativeChips: values,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDoubleCard(
      appBarTitle: '5주차 - 불안 직면 VS 회피',
      topChild: _buildTopPanel(),
      // 가운데 말풍선 텍스트만 여기서 던져주면 ApplyDoubleCard가 알아서 JellyfishNotice로 그려줌
      middleBannerText:
      '아래 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',
      panelsGap: 2,
      bottomChild: _buildBottomPanel(),
      onBack: () => Navigator.pop(context),
      onNext: _chips.isNotEmpty ? _goNext : null,
      // 필요하면 카드 색을 이렇게도 줄 수 있음
      btmcardColor: const Color(0xFF7DD9E8).withOpacity(0.25),
    );
  }
}
