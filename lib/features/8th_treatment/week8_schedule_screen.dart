import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/8th_treatment/week8_matrix_screen.dart';
import 'package:gad_app_team/widgets/calendar_sheet.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';

/// 캘린더 이벤트 모델
class CalendarEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> behaviors;

  CalendarEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.behaviors,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'behaviors': behaviors,
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'] as String,
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    behaviors: List<String>.from(json['behaviors']),
  );
}

class Week8ScheduleScreen extends StatefulWidget {
  final List<String> behaviorsToKeep;
  const Week8ScheduleScreen({super.key, required this.behaviorsToKeep});

  @override
  State<Week8ScheduleScreen> createState() => _Week8ScheduleScreenState();
}

class _Week8ScheduleScreenState extends State<Week8ScheduleScreen> {
  List<CalendarEvent> _savedEvents = [];
  bool _isLoading = true;

  static const Color bluePrimary = Color(0xFF5DADEC);
  static const Color chipBorderBlue = Color(0xFF7EB9FF);
  static const Color checkedChipFill = Color(0xFFE5F1FF);

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];
      setState(() {
        _savedEvents =
            eventsJson
                .map((e) => CalendarEvent.fromJson(jsonDecode(e)))
                .toList();
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];
      eventsJson.removeWhere((e) {
        try {
          final ev = CalendarEvent.fromJson(jsonDecode(e));
          return ev.id == id;
        } catch (_) {
          return false;
        }
      });
      await prefs.setStringList('calendar_events', eventsJson);
      setState(() => _savedEvents.removeWhere((e) => e.id == id));
      BlueBanner.show(context, '일정이 삭제되었습니다.');
    } catch (_) {
      BlueBanner.show(context, '일정 삭제 중 오류가 발생했습니다.');
    }
  }

  void _addToCalendar(DateTime start, DateTime end) async {
    if (widget.behaviorsToKeep.isEmpty) {
      BlueBanner.show(context, '추가할 행동이 없습니다.');
      return;
    }

    final event = CalendarEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: start,
      endDate: end,
      behaviors: widget.behaviorsToKeep,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];
      eventsJson.add(jsonEncode(event.toJson()));
      await prefs.setStringList('calendar_events', eventsJson);
      setState(() => _savedEvents.add(event));

      BlueBanner.show(context, '일정이 추가되었습니다.');
    } catch (_) {
      BlueBanner.show(context, '일정 추가 중 오류가 발생했습니다.');
    }
  }

  void _showAddEventDialog() {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setS) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text(
                  '캘린더에 추가',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '선택한 건강한 생활 습관들을\n캘린더에 추가하시겠습니까?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF718096),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _dateTile('시작 기간', startDate, () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setS(() {
                          startDate = picked;
                          if (endDate.isBefore(startDate)) endDate = startDate;
                        });
                      }
                    }),
                    const SizedBox(height: 16),
                    _dateTile('종료 기간', endDate, () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate,
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setS(() => endDate = picked);
                    }),
                  ],
                ),
                actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Color(0xFF718096)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _addToCalendar(startDate, endDate);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: bluePrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
          ),
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${date.year}년 ${date.month}월 ${date.day}일'),
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Color(0xFF718096),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 선택된 행동 칩 리스트
  Widget _selectedBehaviorsChips() {
    final items = widget.behaviorsToKeep;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child:
          items.isEmpty
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
                children:
                    items.map((b) {
                      return ConstrainedBox(
                        constraints: const BoxConstraints.tightFor(
                          width: 239,
                          height: 52,
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: checkedChipFill,
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
  Widget build(BuildContext context) {
    return EduhomeBg(
      // ✅ 통일된 배경 위젯으로 감싸기
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: '8주차 - 스케줄 관리'),

        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 20, bottom: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // 재사용 캘린더 시트
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
                                      e.endDate.difference(e.startDate).inDays +
                                      1;
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
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${e.startDate.month}월 ${e.startDate.day}일 ~ ${e.endDate.month}월 ${e.endDate.day}일 ($duration일)',
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
                                              borderRadius:
                                                  BorderRadius.circular(4),
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
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],

                              const SizedBox(height: 8),

                              // 2/3 폭 버튼
                              Center(
                                child: FractionallySizedBox(
                                  widthFactor: 0.66,
                                  child: ElevatedButton(
                                    onPressed:
                                        widget.behaviorsToKeep.isNotEmpty
                                            ? _showAddEventDialog
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: bluePrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(34, 8, 34, 16),
          child: NavigationButtons(
            leftLabel: '이전',
            rightLabel: '다음',
            onBack: () => Navigator.pop(context),
            onNext:
                () => Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder:
                        (_, __, ___) => Week8MatrixScreen(
                          behaviorsToKeep: widget.behaviorsToKeep,
                        ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                ),
          ),
        ),
      ),
    );
  }
}
