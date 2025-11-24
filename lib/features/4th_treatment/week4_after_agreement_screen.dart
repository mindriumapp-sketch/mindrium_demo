// lib/features/4th_treatment/week4_after_agreement_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/widgets/top_btm_card.dart'; // ✅ 두 패널 레이아웃
import 'package:gad_app_team/data/user_provider.dart'; // 사용자 이름
import 'week4_after_sud_screen.dart';
import 'week4_next_thought_screen.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week4AfterAgreementScreen extends StatefulWidget {
  final String previousB;
  final int beforeSud;
  final List<String> remainingBList;
  final List<String> allBList;
  final List<String> alternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String> originalBList;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;
  final int loopCount;

  const Week4AfterAgreementScreen({
    super.key,
    required this.previousB,
    required this.beforeSud,
    required this.remainingBList,
    required this.allBList,
    required this.alternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.originalBList = const [],
    this.existingAlternativeThoughts,
    this.abcId,
    this.loopCount = 1,
  });

  @override
  State<Week4AfterAgreementScreen> createState() =>
      _Week4AfterAgreementScreenState();
}

class _Week4AfterAgreementScreenState extends State<Week4AfterAgreementScreen> {
  double _sliderValue = 5.0;
  late String _currentB;
  late final ApiClient _client;
  late final DiariesApi _diariesApi;

  @override
  void initState() {
    super.initState();
    _currentB = widget.previousB;
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
  }

  // 점수에 따른 컬러 (Week4ClassificationScreen 스타일)
  Color get _trackColor =>
      _sliderValue <= 2
          ? Colors.green
          : (_sliderValue >= 8 ? Colors.red : Colors.amber);

  List<String> _removeDuplicates(List<String> list) {
    final uniqueList = <String>[];
    for (final item in list) {
      if (!uniqueList.contains(item)) uniqueList.add(item);
    }
    return uniqueList;
  }

  // ────────────── Top 패널 UI ──────────────
  Widget _buildTopPanel() {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 35),
        Text(
          '$userName님께서 걱정일기에 작성하신 생각을 \n보며 진행해주세요.',
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
          (_currentB.isNotEmpty) ? _currentB : '생각이 없습니다.',
          style: TextStyle(
            fontSize: 20,
            height: 1.35,
            wordSpacing: 1.4,
            fontWeight: FontWeight.w800,
            fontFamily: 'Noto Sans KR',
            color: Color(0xFF263C69),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 35),
        // PanelHeader(
        //   icon: Image.asset('assets/image/question_icon.png',
        //       width: 32, height: 32),
        //   subtitle: '$userName님께서 걱정일기에 작성하신 생각을 \n보며 진행해주세요.',
        // ),
        // const SizedBox(height: 8),
        // Text(
        //   (_currentB.isNotEmpty) ? _currentB : '생각이 없습니다.',
        //   style: const TextStyle(
        //     fontSize: 20,
        //     color: Colors.black,
        //     fontWeight: FontWeight.w500,
        //     wordSpacing: 1.2,
        //   ),
        //   textAlign: TextAlign.center,
        // ),
        // const SizedBox(height: 15),
      ],
    );
  }

  // ────────────── Bottom 패널 UI (슬라이더) ──────────────
  Widget _buildBottomPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 큰 숫자
        Text(
          '${_sliderValue.round()}',
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: _trackColor,
          ),
        ),
        const SizedBox(height: 8),
        // 커스텀 슬라이더(분위기 동일)
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
            inactiveTrackColor: _trackColor.withValues(alpha: 0.25),
            thumbColor: _trackColor,
            overlayColor: _trackColor.withValues(alpha: 0.25),
            showValueIndicator: ShowValueIndicator.never,
          ),
          child: Slider(
            value: _sliderValue,
            min: 0,
            max: 10,
            divisions: 10,
            label: _sliderValue.round().toString(),
            activeColor: _trackColor,
            inactiveColor: _trackColor.withValues(alpha: 0.25),
            onChanged: (v) => setState(() => _sliderValue = v),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0점: 전혀 믿지 않음',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '10점: 매우 믿음',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ────────────── onNext 로직 (원본 그대로 유지) ──────────────
  void _handleNext() {
    // realOddness.after 갱신
    final diaryId = widget.abcId;
    if (diaryId != null && diaryId.isNotEmpty && _currentB.isNotEmpty) {
      // 기존 realOddness와 병합하여 전체 배열로 업데이트
      _diariesApi
          .getDiary(diaryId)
          .then((current) async {
            final List<dynamic> existing =
                (current['realOddness'] is List)
                    ? List.from(current['realOddness'])
                    : <dynamic>[];
            final Map<String, Map<String, dynamic>> byBelief = {};
            for (final e in existing) {
              if (e is Map && e['belief'] != null) {
                byBelief[e['belief'].toString().trim()] = e.map(
                  (k, v) => MapEntry(k.toString(), v),
                );
              }
            }
            final key = _currentB.trim();
            final prev = byBelief[key];
            byBelief[key] = {
              if (prev != null) ...prev,
              'belief': key,
              'after': _sliderValue.round(),
            };
            final merged = byBelief.values.toList();
            await _diariesApi.updateDiary(diaryId, {'realOddness': merged});
          })
          .catchError((_) {});
    }

    // 모든 B를 다룬 경우 → abcId 유무에 따라 분기
    if (widget.remainingBList.isEmpty) {
      if (widget.abcId != null && widget.abcId!.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) => Week4AfterSudScreen(
                  beforeSud: widget.beforeSud,
                  currentB: _currentB,
                  remainingBList: widget.remainingBList,
                  allBList: widget.allBList,
                  alternativeThoughts: _removeDuplicates([
                    ...?widget.existingAlternativeThoughts,
                    ...widget.alternativeThoughts,
                  ]),
                  isFromAnxietyScreen: widget.isFromAnxietyScreen,
                  originalBList: widget.originalBList,
                  loopCount: widget.loopCount,
                  abcId: widget.abcId,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        // ② abcId가 없으면: 기존 로직(Week4AfterSudScreen)으로 이동
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) => Week4AfterSudScreen(
                  beforeSud: widget.beforeSud,
                  currentB: _currentB,
                  remainingBList: widget.remainingBList,
                  allBList: widget.allBList,
                  alternativeThoughts: _removeDuplicates([
                    ...?widget.existingAlternativeThoughts,
                    ...widget.alternativeThoughts,
                  ]),
                  isFromAnxietyScreen: widget.isFromAnxietyScreen,
                  originalBList: widget.originalBList,
                  loopCount: widget.loopCount,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } else {
      // 남은 B가 있으면 다음 B로 진행
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder:
              (_, __, ___) => Week4NextThoughtScreen(
                remainingBList: widget.remainingBList,
                beforeSud: widget.beforeSud,
                allBList: widget.allBList,
                alternativeThoughts: _removeDuplicates([
                  ...?widget.existingAlternativeThoughts,
                  ...widget.alternativeThoughts,
                ]),
                isFromAnxietyScreen: widget.isFromAnxietyScreen,
                addedAnxietyThoughts: const [],
                existingAlternativeThoughts: _removeDuplicates([
                  ...?widget.existingAlternativeThoughts,
                  ...widget.alternativeThoughts,
                ]),
                abcId: widget.abcId,
                loopCount: widget.loopCount,
              ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  // ────────────── 화면 구성: ApplyDoubleCard 사용 ──────────────
  @override
  Widget build(BuildContext context) {
    return ApplyDoubleCard(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      onBack: () => Navigator.pop(context),
      onNext: _handleNext,

      // 상단/하단 패널
      topChild: _buildTopPanel(),
      bottomChild: _buildBottomPanel(),

      // 패널 사이 말풍선 안내
      middleBannerText:
          '지금은 위 생각에 대해 얼마나 \n강하게 믿고 계시나요? 아래 슬라이더를 조정하고 [ 다음 ]을 눌러주세요.',

      // 스타일(필요시 조정)
      pagePadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
      panelsGap: 2,
      panelRadius: 20,
      panelPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
    );
  }
}
