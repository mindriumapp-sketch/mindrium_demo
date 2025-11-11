// File: lib/features/7th_treatment/week7_add_display_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/7th_treatment/week7_reason_input_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_planning_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/widgets/behavior_confirm_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';

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
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;

  List<Map<String, String>> _behaviorCards = [];
  Set<String> _addedBehaviors = {};

  late AnimationController _fadeController;
  late AnimationController _slideController;

  // 공유 전역 상태
  static final Set<String> _globalAddedBehaviors = {};
  static final List<String> _globalNewBehaviors = [];

  // 색상 토큰 (통일)
  static const Color _titleNavy = Color(0xFF263C69);
  static const Color _primaryBlue = Color.fromARGB(255, 112, 193, 243); // 추가하기
  static const Color _stripBlue = Color(0xFF5DADEC);
  static const Color _stripPaleBlue = Color(0xFFD7E8FF);
  static const Color _pillBlue = Color(0xFF81C8FF);
  static const Color _stripTextGrey = Color(0xFF646464);
  static const Color _removePink = Color.fromARGB(255, 243, 173, 177); // 제거하기

  // 내부 여백/치수
  static const double _bodySidePad = 20.0; // 본문 좌우
  static const EdgeInsets _cardPad = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 24,
  );
  static const EdgeInsets _listInnerPad = EdgeInsets.symmetric(horizontal: 12);

  // 행동 텍스트 정렬(세로 중앙 정렬)
  final Alignment _behaviorTextAlignment = Alignment.centerLeft;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fetchLatestAbcModel();
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

  Future<void> _fetchLatestAbcModel() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');

      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('abc_models')
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        _abcModel = null;
        await _loadWeek6Fallback();
        setState(() {
          _isLoading = false;
          if (_behaviorCards.isEmpty) {
            _error = 'ABC 모델이 없고 6주차 데이터도 찾을 수 없습니다.';
          }
        });
        return;
      }

      final data = snapshot.docs.first.data();
      setState(() {
        _abcModel = data;
        _isLoading = false;
        _initBehaviorCards();
      });

      if (_behaviorCards.isEmpty) {
        await _loadWeek6Fallback();
        setState(() {});
      }

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      await _loadWeek6Fallback();
      setState(() {
        _error = _behaviorCards.isEmpty ? '데이터 오류: $e' : null;
        _isLoading = false;
      });
    }
  }

  void _initBehaviorCards() {
    if (_abcModel == null) return;

    final behaviorClassifications =
        _abcModel!['behavior_classifications'] as Map<String, dynamic>?;

    if (behaviorClassifications == null || behaviorClassifications.isEmpty) {
      _behaviorCards = [];
    } else {
      _behaviorCards =
          behaviorClassifications.entries
              .map(
                (e) => {
                  'behavior': e.key,
                  'classification': (e.value as String?) ?? '미분류',
                },
              )
              .toList();
    }

    // 초기 자동 추가는 "지연" (기본 true) — 기존 로직은 그대로 두고 게이트만 추가
    if (widget.initialBehavior != null && !widget.deferInitialMarkAsAdded) {
      _globalAddedBehaviors.add(widget.initialBehavior!);
    }

    _addedBehaviors = Set.from(_globalAddedBehaviors);
  }

  Future<void> _loadWeek6Fallback() async {
    if (_behaviorCards.isNotEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final week6Snap =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('week6_behaviors')
                .orderBy('createdAt', descending: true)
                .limit(1)
                .get();

        if (week6Snap.docs.isNotEmpty) {
          final m = week6Snap.docs.first.data();
          final cards = _cardsFromAnyWeek6Payload(m);
          if (cards.isNotEmpty) {
            _behaviorCards = cards;
            return;
          }
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bcJson = prefs.getString('week6_behavior_classifications');
      if (bcJson != null) {
        final decoded = json.decode(bcJson);
        if (decoded is Map<String, dynamic>) {
          final cards = _cardsFromAnyWeek6Payload(decoded);
          if (cards.isNotEmpty) {
            _behaviorCards = cards;
            return;
          }
        }
      }

      final listJson = prefs.getString('week6_behaviors');
      if (listJson != null) {
        final decoded = json.decode(listJson);
        if (decoded is List) {
          final list = decoded.whereType<String>().toList();
          if (list.isNotEmpty) {
            _behaviorCards =
                list
                    .map((b) => {'behavior': b, 'classification': '미분류'})
                    .toList();
          }
        }
      }
    } catch (_) {}
  }

  List<Map<String, String>> _cardsFromAnyWeek6Payload(Map<String, dynamic> m) {
    final bc = m['behavior_classifications'];
    if (bc is Map<String, dynamic> && bc.isNotEmpty) {
      return bc.entries
          .map(
            (e) => {
              'behavior': e.key,
              'classification': (e.value as String?) ?? '미분류',
            },
          )
          .toList();
    }
    final bList = m['behaviors'];
    if (bList is List && bList.isNotEmpty) {
      return bList
          .whereType<String>()
          .map((b) => {'behavior': b, 'classification': '미분류'})
          .toList();
    }
    return const [];
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
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return BehaviorConfirmDialog(
          titleText: '행동 추가',
          highlightText: '[$behavior]',
          messageText: '정말로 추가할까요?',
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
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return BehaviorConfirmDialog(
          titleText: '행동 제거',
          highlightText: '[${behavior}]',
          messageText: '건강한 생활 습관에서 제거하시겠습니까?',
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
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return BehaviorConfirmDialog(
          titleText: '건강한 생활 습관 추가',
          highlightText: '[$behavior]', // 메모 띠 안의 행동 표시
          messageText: '이 행동을 건강한 생활 습관에 추가하시겠습니까??',
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
            color: Colors.white.withOpacity(enabled ? 1 : 0.7),
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
            height: 31,
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
          // 중앙 정렬 안내 문구 (텍스트만)
          const Text(
            '6주차에서 분류한 행동들을 확인해보세요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF263C69),
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
