// lib/features/5th_treatment/week5_imagination_screen.dart

import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/chips_editor.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/5th_treatment/week5_confront_anxiety.dart';

// ⭐ 추가: 우리가 쓰려는 더블 카드 레이아웃
import 'package:gad_app_team/widgets/top_btm_card.dart'; // 경로는 너 프로젝트 구조에 맞춰줘

class Week5ImaginationScreen extends StatefulWidget {
  const Week5ImaginationScreen({super.key});

  @override
  State<Week5ImaginationScreen> createState() => _Week5ImaginationScreenState();
}

class _Week5ImaginationScreenState extends State<Week5ImaginationScreen> {
  // ▶ ChipsEditor 상태 & 값 (로직 유지)
  final GlobalKey<ChipsEditorState> _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  // ───────── 상단 흰 카드 내용 ─────────
  Widget _buildTopPanel() {
    return SizedBox(
      height: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          SizedBox(height: 4),
          Text(
            '불안하면 어떤 행동을 할까요?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263C69),
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 14),
          Text(
            '불안할 때 보통 어떤 행동을 하는지 자유롭게 적어보세요.',
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

  // ───────── 다음 화면 이동 (로직 그대로 유지) ─────────
  void _goNext() {
    _chipsKey.currentState?.unfocusAndCommit();
    final values = _chipsKey.currentState?.values ?? _chips;

    if (values.isEmpty) return;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) => Week5ConfrontAnxietyScreen(previousChips: values),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDoubleCard(
      appBarTitle: '5주차 - 불안 직면 VS 회피',
      // 위쪽 카드
      topChild: _buildTopPanel(),
      // 가운데 해파리 말풍선 대신 이 텍스트로 출력
      middleBannerText: '아래 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',
      panelsGap: 2,
      // 아래쪽 카드
      bottomChild: _buildBottomPanel(),
      // 네비게이션
      onBack: () => Navigator.pop(context),
      onNext: _chips.isNotEmpty ? _goNext : null,
      // 필요하면 색/패딩도 여기서 바꿀 수 있음
      // topcardColor: Colors.white,
      btmcardColor: const Color(0xFF7DD9E8).withOpacity(0.25),
    );
  }
}
