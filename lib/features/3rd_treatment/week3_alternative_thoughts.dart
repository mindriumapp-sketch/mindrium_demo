// lib/features/3rd_treatment/week3_alternative_thoughts.dart

import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/chips_editor.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_visual_screen.dart';

// ⭐ 5주차에서 썼던 더블 카드 레이아웃
import 'package:gad_app_team/widgets/top_btm_card.dart';

class Week3AlternativeThoughtsScreen extends StatefulWidget {
  final List<String> previousChips;
  final List<Map<String, dynamic>>? quizResults;
  final int? correctCount;

  const Week3AlternativeThoughtsScreen({
    super.key,
    required this.previousChips,
    this.quizResults,
    this.correctCount,
  });

  @override
  State<Week3AlternativeThoughtsScreen> createState() =>
      _Week3AlternativeThoughtsScreenState();
}

class _Week3AlternativeThoughtsScreenState
    extends State<Week3AlternativeThoughtsScreen> {
  final GlobalKey<ChipsEditorState> _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  // ───────── 상단 카드 내용 ─────────
  Widget _buildTopPanel() {
    return SizedBox(
      height: 150, // 위쪽 카드 높이 통일
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            '도움이 되는 생각으로 바꿔보세요',
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
            '앞에서 떠올린 불안한 생각들을 기반으로,\n도움이 되는 생각을 자유롭게 적어보세요.',
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
    _chipsKey.currentState?.unfocusAndCommit();
    final values = _chipsKey.currentState?.values ?? _chips;

    // ✅ 이번 화면도 아무것도 안 적었으면 넘어가지 않게
    if (values.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week3VisualScreen(
          previousChips: widget.previousChips,
          alternativeChips: values,
          quizResults: widget.quizResults,
          correctCount: widget.correctCount,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDoubleCard(
      appBarTitle: '3주차 - Self Talk',
      topChild: _buildTopPanel(),
      middleBannerText:
      '아래 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',
      bottomChild: _buildBottomPanel(),
      onBack: () => Navigator.pop(context),

      // ✅ 칩이 없으면 다음 버튼 비활성화
      onNext: _chips.isNotEmpty ? _goNext : null,

      // 3주차 느낌 맞춰서 하단 패널만 살짝 민트
      btmcardColor: const Color(0xFF7DD9E8).withValues(alpha: 0.25),
    );
  }
}
