// File: lib/features/8th_treatment/week8_planning_check_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/7th_treatment/week7_add_display_screen.dart';
import 'package:gad_app_team/features/8th_treatment/week8_effectiveness_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';
// import 'package:gad_app_team/widgets/jellyfish_banner.dart'; // 실제 경로에 맞게 열어줘

const Color _postItBlue = Color(0xFF3690D9);

// 캘린더 이벤트 모델 (week7이랑 동일하게)
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

class Week8PlanningCheckScreen extends StatefulWidget {
  const Week8PlanningCheckScreen({super.key});

  @override
  State<Week8PlanningCheckScreen> createState() =>
      _Week8PlanningCheckScreenState();
}

class _Week8PlanningCheckScreenState extends State<Week8PlanningCheckScreen> {
  // 7주차에서 가져온 행동들
  final List<String> _addedBehaviors = [];
  final List<String> _newBehaviors = [];

  // week7에서 저장한 캘린더 이벤트들
  final List<CalendarEvent> _savedEvents = [];

  bool _isLoading = true;

  // 행동 체크 상태
  final Map<String, bool> _behaviorCheckStates = {};

  // 이벤트별 행동 체크 상태 (eventId -> {behavior: checked})
  final Map<String, Map<String, bool>> _eventBehaviorCheckStates = {};

  @override
  void initState() {
    super.initState();
    _loadPlannedBehaviors();
  }

  void _loadPlannedBehaviors() {
    final globalBehaviors = Week7AddDisplayScreen.globalAddedBehaviors;
    final globalNewBehaviors = Week7AddDisplayScreen.globalNewBehaviors;

    setState(() {
      _addedBehaviors
        ..clear()
        ..addAll(globalBehaviors);
      _newBehaviors
        ..clear()
        ..addAll(globalNewBehaviors);

      _behaviorCheckStates.clear();
      for (final b in [...globalBehaviors, ...globalNewBehaviors]) {
        _behaviorCheckStates[b] = false;
      }

      _isLoading = false;
    });

    _loadSavedEvents();
  }

  // 저장된 이벤트 다 불러오기 (깨진 건 건너뛰기) → 원본 로직과 동일
  Future<void> _loadSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];

      final List<CalendarEvent> parsed = [];
      final Map<String, Map<String, bool>> eventCheckStates = {};

      for (final e in eventsJson) {
        try {
          final data = jsonDecode(e);
          final event = CalendarEvent.fromJson(data);
          parsed.add(event);

          eventCheckStates[event.id] = {
            for (final b in event.behaviors) b: false,
          };
        } catch (err) {
          debugPrint('이벤트 파싱 오류: $err');
        }
      }

      if (mounted) {
        setState(() {
          _savedEvents
            ..clear()
            ..addAll(parsed);
          _eventBehaviorCheckStates
            ..clear()
            ..addAll(eventCheckStates);
        });
      }
    } catch (e) {
      debugPrint('캘린더 이벤트 로드 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: '8주차 - 계획 점검'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allBehaviors = [..._addedBehaviors, ..._newBehaviors];

    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '8주차 - 계획 점검'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 네가 쓰던 안내 위젯
                      JellyfishBanner(
                        message:
                        '7주차에서 계획하신 건강한 생활 습관들을 실제로 실천하셨는지 점검해보세요!',
                      ),
                      const SizedBox(height: 30),

                      if (allBehaviors.isNotEmpty)
                        _buildPlannedBehaviorsSection(allBehaviors),

                      if (_savedEvents.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildCalendarSection(),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: '다음',
                  onBack: () => Navigator.pop(context),
                  onNext: _handleNextPressed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 위쪽: 계획된 행동
  Widget _buildPlannedBehaviorsSection(List<String> allBehaviors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계획된 건강한 생활 습관',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF).withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                const Color.fromARGB(255, 102, 146, 234).withOpacity(0.35),
              ),
            ),
            child: const Text(
              '실제로 실천하신 행동에 체크해주세요.\n체크된 행동은 효과를 평가하고 유지 여부를 결정합니다.',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 102, 146, 234),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...allBehaviors.map((behavior) {
            final isChecked = _behaviorCheckStates[behavior] ?? false;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isChecked ? _postItBlue : const Color(0xFFE2E8F0),
                  width: isChecked ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        _behaviorCheckStates[behavior] = !isChecked;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isChecked ? _postItBlue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isChecked
                              ? _postItBlue
                              : const Color(0xFFCBD5E0),
                          width: 2,
                        ),
                      ),
                      child: isChecked
                          ? const Icon(
                        Icons.check,
                        size: 18,
                        color: Colors.white,
                      )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      behavior,
                      style: TextStyle(
                        fontSize: 16,
                        color:
                        isChecked ? _postItBlue : const Color(0xFF2D3748),
                        decoration:
                        isChecked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 아래쪽: 캘린더에 추가된 일정들 (→ “다 보여준다”가 원래 로직)
  Widget _buildCalendarSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '캘린더에 추가된 일정',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 230, 245, 255).withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color:
                const Color.fromARGB(255, 107, 140, 180).withOpacity(0.35),
              ),
            ),
            child: const Text(
              '캘린더에 등록된 일정의 행동들을 보고\n실천 여부를 체크해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 107, 140, 180),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._savedEvents.map((event) {
            final duration =
                event.endDate.difference(event.startDate).inDays + 1;
            final behaviorStates = _eventBehaviorCheckStates[event.id] ?? {};
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${event.startDate.month}월 ${event.startDate.day}일 ~ '
                              '${event.endDate.month}월 ${event.endDate.day}일',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 107, 140, 180)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$duration일',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 107, 140, 180),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...event.behaviors.map((b) {
                    final checked = behaviorStates[b] ?? false;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _eventBehaviorCheckStates[event.id]![b] = !checked;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: checked
                                ? _postItBlue
                                : const Color(0xFFE2E8F0),
                            width: checked ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: checked
                                    ? _postItBlue
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: checked
                                      ? _postItBlue
                                      : const Color(0xFFCBD5E0),
                                  width: 2,
                                ),
                              ),
                              child: checked
                                  ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(
                                  color: checked
                                      ? _postItBlue
                                      : const Color(0xFF718096),
                                  decoration: checked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 다음 버튼
  void _handleNextPressed() {
    final hasChecked =
        _behaviorCheckStates.values.any((v) => v) ||
            _eventBehaviorCheckStates.values
                .any((m) => m.values.any((v) => v));

    if (hasChecked) {
      final checked = <String>[];

      _behaviorCheckStates.forEach((behavior, isChecked) {
        if (isChecked) checked.add(behavior);
      });

      _eventBehaviorCheckStates.forEach((_, behaviorMap) {
        behaviorMap.forEach((behavior, isChecked) {
          if (isChecked && !checked.contains(behavior)) {
            checked.add(behavior);
          }
        });
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              Week8EffectivenessScreen(checkedBehaviors: checked),
        ),
      );
    } else {
      BlueBanner.show(context, '다음 화면으로 이동합니다.');
    }
  }
}
