import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/top_btm_card.dart';        // ApplyDoubleCard, PanelHeader
import 'package:gad_app_team/widgets/chips_editor.dart';        // 칩 입력 위젯
import 'package:gad_app_team/features/3rd_treatment/week3_explain_alternative_thoughts.dart';

/// 🌊 3주차 - Self Talk (상상하기 단계)
class Week3GuideScreen extends StatefulWidget {
  const Week3GuideScreen({super.key});

  @override
  State<Week3GuideScreen> createState() => _Week3GuideScreenState();
}

class _Week3GuideScreenState extends State<Week3GuideScreen> {
  // ChipsEditor 제어용 Key
  final GlobalKey<ChipsEditorState> _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  // 상단 큰 이미지 카드 (imagination.png 로 변경)
  Widget _buildTopCard(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PanelHeader(
          subtitle: '불안하면 어떤 일이 일어날까요? ✨',
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
                'assets/image/imagination.png',   // ✅ 여기만 바뀜
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

  // 하단 입력 패널 (팝업 없이 바로 칩 입력)
  Widget _buildBottomCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChipsEditor(
          key: _chipsKey,
          initial: const [],
          onChanged: _onChipsChanged,
          minHeight: 150,
          maxWidthFactor: 0.78,
          emptyText: const Text(
            '여기에 입력한 내용이 표시됩니다',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey,
              fontWeight: FontWeight.w400,
            ),
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
        pageBuilder: (_, __, ___) =>
            Week3ExplainAlternativeThoughtsScreen(chips: values),
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

        // 스타일 옵션 (위 코드와 동일하게)
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
