import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/top_btm_card.dart';
import 'package:gad_app_team/widgets/chips_editor.dart';
import 'week4_next_thought_screen.dart';

class Week4AnxietyScreen extends StatefulWidget {
  final List<String>? bList;
  final int beforeSud;
  final List<String>? existingAlternativeThoughts;
  final int loopCount;

  const Week4AnxietyScreen({
    super.key,
    this.bList,
    this.beforeSud = 0,
    this.existingAlternativeThoughts,
    this.loopCount = 1,
  });

  @override
  State<Week4AnxietyScreen> createState() => _Week4AnxietyScreenState();
}

class _Week4AnxietyScreenState extends State<Week4AnxietyScreen> {
  final _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _confirmed = [];

  void _onChanged(List<String> v) {
    setState(() => _confirmed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ApplyDoubleCard(
        appBarTitle: '4주차 - 인지 왜곡 찾기',
        onBack: () => Navigator.pop(context),
        onNext: _confirmed.isNotEmpty
            ? () {
          final current = _chipsKey.currentState?.values ?? _confirmed;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => Week4NextThoughtScreen(
                remainingBList: current,
                beforeSud: widget.beforeSud,
                allBList: [...?widget.bList, ...current],
                alternativeThoughts: null,
                isFromAnxietyScreen: true,
                addedAnxietyThoughts: current,
                existingAlternativeThoughts:
                widget.existingAlternativeThoughts ?? [],
                loopCount: widget.loopCount,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
            : null,

        // 레이아웃 옵션
        pagePadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
        panelsGap: 2,
        panelRadius: 20,
        panelPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),

        // 상단 패널
        topChild: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 35),
              Text(
                '앞선 상황과 관련해서 불안을 일으키는 \n또 다른 생각이 있으실까요?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF8796B8),
                  letterSpacing: 1.2,
                  fontFamily: 'Noto Sans KR',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Text(
                '또 다른 불안한 생각 적어보기',
                style: TextStyle(
                  fontSize: 20,
                  height: 1.35,
                  wordSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF263C69),
                  fontFamily: 'Noto Sans KR',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 35),
            ],
          ),
        ),

        middleBannerText: '입력 영역을 탭하면 항목이 추가돼요! \n엔터 또는 바깥 터치로 확정됩니다',

        // 하단 패널 (칩 편집 위젯 사용)
        bottomChild: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ChipsEditor(
                key: _chipsKey,
                initial: const [],            // 초기 칩 있으면 전달
                onChanged: _onChanged,        // 확정 칩 리스트 콜백
                minHeight: 150,
                maxWidthFactor: 0.78,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        btmcardColor: const Color(0xFF7DD9E8).withOpacity(0.35),
        // height: 120,
        // topPadding: 20,
      ),
    );
  }
}
