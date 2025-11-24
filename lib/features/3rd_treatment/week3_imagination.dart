// lib/features/3rd_treatment/week3_imagination.dart

import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/chips_editor.dart';
import 'week3_explain_alternative_thoughts.dart';

// ⭐ 우리가 방금 쓰기로 한 더블 카드 레이아웃
import 'package:gad_app_team/widgets/top_btm_card.dart';

class Week3ImaginationScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? quizResults;
  final int? correctCount;

  const Week3ImaginationScreen({
    super.key,
    this.quizResults,
    this.correctCount,
  });

  @override
  State<Week3ImaginationScreen> createState() =>
      _Week3ImaginationScreenState();
}

class _Week3ImaginationScreenState extends State<Week3ImaginationScreen> {
  final GlobalKey<ChipsEditorState> _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  // ───────── 상단 카드 내용 ─────────
  Widget _buildTopPanel() {
    return SizedBox(
      height: 150, // 5주차 화면과 높이 맞춰서 정사이즈
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(
            '불안하면 어떤 일이 일어날까요?',
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
            '불안할 때 떠오르는 최악의 상황이나\n걱정되는 장면을 솔직하게 적어보세요.',
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

  // ───────── 다음 화면 이동 (백엔드/로직 유지) ─────────
  void _goNext() {
    _chipsKey.currentState?.unfocusAndCommit();
    final values = _chipsKey.currentState?.values ?? _chips;

    // ✅ 입력된 칩이 없으면 넘어가지 않도록 안전장치
    if (values.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week3ExplainAlternativeThoughtsScreen(
          chips: values,
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
      // 가운데 말풍선 텍스트
      middleBannerText:
      '아래 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',
      bottomChild: _buildBottomPanel(),
      onBack: () => Navigator.pop(context),

      // ✅ 칩이 없으면 onNext를 null로 넘겨서 버튼 비활성화
      onNext: _chips.isNotEmpty ? _goNext : null,

      // 3주차 원래 하단 민트 느낌
      btmcardColor: const Color(0xFF7DD9E8).withValues(alpha: 0.25),
    );
  }
}
