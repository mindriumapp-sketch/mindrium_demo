import 'package:flutter/material.dart';
import 'package:gad_app_team/features/5th_treatment/week5_final_screen.dart';
import 'package:gad_app_team/widgets/top_btm_card.dart';
import 'package:gad_app_team/widgets/thought_card.dart';
import 'package:gad_app_team/widgets/detail_popup.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week5VisualScreen extends StatefulWidget {
  final List<String> previousChips;     // 불안을 회피하는 행동
  final List<String> alternativeChips;  // 불안을 직면하는 행동
  final List<Map<String, dynamic>>? quizResults; // 퀴즈 결과
  final int? correctCount; // 정답 개수

  const Week5VisualScreen({
    super.key,
    required this.previousChips,
    required this.alternativeChips,
    this.quizResults,
    this.correctCount,
  });

  @override
  State<Week5VisualScreen> createState() => _Week5VisualScreenState();
}

class _Week5VisualScreenState extends State<Week5VisualScreen> {
  late final ApiClient _client;
  late final UserDataApi _userDataApi;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _userDataApi = UserDataApi(_client);
  }

  Future<void> _saveSession() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      // 퀴즈 결과 변환
      Map<String, dynamic>? classificationQuiz;
      if (widget.quizResults != null && widget.quizResults!.isNotEmpty && widget.correctCount != null) {
        final wrongList = widget.quizResults!
            .where((item) => item['isCorrect'] == false)
            .map((item) => {
                  'text': item['text'],
                  'user_choice': item['userChoice'],
                  'correct_type': item['correctType'],
                })
            .toList();
        
        classificationQuiz = {
          'correct_count': widget.correctCount,
          'total_count': widget.quizResults!.length,
          'results': widget.quizResults!.map((r) => {
                'text': r['text'],
                'correct_type': r['correctType'],
                'user_choice': r['userChoice'],
                'is_correct': r['isCorrect'],
              }).toList(),
          'wrong_list': wrongList,
        };
      }

      await _userDataApi.createPracticeSession(
        weekNumber: 5,
        negativeItems: widget.previousChips,
        positiveItems: widget.alternativeChips,
        classificationQuiz: classificationQuiz,
      );
    } catch (e) {
      // 에러 발생 시에도 팝업은 표시
      debugPrint('세션 저장 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // 공통 팝업: 전체 칩 보여주기 (ThoughtBubble로)
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

  // 상단 패널: 불안을 회피하는 행동
  Widget _buildTopPanel() {
    return _buildThoughtSection(
      title: '불안을 회피하는 행동',
      chips: widget.previousChips,
      thoughtType: ThoughtType.unhelpful,
    );
  }

  // 하단 패널: 불안을 직면하는 행동
  Widget _buildBottomPanel() {
    return _buildThoughtSection(
      title: '불안을 직면하는 행동',
      chips: widget.alternativeChips,
      thoughtType: ThoughtType.helpful,
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
      appBarTitle: '5주차 - 불안 직면 VS 회피',
      topChild: _buildTopPanel(),
      bottomChild: _buildBottomPanel(),
      onBack: () => Navigator.pop(context),
      onNext: () async {
        await _saveSession();
        if (!mounted) return;
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week5FinalScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
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
