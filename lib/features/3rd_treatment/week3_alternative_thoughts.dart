import 'package:flutter/material.dart';

import 'package:gad_app_team/widgets/top_btm_card.dart';        // ApplyDoubleCard, PanelHeader
import 'package:gad_app_team/widgets/chips_editor.dart';        // ✅ 칩 입력 위젯
import 'package:gad_app_team/features/3rd_treatment/week3_visual_screen.dart';

class Week3AlternativeThoughtsScreen extends StatefulWidget {
  final List<String> previousChips; // 앞 화면에서 넘어온 불안 문구들
  const Week3AlternativeThoughtsScreen({
    super.key,
    required this.previousChips,
  });

  @override
  State<Week3AlternativeThoughtsScreen> createState() =>
      _Week3AlternativeThoughtsScreenState();
}

class _Week3AlternativeThoughtsScreenState
    extends State<Week3AlternativeThoughtsScreen> {
  // ChipsEditor 제어용 Key
  final GlobalKey<ChipsEditorState> _chipsKey = GlobalKey<ChipsEditorState>();

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }
  List<String> _chips = [];

  // 상단 큰 이미지 카드
  Widget _buildTopCard(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PanelHeader(
          subtitle: '도움이 되는 생각으로 바꿔보세요 🌿',
          showDivider: false,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2962F6).withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/image/alternative thoughts.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                width: w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 하단 입력 패널
  Widget _buildBottomCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipsEditor(
          key: _chipsKey,
          initial: const [],      // 초기 칩이 있다면 전달
          onChanged: _onChipsChanged,
          minHeight: 150,
          maxWidthFactor: 0.78,
          emptyText: const Text(
            '여기에 입력한 내용이 표시됩니다',
            style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w400),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _goNext(BuildContext context) {
    // 혹시 편집 중이면 먼저 확정
    _chipsKey.currentState?.unfocusAndCommit();

    final values = _chipsKey.currentState?.values ?? const <String>[];
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week3VisualScreen(
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // 바깥 탭 → 편집칩 확정 + 포커스 해제
        _chipsKey.currentState?.unfocusAndCommit();
      },
      child: ApplyDoubleCard(
        appBarTitle: '3주차 - Self Talk',
        topChild: _buildTopCard(context),
        bottomChild: _buildBottomCard(context),
        middleNoticeText: '아래 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',
        onBack: () => Navigator.pop(context),
        onNext: () => _goNext(context),

        // 스타일 옵션
        pagePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        panelsGap: 24,
        panelPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        panelRadius: 18,
        maxWidth: 960,
        topcardColor: Colors.white.withOpacity(0.96),
        btmcardColor: const Color(0xFF7DD9E8).withOpacity(0.35),
      ),
    );
  }
}
