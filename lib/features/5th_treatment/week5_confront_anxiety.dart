// lib/features/5th_treatment/week5_confront_anxiety.dart
import 'package:flutter/material.dart';

// ✅ 공용 레이아웃 & 칩 에디터
import 'package:gad_app_team/widgets/top_btm_card.dart';   // ApplyDoubleCard
import 'package:gad_app_team/widgets/chips_editor.dart';   // ChipsEditor

// 다음 화면 (기존 로직 유지)
import 'week5_visual_screen.dart';

class Week5ConfrontAnxietyScreen extends StatefulWidget {
  final List<String> previousChips;
  final List<Map<String, dynamic>>? quizResults;
  final int? correctCount;

  const Week5ConfrontAnxietyScreen({
    super.key,
    required this.previousChips,
    this.quizResults,
    this.correctCount,
  });
  static double cardWidth = 200;

  @override
  State<Week5ConfrontAnxietyScreen> createState() =>
      _Week5ConfrontAnxietyScreenState();
}

class _Week5ConfrontAnxietyScreenState
    extends State<Week5ConfrontAnxietyScreen> {
  // ▶ ChipsEditor 상태 & 값
  final _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  // ─────────────────── 상단 패널 ───────────────────
  Widget _buildTopPanel() {
    return Container(
      width: 700,
      height: 123,
      color: Colors.transparent,
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            '다르게 생각해보기',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263C69),
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ─────────────────── 하단 패널 ───────────────────
  Widget _buildBottomPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipsEditor(
          key: _chipsKey,
          initial: const [],          // 초기 칩이 있다면 전달
          onChanged: _onChipsChanged, // 변경 콜백
          minHeight: 150,
          maxWidthFactor: 0.78,
          emptyIcon: const Icon(
            Icons.edit_note_rounded,
            size: 64,
            color: Colors.black45,
          ),
          emptyText: const Text(
            '여기에 입력한 내용이 표시됩니다',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ApplyDoubleCard(
        appBarTitle: '5주차 - 불안 직면 VS 회피',

        // ◀◀ 뒤로/다음 (기존 흐름 유지)
        onBack: () => Navigator.pop(context),
        onNext: () {
          final values = _chipsKey.currentState?.values ?? _chips;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => Week5VisualScreen(
                previousChips: widget.previousChips,
                alternativeChips: values,
                quizResults: widget.quizResults,
                correctCount: widget.correctCount,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        },

        // 레이아웃 옵션
        pagePadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
        panelsGap: 16,
        panelRadius: 20,
        panelPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        maxWidth: 980,

        // 패널 사이 말풍선(안내)
        middleNoticeText: '아래 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',

        // 패널 색상(하단은 은은한 톤으로 입력영역 강조)
        topcardColor: Colors.white.withOpacity(0.96),
        btmcardColor: const Color(0xFF7DD9E8).withOpacity(0.35),

        // 실제 패널들
        topChild: _buildTopPanel(),
        bottomChild: _buildBottomPanel(),
      ),
    );
  }
}
