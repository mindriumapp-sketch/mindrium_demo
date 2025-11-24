import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/features/8th_treatment/week8_schedule_screen.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';
import 'package:gad_app_team/widgets/jellyfish_notice.dart';
import 'package:gad_app_team/widgets/quiz_card.dart';
import 'package:gad_app_team/widgets/choice_card_button.dart';
import 'package:gad_app_team/features/7th_treatment/week7_add_display_screen.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/week8_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 모델
class CalendarEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> behaviors;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.behaviors,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'behaviors': behaviors,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    behaviors: List<String>.from(json['behaviors']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// 화면
class Week8EffectivenessScreen extends StatefulWidget {
  final List<String> checkedBehaviors;

  const Week8EffectivenessScreen({super.key, required this.checkedBehaviors});

  @override
  State<Week8EffectivenessScreen> createState() =>
      _Week8EffectivenessScreenState();
}

class _Week8EffectivenessScreenState extends State<Week8EffectivenessScreen> {
  // 컬러 상수
  static const chipBorderBlue = Color(0xFF6DBEF2);
  static const checkedChipFill = Color(0xFFDDEEFF);

  // 처음에는 “체크된 계획”만 보여주는 상태
  bool _showingCheckedList = true;

  final List<String> _checkedBehaviors = [];
  final Set<String> _removedBehaviors = {};
  int _currentBehaviorIndex = 0;

  // 단계(0: 효과성, 1: 유지)
  int _step = 0;
  bool? _wasEffective;
  bool? _willContinue;

  bool _loading = true;
  String? _userName;
  String? _userValueGoal;

  // ✅ JellyfishNotice에 띄울 말 제어용 UI 상태
  bool _answered = false; // 이번 질문에 예/아니오를 눌렀는가
  bool _answeredYes = true; // true면 예, false면 아니오

  // 평가 결과 저장 (behavior -> {was_effective, will_continue})
  final Map<String, Map<String, bool>> _evaluationResults = {};

  // API 클라이언트
  late final ApiClient _apiClient;
  late final Week8Api _week8Api;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(tokens: TokenStorage());
    _week8Api = Week8Api(_apiClient);
    _init();
  }

  Future<void> _init() async {
    _checkedBehaviors
      ..clear()
      ..addAll(widget.checkedBehaviors);
    await _loadUser();
    setState(() => _loading = false);
  }

  Future<void> _loadUser() async {
    // TODO: 사용자 정보는 필요시 UserDataApi에서 가져오기
    // 현재는 사용하지 않으므로 주석 처리
    // try {
    //   final userDataApi = UserDataApi(_apiClient);
    //   final user = await userDataApi.getUser();
    //   _userName = user['name'] as String?;
    //   _userValueGoal = user['value_goal'] as String?;
    // } catch (_) {}
  }

  String get _currentBehavior => _checkedBehaviors[_currentBehaviorIndex];
  bool get _canNext =>
      _showingCheckedList
          ? true
          : (_step == 0 ? _wasEffective != null : _willContinue != null);

  void _onNext() {
    // 1) 체크된 계획만 보여주던 첫 화면일 때 → 평가 모드로 전환
    if (_showingCheckedList) {
      setState(() {
        _showingCheckedList = false;
        _step = 0;
        _currentBehaviorIndex = 0;
        _wasEffective = null;
        _willContinue = null;
        _answered = false; // ✅ 새로운 질문이니까 초기화
      });
      return;
    }

    // 2) 평가 모드일 때 기존 로직
    if (_step == 0) {
      setState(() {
        _step = 1;
        _answered = false; // ✅ 다음 질문(유지 질문)으로 넘어가므로 초기화
      });
      return;
    }

    // 현재 행동의 평가 결과 저장
    _evaluationResults[_currentBehavior] = {
      'was_effective': _wasEffective ?? false,
      'will_continue': _willContinue ?? false,
    };

    // 유지하기 않음 선택 시 제거 목록에 추가
    if (_willContinue == false) {
      _removedBehaviors.add(_currentBehavior);
    }

    // 다음 행동으로
    if (_currentBehaviorIndex < _checkedBehaviors.length - 1) {
      setState(() {
        _currentBehaviorIndex++;
        _step = 0;
        _wasEffective = null;
        _willContinue = null;
        _answered = false; // ✅ 새 행동이므로 초기화
      });
    } else {
      _saveEvaluations();
    }
  }

  void _onBack() {
    // 체크된 계획 화면에서는 그냥 나가기
    if (_showingCheckedList) {
      Navigator.pop(context);
      return;
    }

    // 평가 중인데 유지 단계면 → 효과성 단계로만 한 단계 뒤로
    if (_step == 1) {
      setState(() {
        _step = 0;
        _wasEffective = null;
        _answered = false; // 다시 효과성 질문으로 왔으니 초기화
      });
      return;
    }

    // 그 외에는 나가기
    Navigator.pop(context);
  }

  Future<void> _saveEvaluations() async {
    try {
      // behavior -> chip_id 매핑 가져오기
      final behaviorToChip = Week7AddDisplayScreen.globalBehaviorToChip;
      
      // 평가 결과를 API 형식으로 변환
      final evaluations = _evaluationResults.entries.map((entry) {
        final behavior = entry.key;
        final result = entry.value;
        final chipId = behaviorToChip[behavior]; // null일 수 있음 (새로 추가한 행동)
        
        return {
          'behavior': behavior, // 항상 포함 (chip_id가 없을 때 식별용)
          if (chipId != null) 'chip_id': chipId, // chip_id가 있을 때만 포함
          'was_effective': result['was_effective'] ?? false,
          'will_continue': result['will_continue'] ?? false,
        };
      }).toList();

      await _week8Api.updateEffectiveness(evaluations: evaluations);
      
      if (!mounted) return;
      _showDone();
    } catch (e) {
      if (!mounted) return;
      BlueBanner.show(context, '평가 저장에 실패했습니다: $e');
    }
  }

  void _showDone() {
    final keep =
    _checkedBehaviors.where((b) => !_removedBehaviors.contains(b)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomPopupDesign(
        title: '평가 완료',
        highlightText:
        keep.isEmpty ? '유지할 행동이 없습니다.' : '유지할 행동: ${keep.join(", ")}',
        message: '평가가 완료되었습니다! \n스케줄 관리하는 페이지로 넘어가겠습니다.',
        negativeText: '닫기',
        positiveText: '다음',
        onNegativePressed: () {
          Navigator.pop(context);
        },
        onPositivePressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Week8ScheduleScreen(behaviorsToKeep: keep),
            ),
          );
        },
      ),
    );
  }

  // ✅ 여기: 공통 진행바 위젯 (이 화면 버전)
  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '질문 ${_currentBehaviorIndex + 1}',
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                color: Color(0xFF356D91),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_currentBehaviorIndex + 1}/${_checkedBehaviors.length}',
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                color: Color(0xFF356D91),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentBehaviorIndex + 1) / _checkedBehaviors.length,
            backgroundColor: Colors.white,
            valueColor:
            const AlwaysStoppedAnimation<Color>(Color(0xFF74D2FF)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading || _checkedBehaviors.isEmpty) {
      return EduhomeBg(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(title: '8주차 - 효과성 평가'),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final String defaultDesc =
    _userName != null && _userValueGoal != null
        ? '$_userName님의 불안을 줄이고,\n소중히 여기는 가치\n"$_userValueGoal"를 향상하는 데\n도움이 되셨습니까?'
        : '이 행동이 불안을 줄이고\n소중히 여기는 가치를 향상하는 데\n도움이 되셨습니까?';

    // ✅ Jellyfish에 들어갈 실제 텍스트 결정
    Color jellyColor = const Color(0xFF626262);
    String jellyText;
    if (!_answered) {
      jellyText = _step == 0
          ? defaultDesc
          : '이 행동을 앞으로도 유지하고 싶은지 한 번 생각해볼까요?';
    } else {
      if (_step == 0) {
        jellyText = _answeredYes
            ? '효과가 있었다고 생각하시는군요!'
            : '효과가 없었다고 생각하시는군요!';
        jellyColor = _answeredYes
            ? const Color(0xFF329CF1)
            : const Color(0xFFE84551);
      } else {
        jellyText =
        _answeredYes ? '앞으로 유지할게요!' : '앞으로 유지하지 않을게요!';
        jellyColor = _answeredYes
            ? const Color(0xFF329CF1)
            : const Color(0xFFE84551);
      }
    }

    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '8주차 - 효과성 평가'),
        body: SafeArea(
          child: Column(
            children: [
              // 위쪽 스크롤 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.88,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ 체크된 계획 화면일 때는 진행바 안 보이게
                          if (!_showingCheckedList) ...[
                            _buildProgressBar(),
                            const SizedBox(height: 16),
                          ],

                          // 본문
                          _showingCheckedList
                              ? _checkedListCard()
                              : Column(
                            children: [
                              const SizedBox(height: 12),
                              _questionCard(),
                              const SizedBox(height: 14),
                              Container(
                                color: Colors.transparent,
                                height: 130,
                                child: JellyfishNotice(
                                  feedback: jellyText,
                                  feedbackColor: jellyColor,
                                ),
                              ),
                              // const SizedBox(height: 10),
                              ChoiceCardButton(
                                type: ChoiceType.other,
                                othText: '예',
                                height: 54,
                                onPressed: () {
                                  setState(() {
                                    _answered = true;
                                    _answeredYes = true;
                                    if (_step == 0) {
                                      _wasEffective = true;
                                    } else {
                                      _willContinue = true;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              ChoiceCardButton(
                                type: ChoiceType.another,
                                anoText: '아니오',
                                height: 54,
                                onPressed: () {
                                  setState(() {
                                    _answered = true;
                                    _answeredYes = false;
                                    if (_step == 0) {
                                      _wasEffective = false;
                                    } else {
                                      _willContinue = false;
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 아래 네비게이션 고정
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: '다음',
                  onBack: _onBack,
                  onNext: _canNext ? _onNext : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ quiz_card로 바꾼 질문 카드
  Widget _questionCard() {
    return QuizCard(
      noticeText: _currentBehavior,
      quizText: _step == 0 ? '효과가 있었나요?' : '앞으로도 유지하실 건가요?',
      currentIndex: _currentBehaviorIndex + 1,
      totalCount: _checkedBehaviors.length,
    );
  }

  // ✅ 체크된 계획 화면
  Widget _checkedListCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizCard(
          quizText: '아래 목록을 한 번 보고\n다음을 눌러 효과를 \n평가해볼까요?',
          currentIndex: 0,
        ),
        const SizedBox(height: 30),
        JellyfishBanner(
          message: '이번 주에 실천했던 계획들이에요.',
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _checkedBehaviors.map((b) {
              final removed = _removedBehaviors.contains(b);
              return ConstrainedBox(
                constraints: const BoxConstraints.tightFor(
                  width: 239,
                  height: 52,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: removed ? Colors.grey[300] : checkedChipFill,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: chipBorderBlue, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: chipBorderBlue.withOpacity(0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: removed ? Colors.black54 : const Color(0xFF2D3748),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
