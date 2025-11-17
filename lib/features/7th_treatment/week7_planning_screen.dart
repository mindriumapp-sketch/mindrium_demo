// File: features/7th_treatment/week7_planning_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/7th_treatment/week7_add_display_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_calendar_summary_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gad_app_team/widgets/behavior_confirm_dialog.dart';
import 'package:gad_app_team/widgets/calendar_sheet.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

// ─────────────────────────────────────────────
// 캘린더 이벤트 모델
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'behaviors': behaviors,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      behaviors: List<String>.from(json['behaviors']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────
class Week7PlanningScreen extends StatefulWidget {
  const Week7PlanningScreen({super.key});

  @override
  State<Week7PlanningScreen> createState() => _Week7PlanningScreenState();
}

class _Week7PlanningScreenState extends State<Week7PlanningScreen> {
  // 레이아웃 상수
  static const double _sidePadding = 34; // 좌우 여백
  static const double _ringOverhang = 16; // 캘린더시트 위 고리 높이

  // Week7AddDisplayScreen 전역 상태와 싱크될 목록들
  final TextEditingController _newBehaviorController = TextEditingController();
  final List<String> _addedBehaviors = [];
  final List<String> _newBehaviors = [];

  // 로컬에 저장된 캘린더 이벤트
  final List<CalendarEvent> _savedEvents = [];

  // 사용자 이름/핵심가치
  String? _userName;
  String? _userCoreValue;

  static const Color _bluePrimary = Color(0xFF5DADEC);
  static const Color _chipBorderBlue = Color(0xFF7EB9FF);
  static const Color _checkedChipFill = Color(0xFFE5F1FF);

  @override
  void initState() {
    super.initState();
    _loadAddedBehaviors();
    _loadSavedEvents();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 복귀 시 전역 상태 동기화
    _loadAddedBehaviors();
  }

  // ───────────────── 로드/세이브/삭제 로직 ─────────────────
  void _loadAddedBehaviors() {
    final globalBehaviors = Week7AddDisplayScreen.globalAddedBehaviors;
    final globalNewBehaviors = Week7AddDisplayScreen.globalNewBehaviors;

    setState(() {
      _addedBehaviors
        ..clear()
        ..addAll(globalBehaviors);
      _newBehaviors
        ..clear()
        ..addAll(globalNewBehaviors);
    });
  }

  Future<void> _loadSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];
      setState(() {
        _savedEvents.clear();
        for (final eventJson in eventsJson) {
          try {
            final eventData = jsonDecode(eventJson);
            _savedEvents.add(CalendarEvent.fromJson(eventData));
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('캘린더 이벤트 로드 오류: $e');
    }
  }

  Future<void> _saveEvent(CalendarEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];
      eventsJson.add(jsonEncode(event.toJson()));
      await prefs.setStringList('calendar_events', eventsJson);
      setState(() => _savedEvents.add(event));
    } catch (e) {
      debugPrint('캘린더 이벤트 저장 오류: $e');
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];

      eventsJson.removeWhere((eventJson) {
        try {
          final eventData = jsonDecode(eventJson);
          return eventData['id'] == eventId;
        } catch (_) {
          return false;
        }
      });

      await prefs.setStringList('calendar_events', eventsJson);
      setState(() => _savedEvents.removeWhere((e) => e.id == eventId));
    } catch (e) {
      debugPrint('캘린더 이벤트 삭제 오류: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      // UserProvider에서 사용자 이름 가져오기
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _userName = userProvider.userName;
      
      // 핵심 가치는 UserDataApi를 통해 가져오기
      final apiClient = ApiClient(tokens: TokenStorage());
      final userDataApi = UserDataApi(apiClient);
      final coreValueData = await userDataApi.getCoreValue();
      _userCoreValue =
          (coreValueData?['value_goal'] ?? coreValueData?['core_value']) as String?;
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('사용자 데이터 로드 실패: $e');
    }
  }

  // ───────────────── 행동 추가/삭제 및 다이얼로그 ─────────────────
  void _addNewBehavior() {
    final behavior = _newBehaviorController.text.trim();
    if (behavior.isNotEmpty) {
      _showAddBehaviorDialog(behavior);
    }
  }

  void _showAddBehaviorDialog(String behavior) {
    final sb = StringBuffer();
    if (_userName != null) {
      sb.writeln('$_userName님, 이 행동을 건강한 생활 습관으로서 실천하시고자 하시는군요.');
    } else {
      sb.writeln('이 행동을 건강한 생활 습관으로서 실천하시고자 하시는군요.');
    }
    sb.writeln();

    if (_userCoreValue != null) {
      if (_userName != null) {
        sb.writeln('$_userName님께서 소중히 여기는 가치는 "$_userCoreValue"입니다.');
      } else {
        sb.writeln('소중히 여기는 가치는 $_userCoreValue입니다.');
      }
      sb.writeln();
      sb.writeln('이 가치를 실현하기 위해 추가하시는 행동이 도움이 될 것 같다면 추가해주세요.');
      sb.writeln();
      sb.writeln('아니라면 가치에 더 맞도록 조금 바꿔봤을 때 어떤 행동이 더 나을지 생각해보아요.');
    } else {
      sb.writeln('이 행동이 건강한 생활 습관으로 도움이 될 것 같다면 추가해주세요.');
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) {
        return BehaviorConfirmDialog(
          titleText: '건강한 생활 습관 추가',
          highlightText: '"$behavior"',
          messageText: sb.toString(),
          negativeText: '추가하지 않을래요',
          positiveText: '추가할게요',
          onNegativePressed: () {
            Navigator.of(context).pop();
            _newBehaviorController.clear();
          },
          onPositivePressed: () {
            Navigator.of(context).pop();
            _confirmAddBehavior(behavior);
          },
          badgeBgAsset: 'assets/image/popup1.png',
          memoBgAsset: 'assets/image/popup2.png',
        );
      },
    );
  }

  void _confirmAddBehavior(String behavior) {
    final newGlobalBehaviors = List<String>.from(_newBehaviors)..add(behavior);
    Week7AddDisplayScreen.updateGlobalNewBehaviors(newGlobalBehaviors);

    setState(() {
      _newBehaviors.add(behavior);
      _newBehaviorController.clear();
    });

    BlueBanner.show(context, '"$behavior"이(가) 추가되었습니다.');
  }

  void _removeAddedBehavior(String behavior) {
    final newGlobalBehaviors = Set<String>.from(_addedBehaviors)..remove(behavior);
    Week7AddDisplayScreen.updateGlobalAddedBehaviors(newGlobalBehaviors);

    setState(() {
      _addedBehaviors.remove(behavior);
    });

    BlueBanner.show(context, '행동이 제거되었습니다.');
  }

  void _removeNewBehavior(String behavior) {
    final newGlobalBehaviors = List<String>.from(_newBehaviors)..remove(behavior);
    Week7AddDisplayScreen.updateGlobalNewBehaviors(newGlobalBehaviors);

    setState(() {
      _newBehaviors.remove(behavior);
    });

    BlueBanner.show(context, '행동이 제거되었습니다.');
  }

  // ───────────────── 캘린더 다이얼로그 (선택 가능하게 수정) ─────────────────
  void _showCalendarDialog() {
    // 현재 행동들
    final allBehaviors = [..._addedBehaviors, ..._newBehaviors];

    if (allBehaviors.isEmpty) {
      BlueBanner.show(context, '추가할 행동이 없습니다.');
      return;
    }

    // 다이얼로그 내부 선택 상태
    final Map<String, bool> selected = {
      for (final b in allBehaviors) b: false, // 기본으로 전부 체크
    };

    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // ↓ 펼치기/접기 상태
            bool isExpanded = true;

            // 근데 StatefulBuilder 안에서 지역변수로 하면 매빌드마다 초기화되잖아?
            // 그래서 위에 선언 말고, 아래 return 안에 하나 더 감싸서
            // 또 다른 StatefulBuilder 쓰는 방식도 있지만,
            // 여기서는 간단히 ValueNotifier 스타일로 처리해주자…
            // …라고 하기엔 길어지니까, 그냥 이 StatefulBuilder 안에서
            // isExpanded를 외부로 빼는 대신, 아래처럼 또 한 번 StatefulBuilder 감싸줄게.

            return StatefulBuilder(
              builder: (context, innerSetState) {
                // 실제 UI
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  title: const Text(
                    '캘린더에 추가',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            '추가할 행동을 고르고\n기간을 선택해주세요.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF718096),
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ─── 현재 선택된 행동들 헤더 박스 ───
                        GestureDetector(
                          onTap: () {
                            innerSetState(() {
                              isExpanded = !isExpanded;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF8ED7FF)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '현재 선택된 행동들',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3748),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF2D3748),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ─── 펼쳐졌을 때만 행동 리스트 ───
                        if (isExpanded) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allBehaviors.map((b) {
                              final bool isOn = selected[b] ?? false;
                              return GestureDetector(
                                onTap: () {
                                  innerSetState(() {
                                    selected[b] = !isOn;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isOn
                                        ? const Color(0xFF8ED7FF)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF8ED7FF),
                                    ),
                                    boxShadow: isOn
                                        ? [
                                      BoxShadow(
                                        color: const Color(0xFF8ED7FF)
                                            .withOpacity(0.30),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                        : null,
                                  ),
                                  child: Text(
                                    b,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isOn
                                          ? Colors.white
                                          : const Color(0xFF2D3748),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // 시작 기간
                        _dateTile('시작 기간', startDate, () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            innerSetState(() {
                              startDate = date;
                              if (endDate.isBefore(startDate)) {
                                endDate = startDate;
                              }
                            });
                          }
                        }),
                        const SizedBox(height: 12),

                        // 종료 기간
                        _dateTile('종료 기간', endDate, () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            innerSetState(() {
                              endDate = date;
                            });
                          }
                        }),
                      ],
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              '취소',
                              style: TextStyle(
                                color: Color(0xFF8ED7FF),
                                fontWeight: FontWeight.w900
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final chosen = selected.entries
                                  .where((e) => e.value)
                                  .map((e) => e.key)
                                  .toList();

                              if (chosen.isEmpty) {
                                BlueBanner.show(context, '하나 이상 선택해주세요.');
                                return;
                              }

                              Navigator.of(context).pop();
                              _addToCalendar(chosen, startDate, endDate);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF8ED7FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '추가',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  // ───────────────── 날짜 타일 ─────────────────
  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8ED7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8ED7FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8ED7FF)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8ED7FF).withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${date.year}년 ${date.month}월 ${date.day}일',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ 다이얼로그에서 선택한 행동만 받도록 수정된 버전
  void _addToCalendar(
      List<String> behaviors,
      DateTime startDate,
      DateTime endDate,
      ) async {
    if (behaviors.isEmpty) {
      BlueBanner.show(context, '추가할 행동이 없습니다.');
      return;
    }

    final duration = endDate.difference(startDate).inDays + 1;

    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: startDate,
      endDate: endDate,
      behaviors: behaviors,
      createdAt: DateTime.now(),
    );

    await _saveEvent(event);

    BlueBanner.show(
      context,
      '${behaviors.length}개의 행동이 '
          '${startDate.month}월 ${startDate.day}일부터 ${endDate.month}월 ${endDate.day}일까지 '
          '(${duration}일간) 캘린더에 추가되었습니다.',
      duration: const Duration(seconds: 4),
    );
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '7주차 - 계획 세우기'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 20, bottom: 32),
            child: Column(
              children: [
                _buildHealthyHabitsSection(),
                const SizedBox(height: _sidePadding + _ringOverhang),
                CalendarSheet(
                  title: '캘린더에 추가',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '현재 선택된 행동들:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _selectedBehaviorsChips(),
                      const SizedBox(height: 24),

                      if (_savedEvents.isNotEmpty) ...[
                        const Text(
                          '저장된 캘린더 이벤트',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._savedEvents.map((e) {
                          final duration =
                              e.endDate.difference(e.startDate).inDays + 1;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${e.startDate.month}월 ${e.startDate.day}일 ~ '
                                            '${e.endDate.month}월 ${e.endDate.day}일 ($duration일)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _deleteEvent(e.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFCBD5E0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '행동: ${e.behaviors.join(', ')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF718096),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 8),
                      Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.66,
                          child: ElevatedButton(
                            onPressed: (_addedBehaviors.isNotEmpty ||
                                _newBehaviors.isNotEmpty)
                                ? _showCalendarDialog
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _bluePrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              '캘린더에 추가하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: NavigationButtons(
            leftLabel: '이전',
            rightLabel: '다음',
            onBack: () => Navigator.pop(context),
            onNext: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) =>
                  const Week7CalendarSummaryScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────
  // 상단 “건강한 생활 습관” 카드
  Widget _buildHealthyHabitsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sidePadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFA1CEDF).withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              '건강한 생활 습관',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B3A57),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '추가된 행동을 확인하고, 새로운 행동을 \n입력해보세요.',
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                color: Color(0xFF356D91),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_addedBehaviors.isNotEmpty) ...[
                    const Text(
                      '추가된 행동들',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._addedBehaviors.map((behavior) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 234, 245, 252),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF33A4F0).withOpacity(0.28),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF33A4F0),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                behavior,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeAddedBehavior(behavior),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    '건강한 행동 추가',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newBehaviorController,
                          decoration: InputDecoration(
                            hintText: '새로운 건강한 생활 습관을 입력하세요',
                            hintStyle: const TextStyle(
                              color: Color(0xFFA0AEC0),
                              fontSize: 12,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2E8F0),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _bluePrimary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _addNewBehavior,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _bluePrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_newBehaviors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ..._newBehaviors.map((behavior) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xF0F6FBFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2196F3).withOpacity(0.28),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_circle,
                              color: Color(0xFF2196F3),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                behavior,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF2D3748),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _removeNewBehavior(behavior),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E0),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 선택된 행동 칩
  Widget _selectedBehaviorsChips() {
    final items = [..._addedBehaviors, ..._newBehaviors];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: items.isEmpty
          ? const Center(
        child: Text(
          '선택된 행동이 없습니다.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFFA0AEC0),
            fontStyle: FontStyle.italic,
          ),
        ),
      )
          : Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: items.map((b) {
          return ConstrainedBox(
            constraints: const BoxConstraints.tightFor(
              width: 239,
              height: 52,
            ),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _checkedChipFill,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: _chipBorderBlue,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _chipBorderBlue.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                b,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _newBehaviorController.dispose();
    super.dispose();
  }
}
