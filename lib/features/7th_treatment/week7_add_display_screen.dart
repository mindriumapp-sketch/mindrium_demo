// File: lib/features/7th_treatment/week7_add_display_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/features/7th_treatment/week7_reason_input_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_planning_screen.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week7AddDisplayScreen extends StatefulWidget {
  final String? initialBehavior;

  /// 6→7주차 진입 시 초기 자동 추가를 지연할지 여부 (기본: true)
  final bool deferInitialMarkAsAdded;

  const Week7AddDisplayScreen({
    super.key,
    this.initialBehavior,
    this.deferInitialMarkAsAdded = true,
  });

  @override
  State<Week7AddDisplayScreen> createState() => _Week7AddDisplayScreenState();

  // 전역 상태 getter/setter
  static Set<String> get globalAddedBehaviors =>
      Set<String>.from(_Week7AddDisplayScreenState._globalAddedBehaviors);

  static void updateGlobalAddedBehaviors(Set<String> behaviors) {
    _Week7AddDisplayScreenState._globalAddedBehaviors
      ..clear()
      ..addAll(behaviors);
  }

  static List<String> get globalNewBehaviors =>
      List<String>.from(_Week7AddDisplayScreenState._globalNewBehaviors);

  static void updateGlobalNewBehaviors(List<String> behaviors) {
    _Week7AddDisplayScreenState._globalNewBehaviors
      ..clear()
      ..addAll(behaviors);
  }
}

class _Week7AddDisplayScreenState extends State<Week7AddDisplayScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  List<Map<String, String>> _behaviorCards = [];
  Set<String> _addedBehaviors = {};

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late final ApiClient _client;
  late final DiariesApi _diariesApi;

  // 공유 전역 상태
  static final Set<String> _globalAddedBehaviors = {};
  static final List<String> _globalNewBehaviors = [];

  // 색상 토큰 (통일)
  static const Color _primaryBlue = Color.fromARGB(255, 112, 193, 243); // 추가하기
  static const Color _stripBlue = Color(0xFF5DADEC);
  static const Color _stripPaleBlue = Color(0xFFD7E8FF);
  static const Color _stripTextGrey = Color(0xFF646464);
  static const Color _removePink = Color.fromARGB(255, 243, 173, 177); // 제거하기

  static const EdgeInsets _listInnerPad = EdgeInsets.symmetric(horizontal: 12);

  // 행동 텍스트 정렬(세로 중앙 정렬)
  final Alignment _behaviorTextAlignment = Alignment.centerLeft;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fetchAllConfrontAvoidLogs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncWithGlobalState();
  }

  @override
  void didUpdateWidget(covariant Week7AddDisplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithGlobalState();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _syncWithGlobalState() {
    if (!mounted) return;
    setState(() {
      _addedBehaviors = Set<String>.from(_globalAddedBehaviors);
    });
  }

  Future<void> _fetchAllConfrontAvoidLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // 모든 일기에서 confrontAvoidLogs 수집
      final allLogs = await _diariesApi.getAllConfrontAvoidLogs();
      
      // confrontAvoidLogs를 behaviorCards 형태로 변환
      _initBehaviorCardsFromLogs(allLogs);
      
      // 초기 자동 추가는 "지연" (기본 true) — 기존 로직은 그대로 두고 게이트만 추가
      if (widget.initialBehavior != null && !widget.deferInitialMarkAsAdded) {
        _globalAddedBehaviors.add(widget.initialBehavior!);
      }
      
      _addedBehaviors = Set.from(_globalAddedBehaviors);
      
      setState(() {
        _isLoading = false;
      });
      
      if (_behaviorCards.isNotEmpty) {
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _initBehaviorCardsFromLogs(List<Map<String, dynamic>> logs) {
    // type과 comment를 사용하여 behaviorCards 생성
    // 같은 comment가 여러 번 나올 수 있으므로, 최신 것만 사용 (또는 모두 표시)
    // 여기서는 중복 제거하여 최신 것만 사용
    final Map<String, String> behaviorMap = {}; // comment -> classification
    
    for (var log in logs) {
      final comment = log['comment']?.toString() ?? '';
      final type = log['type']?.toString() ?? '';
      
      if (comment.isNotEmpty && type.isNotEmpty) {
        // 같은 comment가 있으면 최신 것으로 업데이트 (이미 정렬되어 있음)
        final classification = type == 'confronted' ? '직면' : '회피';
        behaviorMap[comment] = classification;
      }
    }
    
    _behaviorCards = behaviorMap.entries
        .map((e) => {
              'behavior': e.key,
              'classification': e.value,
            })
        .toList();
  }

  String _getClassificationText(String classification) {
    switch (classification) {
      case '직면':
        return '불안 직면';
      case '회피':
        return '불안 회피';
      default:
        return '미분류';
    }
  }

  // ── 팝업 (BehaviorConfirmDialog 사용: 기존 플로우 유지)
  void _showAddConfirmationDialog(String behavior) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return CustomPopupDesign(
          title: '건강한 생활 습관 추가',
          highlightText: '[$behavior]',
          message: '이 불안 회피 행동을 건강한 생활 습관에 \n추가하시겠습니까?',
          negativeText: '취소',
          positiveText: '추가',
          onNegativePressed: () => Navigator.of(context).pop(),
          onPositivePressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week7ReasonInputScreen(behavior: behavior),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      },
    );
  }

  void _showRemoveConfirmationDialog(String behavior) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return CustomPopupDesign(
          title: '생활 습관 제거',
          highlightText: '[$behavior]',
          message: '이 행동을 건강한 생활 습관에서 제거하시겠습니까?',
          negativeText: '취소',
          positiveText: '제거',
          onNegativePressed: () => Navigator.of(context).pop(),
          onPositivePressed: () {
            Navigator.of(context).pop();
            _removeFromHealthyHabits(behavior);
          },
        );
      },
    );
  }

  void _removeFromHealthyHabits(String behavior) {
    final newGlobalBehaviors = Set<String>.from(_globalAddedBehaviors)
      ..remove(behavior);
    Week7AddDisplayScreen.updateGlobalAddedBehaviors(newGlobalBehaviors);

    setState(() {
      _addedBehaviors.remove(behavior);
    });

    BlueBanner.show(context, '"$behavior"이(가) 건강한 생활 습관에서 제거되었습니다.');
  }

  void _showAddToHealthyHabitsDialog(String behavior) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) {
        return CustomPopupDesign(
          title: '건강한 생활 습관 추가',
          highlightText: '[$behavior]', // 메모 띠 안의 행동 표시
          message: '이 불안 직면 행동을 건강한 생활 습관에 추가하시겠습니까??',
          negativeText: '취소',
          positiveText: '추가',
          onNegativePressed: () => Navigator.of(context).pop(),
          onPositivePressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week7ReasonInputScreen(behavior: behavior),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        );
      },
    );
  }

  // ── 단색 버튼 빌더 (색상만 바꾸면 전체 일괄 적용)
  Widget _solidButton({
    required String text,
    required Color color,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 112,
        height: 31,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? color : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: enabled ? 1 : 0.7),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ── 리스트 카드 (표시 로직: 최초=추가하기만 / 확정 후=추가됨+제거하기)
  Widget _buildBehaviorCard(Map<String, String> card, int index) {
    final classification = card['classification'] ?? '';
    final behavior = card['behavior'] ?? '';
    final bool isFacing = classification == '직면';
    final Color stripColor = isFacing ? _stripPaleBlue : _stripBlue;
    final Color stripTextColor = isFacing ? _stripTextGrey : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // 상단 분류 스트립
          Container(
            width: double.infinity,
            height: 30,
            decoration: BoxDecoration(color: stripColor),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _getClassificationText(classification),
              style: TextStyle(
                color: stripTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),

          // 내용 카드 (아래만 둥글게 10 + 그림자)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F000000), // 12% 블랙
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
              border: Border.all(color: Color(0xFFE6EEF9), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 왼쪽: 행동 텍스트 (세로 중앙 정렬)
                Expanded(
                  child: Align(
                    alignment: _behaviorTextAlignment,
                    child: Text(
                      behavior,
                      style: const TextStyle(
                        color: Color(0xFF263C69),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 오른쪽: 버튼 컬럼
                if (_addedBehaviors.contains(behavior))
                  // 최종 추가된 상태 → "추가됨"(비활성 회색) + "제거하기"(핑크)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _solidButton(
                        text: '추가됨',
                        color: const Color(0xFFCBD5E1),
                        enabled: false,
                        onTap: null,
                      ),
                      const SizedBox(height: 8),
                      _solidButton(
                        text: '제거하기',
                        color: _removePink,
                        enabled: true,
                        onTap: () => _showRemoveConfirmationDialog(behavior),
                      ),
                    ],
                  )
                else
                  // 최초 상태 → "추가하기"(파랑)만 표시
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _solidButton(
                        text: '추가하기',
                        color: _primaryBlue,
                        enabled: true,
                        onTap: () {
                          if (classification == '회피') {
                            _showAddConfirmationDialog(behavior);
                          } else {
                            _showAddToHealthyHabitsDialog(behavior);
                          }
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 화면
  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '7주차 - 생활 습관 개선',
      cardTitle: '행동 분석 결과',
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week7PlanningScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      // 👉 카드 내부 (디자인만 수정)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20,),
          // 중앙 정렬 안내 문구 (텍스트만)
          const Text(
            '6주차에서 분류한 행동들을 확인해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              wordSpacing: 1.6,
              fontWeight: FontWeight.w500,
              color: Color(0xFF626262),
            ),
          ),
          const SizedBox(height: 40),

          // 리스트 (Expanded → shrinkWrap ListView로 수정)
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            )
          else if (_behaviorCards.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '분류된 행동이 없습니다',
                  style: TextStyle(color: Color(0xFF718096)),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: _listInnerPad,
              itemCount: _behaviorCards.length,
              itemBuilder: (context, index) {
                final card = _behaviorCards[index];
                return _buildBehaviorCard(card, index);
              },
            ),
        ],
      ),
    );
  }
}
