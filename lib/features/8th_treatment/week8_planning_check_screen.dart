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

const Color _postItBlue = Color(0xFF3690D9); // #3690D9

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

// 8주차 계획 점검 화면
class Week8PlanningCheckScreen extends StatefulWidget {
  const Week8PlanningCheckScreen({super.key});

  @override
  State<Week8PlanningCheckScreen> createState() =>
      _Week8PlanningCheckScreenState();
}

class _Week8PlanningCheckScreenState extends State<Week8PlanningCheckScreen> {
  final List<String> _addedBehaviors = [];
  final List<String> _newBehaviors = [];
  final List<CalendarEvent> _savedEvents = [];
  bool _isLoading = true;

  final Map<String, bool> _behaviorCheckStates = {};
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
      _isLoading = false;

      _behaviorCheckStates.clear();
      for (final b in [...globalBehaviors, ...globalNewBehaviors]) {
        _behaviorCheckStates[b] = false;
      }
    });

    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];

      setState(() {
        _savedEvents.clear();
        for (final e in eventsJson) {
          final event = CalendarEvent.fromJson(jsonDecode(e));
          _savedEvents.add(event);
          _eventBehaviorCheckStates[event.id] = {
            for (var b in event.behaviors) b: false,
          };
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('캘린더 이벤트 로드 오류: $e');
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
      // ✅ 통일된 배경 위젯 사용
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '8주차 - 계획 점검'),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 30),

                if (allBehaviors.isNotEmpty)
                  _buildPlannedBehaviorsSection(allBehaviors),

                if (_savedEvents.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildCalendarSection(),
                ],

                const SizedBox(height: 40),

                // ✅ 하단 네비 버튼
                NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: '다음',
                  onBack: () => Navigator.pop(context),
                  onNext: _handleNextPressed,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 포스트잇 헤더 + 안내 + 해파리 (그대로)
  Widget _buildHeaderCard() {
    const double bleed = 34; // 좌우 여백과 동일

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-bleed, 0),
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  child: Container(
                    width: 206,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.zero,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '7주차 계획 점검',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 200, // 206 - 6
                  top: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 26,
                    height: 48,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _postItBlue,
                        borderRadius: BorderRadius.zero,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 6,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.90),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _postItBlue.withOpacity(0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                '7주차에서 계획하신 건강한 생활 습관들을\n실제로 실천하셨는지 점검해보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF4A5568),
                  height: 1.6,
                ),
              ),
            ),
            Positioned(
              right: -15,
              bottom: -20,
              child: Image.asset(
                'assets/image/jellyfish_smart.png',
                width: 85,
                height: 85,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 계획된 습관
  Widget _buildPlannedBehaviorsSection(List<String> allBehaviors) => Container(
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
              color: const Color.fromARGB(255, 102, 146, 234).withOpacity(0.35),
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
        ...allBehaviors.asMap().entries.map((entry) {
          final index = entry.key;
          final behavior = entry.value;
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
                  onTap:
                      () => setState(
                        () => _behaviorCheckStates[behavior] = !isChecked,
                      ),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isChecked ? _postItBlue : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isChecked ? _postItBlue : const Color(0xFFCBD5E0),
                        width: 2,
                      ),
                    ),
                    child:
                        isChecked
                            ? const Icon(
                              Icons.check,
                              size: 18,
                              color: Colors.white,
                            )
                            : null,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 229, 238, 255),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 102, 146, 234),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    behavior,
                    style: TextStyle(
                      fontSize: 16,
                      color: isChecked ? _postItBlue : const Color(0xFF2D3748),
                      decoration: isChecked ? TextDecoration.lineThrough : null,
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

  // 캘린더 섹션
  Widget _buildCalendarSection() => Container(
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
              color: const Color.fromARGB(255, 107, 140, 180).withOpacity(0.35),
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
          final duration = event.endDate.difference(event.startDate).inDays + 1;
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
                        '${event.startDate.month}월 ${event.startDate.day}일 ~ ${event.endDate.month}월 ${event.endDate.day}일',
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
                        color: const Color.fromARGB(
                          255,
                          107,
                          140,
                          180,
                        ).withOpacity(0.1),
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
                  final checked =
                      _eventBehaviorCheckStates[event.id]?[b] ?? false;
                  return InkWell(
                    onTap:
                        () => setState(
                          () =>
                              _eventBehaviorCheckStates[event.id]![b] =
                                  !checked,
                        ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              checked ? _postItBlue : const Color(0xFFE2E8F0),
                          width: checked ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: checked ? _postItBlue : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    checked
                                        ? _postItBlue
                                        : const Color(0xFFCBD5E0),
                                width: 2,
                              ),
                            ),
                            child:
                                checked
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
                                color:
                                    checked
                                        ? _postItBlue
                                        : const Color(0xFF718096),
                                decoration:
                                    checked ? TextDecoration.lineThrough : null,
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

  // 다음 버튼 로직
  void _handleNextPressed() {
    final hasChecked =
        _behaviorCheckStates.values.any((v) => v) ||
        _eventBehaviorCheckStates.values.any((m) => m.values.any((v) => v));

    if (hasChecked) {
      final checked = <String>[];
      _behaviorCheckStates.forEach((k, v) {
        if (v) checked.add(k);
      });
      _eventBehaviorCheckStates.forEach((_, m) {
        m.forEach((k, v) {
          if (v && !checked.contains(k)) checked.add(k);
        });
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => Week8EffectivenessScreen(checkedBehaviors: checked),
        ),
      );
    } else {
      BlueBanner.show(context, '다음 화면으로 이동합니다.');
    }
  }
}
