import 'package:flutter/material.dart';

// ✅ 공용 카드 레이아웃
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ApplyDesign

import 'week4_finish_screen.dart';
import 'week4_skip_choice_screen.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/sud_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week4AfterSudScreen extends StatefulWidget {
  final int beforeSud;
  final String currentB;
  final List<String> remainingBList;
  final List<String> allBList;
  final List<String> alternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String> originalBList;
  final int loopCount;
  final String? abcId;

  const Week4AfterSudScreen({
    super.key,
    required this.beforeSud,
    required this.currentB,
    required this.remainingBList,
    required this.allBList,
    required this.alternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.originalBList = const [],
    this.loopCount = 1,
    this.abcId,
  });

  @override
  State<Week4AfterSudScreen> createState() => _Week4AfterSudScreenState();
}

class _Week4AfterSudScreenState extends State<Week4AfterSudScreen> {
  int _sud = 5;
  List<String> _allAlternativeThoughts = [];
  late final ApiClient _client;
  late final SudApi _sudApi;
  String? _diaryIdFromRoute;
  bool _didReadArgs = false;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _sudApi = SudApi(_client);
    _collectAllAlternativeThoughts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadArgs) return;
    _didReadArgs = true;
    _diaryIdFromRoute = widget.abcId;
    if (_diaryIdFromRoute == null || _diaryIdFromRoute!.isEmpty) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _diaryIdFromRoute = args?['abcId'] as String?;
    }
  }

  Future<void> _collectAllAlternativeThoughts() async {
    final unique = <String>[];
    for (final t in widget.alternativeThoughts) {
      if (!unique.contains(t)) unique.add(t);
    }
    if (!mounted) return;
    setState(() {
      _allAlternativeThoughts = unique;
    });
  }

  void _handleNext() {
    // SUD(after) 저장: 기존 엔트리(before만 있는 최신)를 찾아 업데이트
    final id = _diaryIdFromRoute;
    if (id != null && id.isNotEmpty) {
      _sudApi
          .listSudScores(id)
          .then((list) async {
            // after_sud가 null인 가장 최신 항목 선택
            Map<String, dynamic>? target;
            for (final e in list.reversed) {
              final m = e as Map<String, dynamic>;
              if ((m['after_sud'] == null) || (m['after_sud']?.toString().isEmpty ?? true)) {
                target = m;
                break;
              }
            }
            if (target != null && target['sud_id'] != null) {
              await _sudApi.updateSudScore(
                diaryId: id,
                sudId: target['sud_id'].toString(),
                afterScore: _sud,
              );
            } else {
              // 안전장치: 없으면 새로 생성(두 값 모두)
              await _sudApi.createSudScore(
                diaryId: id,
                beforeScore: widget.beforeSud,
                afterScore: _sud,
              );
            }
          })
          .catchError((_) {});
    }

    if (_sud < widget.beforeSud) {
      // 낮아짐 → 종료 화면
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => Week4FinishScreen(
            beforeSud: widget.beforeSud,
            afterSud: _sud,
            alternativeThoughts: _allAlternativeThoughts,
            isFromAfterSud: true,
            loopCount: widget.loopCount,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      // 낮아지지 않음 → 스킵/다시 시도 화면
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => Week4SkipChoiceScreen(
            allBList: widget.allBList,
            beforeSud: widget.beforeSud,
            remainingBList: widget.remainingBList,
            isFromAfterSud: true,
            existingAlternativeThoughts: _allAlternativeThoughts,
            loopCount: widget.loopCount,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  // 점수에 따른 컬러 (Before 화면과 동일 톤)
  Color get _trackColor =>
      _sud <= 2 ? Colors.green : (_sud >= 8 ? Colors.red : Colors.amber);

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '4주차 - SUD 평가 (after)',
      cardTitle: '지금 느끼는 불안 정도를\n선택해 주세요',
      onBack: () => Navigator.pop(context),
      onNext: _handleNext,

      // ===== 카드 내부 UI (Before와 동일 스타일) =====
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 점수
          Text(
            '$_sud',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: _trackColor,
            ),
          ),
          const SizedBox(height: 8),

          // 얼굴 아이콘
          Icon(
            _sud <= 2
                ? Icons.sentiment_very_satisfied
                : _sud >= 8
                ? Icons.sentiment_very_dissatisfied_sharp
                : Icons.sentiment_neutral,
            size: 120,
            color: _trackColor,
          ),
          const SizedBox(height: 20),

          // 슬라이더
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 2,
                pressedElevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              activeTrackColor: _trackColor,
              inactiveTrackColor: _trackColor.withOpacity(0.25),
              thumbColor: _trackColor,
              overlayColor: _trackColor.withOpacity(0.18),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: _sud.toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              label: '$_sud',
              onChanged: (v) => setState(() => _sud = v.round()),
            ),
          ),

          // 0 / 10 표시
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Text('0', style: TextStyle(color: Colors.black54)),
                Spacer(),
                Text('10', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 범례
          const Row(
            children: [
              SizedBox(width: 12),
              Text('평온'),
              Spacer(),
              Text('보통'),
              Spacer(),
              Text('불안'),
              SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}
