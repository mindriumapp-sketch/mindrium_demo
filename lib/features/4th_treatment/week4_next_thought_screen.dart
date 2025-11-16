// lib/features/4th_treatment/week4_next_thought_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/4th_treatment/week4_classfication_screen.dart';

// ✅ ApplyDesign (배경 + AppBar + BlueWhiteCard + 하단 네비 버튼)
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/widgets/ruled_paragraph.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';

class Week4NextThoughtScreen extends StatefulWidget {
  final List<String> remainingBList;
  final int beforeSud;
  final List<String> allBList;
  final List<String>? alternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String> addedAnxietyThoughts;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;
  final int loopCount;

  const Week4NextThoughtScreen({
    super.key,
    required this.remainingBList,
    required this.beforeSud,
    required this.allBList,
    this.alternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.addedAnxietyThoughts = const [],
    this.existingAlternativeThoughts,
    this.abcId,
    this.loopCount = 1,
  });

  @override
  State<Week4NextThoughtScreen> createState() => _Week4NextThoughtScreenState();
}

class _Week4NextThoughtScreenState extends State<Week4NextThoughtScreen> {
  bool _isNextEnabled = false;
  int _secondsLeft = 5;
  bool _showSituation = true; // 상황 안내 먼저, 이후 보라 안내
  String? _activatingEvent;
  bool _isLoading = true;
  late final ApiClient _client;
  late final DiariesApi _diariesApi;
  late final UserDataApi _userDataApi;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    _userDataApi = UserDataApi(_client);
    _startCountdown();
    _fetchActivatingEvent();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (_secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return false;
        setState(() {
          _secondsLeft--;
        });
        return true;
      } else {
        setState(() {
          _isNextEnabled = true;
        });
        return false;
      }
    });
  }

  Future<void> _fetchActivatingEvent() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic>? diary;
      if (widget.abcId != null && widget.abcId!.isNotEmpty) {
        diary = await _diariesApi.getDiary(widget.abcId!);
      } else {
        final list = await _diariesApi.listDiaries();
        if (list.isNotEmpty) diary = list.first;
      }
      if (!mounted) return;
      setState(() {
        _activatingEvent = (diary?['activating_events'] ??
                diary?['activatingEvent'])
            ?.toString();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    final nextThought =
    widget.remainingBList.isNotEmpty ? widget.remainingBList.first : '';

    const double kRuleWidth = 220;

    // 안내문 텍스트
    final situationText = (_activatingEvent != null && _activatingEvent!.isNotEmpty)
        ? "$userName님, \n잘 따라오고 계십니다!\n 다시 '$_activatingEvent' (이)라는 상황을 \n자세하게 상상해 보세요."
        : '이때의 상황을 자세하게 상상해 보세요.';
    final nextThoughtText =
        "일기에 작성하셨던 또 다른 \n생각인 '$nextThought'에 대해 \n계속 진행해보겠습니다.";

    final followingText = _showSituation ? situationText : nextThoughtText;
    final followingTextStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.black,
      height: 1.8,
      letterSpacing: 0.8,
      fontFamily: 'Noto Sans KR',
    );

    // === 카드 안에 들어갈 본문 위젯 ===
    final Widget body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Image.asset(
          'assets/image/think_blue.png',
          height: 160,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 20),
        // 메인 안내
        RuledParagraph(
          text: followingText,
          textAlign: TextAlign.center,
          style: followingTextStyle,
          lineColor: const Color(0xFFE1E8F0),
          lineThickness: 1.2,
          lineGapBelow: 8,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          lineWidth: kRuleWidth,
        ),

        const SizedBox(height: 24),

        // 카운트다운 안내
        if (!_isNextEnabled)
          Text(
            '$_secondsLeft초 후에 다음 버튼이 활성화됩니다',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9BA7B4),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );

    // === ApplyDesign 사용: 배경/앱바/중앙 BlueWhiteCard/하단 네비 버튼 ===
    return ApplyDesign(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      cardTitle: '그때 상황 다시 떠올리기',
      onBack: () => Navigator.pop(context),
      onNext: _isNextEnabled
          ? () async {
        if (_showSituation) {
          setState(() => _showSituation = false);
          return;
        }
        // 1) 새로 입력한 불안 생각을 일기 belief에 누적 + 커스텀 태그 저장
        try {
          final newThoughts = widget.isFromAnxietyScreen ? widget.addedAnxietyThoughts : <String>[];
          if (newThoughts.isNotEmpty) {
            final id = widget.abcId;
            // diaryId가 없으면 최신으로 보정
            final diary = (id != null && id.isNotEmpty)
                ? await _diariesApi.getDiary(id)
                : await _diariesApi.getLatestDiary();
            final diaryId = diary['diaryId']?.toString();
            if (diaryId != null && diaryId.isNotEmpty) {
              final List<String> existingBelief = [
                ...((diary['belief'] is List)
                    ? (diary['belief'] as List).map((e) => e.toString())
                    : diary['belief']?.toString().split(',') ?? <String>[]),
              ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final toAdd = newThoughts.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final merged = <String>{...existingBelief, ...toAdd}.toList();
              await _diariesApi.updateDiary(diaryId, {'belief': merged});
              // 커스텀 태그(B)로도 저장
              for (final t in toAdd) {
                await _userDataApi.createCustomTag(text: t, type: 'B');
              }
            }
          }
        } catch (_) {}

        // 2) 다음 화면 이동
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week4ClassificationScreen(
              bListInput: widget.isFromAnxietyScreen
                  ? widget.addedAnxietyThoughts
                  : widget.remainingBList,
              beforeSud: widget.beforeSud,
              allBList: widget.allBList,
              alternativeThoughts: widget.alternativeThoughts,
              isFromAnxietyScreen: widget.isFromAnxietyScreen,
              existingAlternativeThoughts:
              widget.existingAlternativeThoughts,
              abcId: widget.abcId,
              loopCount: widget.loopCount,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
          : null,
      child: body, // 비활성화 상태면 null 전달 → NavigationButtons에서 비활성 처리
    );
  }
}
