// File: lib/features/7th_treatment/week7_add_display_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/features/7th_treatment/week7_reason_input_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_planning_screen.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/api/week7_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

// Week7 화면 복귀 감지를 위한 RouteObserver
final RouteObserver<PageRoute<dynamic>> week7RouteObserver =
    RouteObserver<PageRoute<dynamic>>();

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

  // 행동 이름 → chip_id 맵 전역 getter
  static Map<String, String> get globalBehaviorToChip =>
      Map<String, String>.from(
        _Week7AddDisplayScreenState._globalBehaviorToChip,
      );
}

class _Week7AddDisplayScreenState extends State<Week7AddDisplayScreen>
    with TickerProviderStateMixin, RouteAware {
  bool _isLoading = true;
  String? _error;

  List<Map<String, String>> _behaviorCards = [];
  Set<String> _addedBehaviors = {};

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late final ApiClient _client;
  late final DiariesApi _diariesApi;
  late final UserDataApi _userDataApi;
  late final Week7Api _week7Api;

  // 공유 전역 상태
  static final Set<String> _globalAddedBehaviors = {};
  static final List<String> _globalNewBehaviors = [];
  static final Map<String, String> _globalBehaviorToChip = {};

  List<Map<String, dynamic>> _customTags = [];
  final Map<String, String> _chipToBehavior = {};
  final Map<String, String> _behaviorToChip = {};
  final Set<String> _addedChipIds = {};

  static const EdgeInsets _listInnerPad = EdgeInsets.symmetric(horizontal: 12);

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    _userDataApi = UserDataApi(_client);
    _week7Api = Week7Api(_client);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _initializeWeek7Data();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // RouteObserver에 등록
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      week7RouteObserver.subscribe(this, route);
    }
  }

  // 다른 화면에서 돌아왔을 때 호출됨
  @override
  void didPopNext() {
    // 화면 복귀 시 백엔드에서 최신 데이터를 다시 로드
    if (!_isLoading && _behaviorCards.isNotEmpty) {
      _refreshWeek7Session();
    }
  }

  Future<void> _refreshWeek7Session() async {
    try {
      final session = await _week7Api.fetchWeek7Session();
      final newChipIds = <String>{};
      final newBehaviors = <String>{};

      if (session != null) {
        final items = session['classification_items'];
        if (items is List) {
          for (final raw in items) {
            if (raw is! Map) continue;
            final chipId = raw['chip_id']?.toString();
            final classification = raw['classification']?.toString();
            if (chipId == null || classification == null) continue;

            newChipIds.add(chipId);

            final behavior =
                _chipToBehavior[chipId] ??
                _customTags
                    .where((tag) => tag['chip_id'] == chipId)
                    .map((tag) => tag['text']?.toString())
                    .firstWhere(
                      (value) => value != null && value.isNotEmpty,
                      orElse: () => null,
                    );

            if (behavior != null) {
              _registerChipBehavior(chipId, behavior);
              newBehaviors.add(behavior);
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _addedChipIds
            ..clear()
            ..addAll(newChipIds);
          _addedBehaviors = newBehaviors;
        });
        Week7AddDisplayScreen.updateGlobalAddedBehaviors(newBehaviors);
      }
    } catch (e) {
      debugPrint('Week7 세션 새로고침 오류: $e');
    }
  }

  @override
  void didUpdateWidget(covariant Week7AddDisplayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncWithGlobalState();
  }

  @override
  void dispose() {
    week7RouteObserver.unsubscribe(this);
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

  Future<void> _initializeWeek7Data() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _loadCustomTags();
      await _loadBehaviorCardsFromLogs();
      await _loadWeek7Session();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_behaviorCards.isNotEmpty) {
          _fadeController.forward();
          _slideController.forward();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '데이터를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCustomTags() async {
    final tags = await _userDataApi.getCustomTags();
    _customTags = tags;
    for (final tag in tags) {
      final chipId = tag['chip_id']?.toString();
      final text = tag['text']?.toString();
      if (chipId != null && text != null && text.isNotEmpty) {
        _registerChipBehavior(chipId, text);
      }
    }
  }

  void _registerChipBehavior(String chipId, String behavior) {
    _chipToBehavior[chipId] = behavior;
    _behaviorToChip[behavior] = chipId;
    _globalBehaviorToChip[behavior] = chipId; // 전역 맵도 업데이트
  }

  Future<void> _loadBehaviorCardsFromLogs() async {
    final allLogs = await _diariesApi.getAllConfrontAvoidLogs();
    if (!mounted) return;
    setState(() {
      _initBehaviorCardsFromLogs(allLogs);
    });
  }

  Future<void> _loadWeek7Session() async {
    final session = await _week7Api.fetchWeek7Session();
    final newChipIds = <String>{};
    final newBehaviors = <String>{};
    final updatedCards = List<Map<String, String>>.from(_behaviorCards);

    if (session != null) {
      final items = session['classification_items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          final chipId = raw['chip_id']?.toString();
          final classification = raw['classification']?.toString();
          if (chipId == null || classification == null) continue;

          newChipIds.add(chipId);

          final behavior =
              _chipToBehavior[chipId] ??
              _customTags
                  .where((tag) => tag['chip_id'] == chipId)
                  .map((tag) => tag['text']?.toString())
                  .firstWhere(
                    (value) => value != null && value.isNotEmpty,
                    orElse: () => null,
                  );

          if (behavior != null) {
            _registerChipBehavior(chipId, behavior);
            newBehaviors.add(behavior);
            final exists = updatedCards.any(
              (card) => card['behavior'] == behavior,
            );
            if (!exists) {
              updatedCards.add({
                'behavior': behavior,
                'classification': classification == 'confront' ? '직면' : '회피',
              });
            }
          }
        }
      }
    }

    updatedCards.sort((a, b) {
      final aOrder = _getClassificationOrder(a['classification'] ?? '');
      final bOrder = _getClassificationOrder(b['classification'] ?? '');
      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }
      return (a['behavior'] ?? '').compareTo(b['behavior'] ?? '');
    });

    setState(() {
      _behaviorCards = updatedCards;
      _addedChipIds
        ..clear()
        ..addAll(newChipIds);
      _addedBehaviors = newBehaviors;
    });
    Week7AddDisplayScreen.updateGlobalAddedBehaviors(newBehaviors);
  }

  Future<String> _ensureChipIdForBehavior(String behavior) async {
    final existing = _behaviorToChip[behavior];
    if (existing != null) return existing;

    for (final tag in _customTags) {
      if (tag['text'] == behavior && tag['chip_id'] != null) {
        final chipId = tag['chip_id'].toString();
        _registerChipBehavior(chipId, behavior);
        return chipId;
      }
    }

    final created = await _userDataApi.createCustomTag(
      text: behavior,
      type: 'CB',
    );
    final chipId = created['chip_id']?.toString();
    if (chipId == null) {
      throw Exception('chip_id 생성 실패');
    }
    _customTags.add(created);
    _registerChipBehavior(chipId, behavior);
    return chipId;
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

    _behaviorCards =
        behaviorMap.entries
            .map((e) => {'behavior': e.key, 'classification': e.value})
            .toList()
          ..sort((a, b) {
            // 정렬 순서: 직면 -> 회피 -> 기타
            final aOrder = _getClassificationOrder(a['classification'] ?? '');
            final bOrder = _getClassificationOrder(b['classification'] ?? '');
            if (aOrder != bOrder) {
              return aOrder.compareTo(bOrder);
            }
            // 같은 분류 내에서는 행동 이름으로 정렬
            return (a['behavior'] ?? '').compareTo(b['behavior'] ?? '');
          });
  }

  int _getClassificationOrder(String classification) {
    switch (classification) {
      case '직면':
        return 1; // 첫 번째
      case '회피':
        return 2; // 두 번째
      default:
        return 3; // 마지막
    }
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
        return CustomPopupDesign(
          title: '건강한 생활 습관 추가',
          highlightText: '[$behavior]',
          message: '이 불안 회피 행동을 건강한 생활 습관에 \n추가하시겠습니까?',
          negativeText: '취소',
          positiveText: '추가',
          onNegativePressed: () => Navigator.of(context).pop(),
          onPositivePressed: () async {
            Navigator.of(context).pop();
            try {
              final chipId = await _ensureChipIdForBehavior(behavior);
              if (!mounted) return;
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (_, __, ___) => Week7ReasonInputScreen(
                        behavior: behavior,
                        chipId: chipId,
                      ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            } catch (e) {
              if (!mounted) return;
              BlueBanner.show(context, '추가 화면으로 이동할 수 없습니다: $e');
            }
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
        return CustomPopupDesign(
          title: '생활 습관 제거',
          highlightText: '[${behavior}]',
          message: '이 행동을 건강한 생활 습관에서 제거하시겠습니까?',
          negativeText: '취소',
          positiveText: '제거',
          onNegativePressed: () => Navigator.of(context).pop(),
          onPositivePressed: () async {
            Navigator.of(context).pop();
            await _removeFromHealthyHabits(behavior);
          },
        );
      },
    );
  }

  Future<void> _removeFromHealthyHabits(String behavior) async {
    try {
      final chipId = await _ensureChipIdForBehavior(behavior);
      await _week7Api.deleteClassificationItem(chipId);

      final newGlobalBehaviors = Set<String>.from(_globalAddedBehaviors)
        ..remove(behavior);
      Week7AddDisplayScreen.updateGlobalAddedBehaviors(newGlobalBehaviors);

      setState(() {
        _addedBehaviors.remove(behavior);
        _addedChipIds.remove(chipId);
      });

      BlueBanner.show(context, '"$behavior"이(가) 건강한 생활 습관에서 제거되었습니다.');
    } catch (e) {
      if (!mounted) return;
      BlueBanner.show(context, '제거에 실패했습니다: $e');
    }
  }

  Future<void> _addConfrontBehavior(String behavior) async {
    if (_addedBehaviors.contains(behavior)) {
      BlueBanner.show(context, '"$behavior"은(는) 이미 추가되어 있습니다.');
      return;
    }

    try {
      final chipId = await _ensureChipIdForBehavior(behavior);
      await _week7Api.upsertClassificationItem(
        chipId: chipId,
        classification: 'confront',
      );

      final updated = Set<String>.from(_globalAddedBehaviors)..add(behavior);
      Week7AddDisplayScreen.updateGlobalAddedBehaviors(updated);

      setState(() {
        _addedBehaviors = Set<String>.from(updated);
        _addedChipIds.add(chipId);
      });

      BlueBanner.show(context, '"$behavior"이(가) 건강한 생활 습관에 추가되었습니다.');
    } catch (e) {
      if (!mounted) return;
      BlueBanner.show(context, '추가에 실패했습니다: $e');
    }
  }

  void _showAddToHealthyHabitsDialog(String behavior) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (context) {
        return CustomPopupDesign(
          title: '건강한 생활 습관 추가',
          highlightText: '[$behavior]', // 메모 띠 안의 행동 표시
          message: '이 불안 직면 행동을 건강한 생활 습관에 추가하시겠습니까??',
          negativeText: '취소',
          positiveText: '추가',
          onNegativePressed: () => Navigator.of(context).pop(),
          onPositivePressed: () async {
            Navigator.of(context).pop();
            await _addConfrontBehavior(behavior);
          },
        );
      },
    );
  }

  // ── 리스트 카드 (표시 로직: 최초=추가하기만 / 확정 후=추가됨+제거하기)
  Widget _buildBehaviorCard(Map<String, String> card, int index) {
    final classification = card['classification'] ?? '';
    final behavior = card['behavior'] ?? '';

    final bool isFacing = classification == '직면';

    // 🎨 상태 기반 컬러 시스템
    final Color pillBg =
        isFacing ? const Color(0xFFE8F5E1) : const Color(0xFFFEE5E8);

    final Color pillText =
        isFacing ? const Color(0xFF2E6B45) : const Color(0xFFD6455F);

    final Color borderColor =
        isFacing ? const Color(0xFFD2E8D2) : const Color(0xFFF5D0D6);

    final Color shadowColor =
        isFacing ? const Color(0x332E6B45) : const Color(0x33D6455F);

    // ⭐️ 정렬을 위한 수직 간격 계산:
    // Pill Container (패딩 상하 4+4 + 폰트 12 ≈ 20) + 중간 SizedBox(10) ≈ 30.0
    const double verticalSpacingForAlignment = 30.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬 유지
        children: [
          // 🔹 좌측 Pill + 텍스트 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔸 상태 Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getClassificationText(classification),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: pillText,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 🔸 행동 내용 (이 텍스트의 상단과 우측 버튼이 수평 정렬됩니다.)
                Text(
                  behavior,
                  style: const TextStyle(
                    color: Color(0xFF263C69),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 우측 버튼 영역
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 🚨 수정된 부분: 행동 내용 텍스트와 수평 정렬하기 위한 공간 추가
              const SizedBox(height: verticalSpacingForAlignment),

              if (_addedBehaviors.contains(behavior)) ...[
                // 🔸 추가됨 badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '추가됨',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // 🔸 제거하기
                GestureDetector(
                  onTap: () => _showRemoveConfirmationDialog(behavior),
                  child: const Text(
                    '제거하기',
                    style: TextStyle(
                      color: Color(0xFFE85D85),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ] else ...[
                // 🔸 추가하기 버튼
                GestureDetector(
                  onTap: () {
                    if (classification == '회피') {
                      _showAddConfirmationDialog(behavior);
                    } else {
                      _showAddToHealthyHabitsDialog(behavior);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, // 크기 축소 유지
                      vertical: 8, // 크기 축소 유지
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF33A4F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '추가하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
          const SizedBox(height: 20),
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
