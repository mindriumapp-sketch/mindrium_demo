// lib/features/4th_treatment/week4_classification_screen.dart
import 'package:flutter/material.dart';
import 'week4_classfication_result_screen.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';

// ✅ 두 패널 레이아웃 (네가 저장한 파일)
import 'package:gad_app_team/widgets/top_btm_card.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week4ClassificationScreen extends StatefulWidget {
  final List<String> bListInput;
  final int? beforeSud;
  final List<String> allBList;
  final List<String>? alternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;
  final int loopCount;

  const Week4ClassificationScreen({
    super.key,
    required this.bListInput,
    this.beforeSud,
    required this.allBList,
    this.alternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.existingAlternativeThoughts,
    this.abcId,
    this.loopCount = 1,
  });

  @override
  Week4ClassificationScreenState createState() =>
      Week4ClassificationScreenState();
}

class Week4ClassificationScreenState extends State<Week4ClassificationScreen> {
  // ── 상태/로직: 그대로 유지 ─────────────────────────────────────────────────────
  Color get _trackColor =>
      _sliderValue <= 2
          ? Colors.green
          : (_sliderValue >= 8 ? Colors.red : Colors.amber);
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;
  double _sliderValue = 5.0;
  late List<String> _bList;
  late String _currentB;
  final Map<String, double> _bScores = {};
  late final ApiClient _client;
  late final DiariesApi _diariesApi;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    final id = widget.abcId;
    if (id != null && id.isNotEmpty) {
      _fetchDiaryById(id);
    } else {
      _fetchLatestDiary();
    }
  }

  Future<void> _fetchLatestDiary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _diariesApi.listDiaries();
      if (list.isEmpty) {
        setState(() {
          _abcModel = null;
          _isLoading = false;
        });
        return;
      }
      // 가장 최신 선택(시간 필드 + 인덱스 우선)
      // removed unused time helpers (latest 선택은 서버 /latest 사용)

      // keep for reference of time parsing if needed later

      // 최신 = 서버 latest API로 확정
      final Map<String, dynamic> latest = await _diariesApi.getLatestDiary();
      setState(() {
        _abcModel = latest;
        _isLoading = false;
        _initBList();
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDiaryById(String diaryId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _diariesApi.getDiary(diaryId);
      if (!mounted) return;
      setState(() {
        _abcModel = res;
        _isLoading = false;
        _initBList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  void _initBList() {
    List<String> parseBelief(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      final s = (raw ?? '').toString();
      return s
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    // 1) 인자로 받은 목록 우선
    if (widget.bListInput.isNotEmpty) {
      _bList =
          widget.bListInput
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
    }
    // 2) 비어 있으면 모델에서 파싱
    if (_bList.isEmpty && _abcModel != null) {
      _bList = parseBelief(_abcModel?['belief']);
    }
    // 3) 남은 목록 중 아직 점수 안 준 첫 항목 선택
    final remainB = _bList.where((b) => !_bScores.containsKey(b)).toList();
    if (remainB.isNotEmpty) {
      _currentB = remainB.first;
    } else if (_bList.isNotEmpty) {
      _currentB = _bList.first;
    } else {
      _currentB = '';
    }
    _sliderValue = 5.0;
  }

  void _onNext() {
    // 현재 B가 비어 있으면 보정
    if (_currentB.isEmpty && _bList.isNotEmpty) {
      final firstNonEmpty = _bList.firstWhere(
        (e) => e.trim().isNotEmpty,
        orElse: () => '',
      );
      if (firstNonEmpty.isNotEmpty) _currentB = firstNonEmpty;
    }
    if (_currentB.isNotEmpty) {
      setState(() {
        _bScores[_currentB] = _sliderValue;
      });
    }
    final List<String> remainingBList =
        _bList.where((b) => !_bScores.containsKey(b)).toList();

    final bool isFromAnxietyScreen = widget.isFromAnxietyScreen;

    // 실시간 real oddness 저장(누적 스코어 병합)
    // 항상 현재 화면에서 로드한 최신 일기의 ID를 사용
    final diaryId = _abcModel?['diaryId']?.toString();
    if (diaryId != null && diaryId.isNotEmpty) {
      final entries =
          _bScores.entries
              .map((e) => {'belief': e.key.trim(), 'before': e.value.round()})
              .toList();
      // 서버가 배열을 통째로 대체할 수 있으므로, 클라이언트에서 병합 후 전체 배열을 전송
      final List<dynamic> existing =
          (_abcModel?['realOddness'] is List)
              ? List.from(_abcModel!['realOddness'])
              : <dynamic>[];
      final Map<String, Map<String, dynamic>> byBelief = {};
      for (final e in existing) {
        if (e is Map && e['belief'] != null) {
          byBelief[e['belief'].toString().trim()] = e.map(
            (k, v) => MapEntry(k.toString(), v),
          );
        }
      }
      for (final e in entries) {
        final key = e['belief'].toString();
        final prev = byBelief[key];
        byBelief[key] = {
          if (prev != null) ...prev,
          ...e, // before 값 갱신
        };
      }
      final merged = byBelief.values.toList();
      _abcModel ??= {};
      _abcModel!['realOddness'] = merged;
      _diariesApi
          .updateDiary(diaryId, {'realOddness': merged})
          .catchError((_) => <String, dynamic>{});
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (_, __, ___) => Week4ClassificationResultScreen(
              bScores: _bScores.values.toList(),
              bList: _bScores.keys.toList(),
              beforeSud: widget.beforeSud ?? 0,
              remainingBList: remainingBList,
              allBList: widget.allBList,
              alternativeThoughts: widget.alternativeThoughts,
              isFromAnxietyScreen: isFromAnxietyScreen,
              existingAlternativeThoughts: widget.existingAlternativeThoughts,
              abcId: _abcModel?['diaryId']?.toString(),
              loopCount: widget.loopCount,
            ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 로딩/에러 상태일 때 보여줄 안전한 위젯들
    final Widget topLoading = const SizedBox(
      height: 160,
      child: Center(child: CircularProgressIndicator()),
    );
    final Widget topError =
        (_error == null)
            ? const SizedBox.shrink()
            : SizedBox(
              height: 160,
              child: Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            );

    // Top 패널 내용
    Widget buildTopPanel() {
      if (_isLoading) return topLoading;
      if (_error != null) return topError;

      // 데이터 없음 안내
      if ((_abcModel == null ||
          (_currentB.isEmpty && widget.bListInput.isEmpty))) {
        return const SizedBox(
          height: 160,
          child: Center(
            child: Text('최근에 작성한 ABC모델이 없습니다.', style: TextStyle(fontSize: 16)),
          ),
        );
      }

      final displayB =
          _currentB.isNotEmpty
              ? _currentB
              : (widget.bListInput.isNotEmpty ? widget.bListInput.first : '');

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 35),
          Text(
            '$userName님께서 걱정일기에 작성해주신 생각을 보며 진행해주세요.',
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
            displayB,
            style: TextStyle(
              fontSize: 20,
              height: 1.35,
              wordSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263C69),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 35),
        ],
      );
    }

    // Bottom 패널 내용 (슬라이더)
    Widget buildBottomPanel() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${_sliderValue.round()}',
            style: TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: _trackColor,
            ),
          ),
          const SizedBox(height: 8),
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
          // const SizedBox(height: 5),
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

    // ===== ApplyDoubleCard 사용: 위/아래 패널 전달 =====
    return ApplyDoubleCard(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      onBack: () => Navigator.pop(context),
      onNext: _onNext,
      topChild: buildTopPanel(),
      bottomChild: buildBottomPanel(),
      middleBannerText:
          '지금은 위 생각에 대해 \n얼마나 강하게 믿고 계시나요? 아래 슬라이더를 조정하고 [ 다음 ]을 눌러주세요.',
      panelsGap: 2,
    );
  }
}
