// lib/features/4th_treatment/week4_classification_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'week4_classfication_result_screen.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';

// ✅ 두 패널 레이아웃 (네가 저장한 파일)
import 'package:gad_app_team/widgets/top_btm_card.dart';

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
      _sliderValue <= 2 ? Colors.green : (_sliderValue >= 8 ? Colors.red : Colors.amber);
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;
  double _sliderValue = 5.0;
  late List<String> _bList;
  late String _currentB;
  final Map<String, double> _bScores = {};

  @override
  void initState() {
    super.initState();
    final id = widget.abcId;
    if (id != null && id.isNotEmpty) {
      _fetchAbcModelById(id);
    } else {
      _fetchLatestAbcModel();
    }
  }

  Future<void> _fetchLatestAbcModel() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _abcModel = null;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _abcModel = snapshot.docs.first.data();
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

  Future<void> _fetchAbcModelById(String abcId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .doc(abcId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        setState(() {
          _abcModel = null;
          _isLoading = false;
          _error = '해당 ABC모델을 찾을 수 없습니다.';
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _abcModel = doc.data();
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
    if (widget.bListInput.isNotEmpty) {
      final skippedThoughts = widget.bListInput;
      _bList = skippedThoughts;
      _currentB = _bList.first;
    } else if (_abcModel != null) {
      final bRaw = (_abcModel?['belief'] ?? '') as String;
      _bList = bRaw
          .split(',')
          .map((e) => e.trim())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
      final remainB = _bList.where((b) => !_bScores.containsKey(b)).toList();
      _currentB = remainB.isNotEmpty
          ? remainB.first
          : (_bList.isNotEmpty ? _bList.first : '');
    } else {
      _bList = [];
      _currentB = '';
    }
    _sliderValue = 5.0;
  }

  void _onNext() {
    setState(() {
      _bScores[_currentB] = _sliderValue;
    });
    final List<String> remainingBList =
    _bList.where((b) => !_bScores.containsKey(b)).toList();

    final bool isFromAnxietyScreen = widget.isFromAnxietyScreen;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week4ClassificationResultScreen(
          bScores: _bScores.values.toList(),
          bList: _bScores.keys.toList(),
          beforeSud: widget.beforeSud ?? 0,
          remainingBList: remainingBList,
          allBList: widget.allBList,
          alternativeThoughts: widget.alternativeThoughts,
          isFromAnxietyScreen: isFromAnxietyScreen,
          existingAlternativeThoughts: widget.existingAlternativeThoughts,
          abcId: widget.abcId,
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
    final Widget topError = (_error == null)
        ? const SizedBox.shrink()
        : SizedBox(
      height: 160,
      child: Center(
        child: Text(
          _error!,
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );

    // Top 패널 내용
    Widget buildTopPanel() {
      if (_isLoading) return topLoading;
      if (_error != null) return topError;

      // 데이터 없음 안내
      if ((_abcModel == null || (_currentB.isEmpty && widget.bListInput.isEmpty))) {
        return const SizedBox(
          height: 160,
          child: Center(
            child: Text('최근에 작성한 ABC모델이 없습니다.', style: TextStyle(fontSize: 16)),
          ),
        );
      }

      final displayB = _currentB.isNotEmpty
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
              inactiveTrackColor: _trackColor.withOpacity(0.25),
              thumbColor: _trackColor,
              overlayColor: _trackColor.withOpacity(0.25),
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: _sliderValue,
              min: 0,
              max: 10,
              divisions: 10,
              label: _sliderValue.round().toString(),
              activeColor: _trackColor,
              inactiveColor: _trackColor.withOpacity(0.25),
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
      middleBannerText: '지금은 위 생각에 대해 \n얼마나 강하게 믿고 계시나요? 아래 슬라이더를 조정하고 [ 다음 ]을 눌러주세요.',
      panelsGap: 2,
    );
  }
}
