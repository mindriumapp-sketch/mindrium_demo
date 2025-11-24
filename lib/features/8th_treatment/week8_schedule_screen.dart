import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/8th_treatment/week8_user_journey_screen.dart';
import 'package:gad_app_team/widgets/calendar_sheet.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';
import 'package:gad_app_team/features/7th_treatment/week7_add_display_screen.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/week7_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// 캘린더 이벤트 모델
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

  // 백엔드 ScheduleEventResponse에서 변환
  factory CalendarEvent.fromApiResponse(Map<String, dynamic> json) {
    final startDateStr = json['start_date']?.toString() ?? '';
    final endDateStr = json['end_date']?.toString() ?? '';
    final tasks = json['tasks'] as List<dynamic>? ?? [];
    
    return CalendarEvent(
      id: json['event_id']?.toString() ?? '',
      startDate: DateTime.parse(startDateStr),
      endDate: DateTime.parse(endDateStr),
      behaviors: tasks
          .map((task) => task is Map ? task['label']?.toString() : null)
          .whereType<String>()
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }
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

  // API 클라이언트
  late final ApiClient _apiClient;
  late final Week7Api _week7Api;

  static const Color bluePrimary = Color(0xFF5DADEC);
  static const Color chipBorderBlue = Color(0xFF7EB9FF);
  static const Color checkedChipFill = Color(0xFFE5F1FF);

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(tokens: TokenStorage());
    _week7Api = Week7Api(_apiClient);
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    try {
      final apiEvents = await _week7Api.listScheduleEvents();
      final List<CalendarEvent> parsed = [];
      for (final eventData in apiEvents) {
        try {
          parsed.add(CalendarEvent.fromApiResponse(eventData));
        } catch (e) {
          debugPrint('이벤트 파싱 오류: $e');
        }
      }
      if (mounted) {
        setState(() {
          _savedEvents = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('캘린더 이벤트 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      await _week7Api.deleteScheduleEvent(id);
      if (mounted) {
        setState(() => _savedEvents.removeWhere((e) => e.id == id));
        BlueBanner.show(context, '일정이 삭제되었습니다.');
      }
    } catch (e) {
      if (!mounted) return;
      BlueBanner.show(context, '일정 삭제 중 오류가 발생했습니다: $e');
    }
  }

  // ✅ 다이얼로그에서 선택된 행동을 넘겨서 저장하게 변경
  void _addToCalendar(
      List<String> chosenBehaviors,
      DateTime start,
      DateTime end,
      ) async {
    if (chosenBehaviors.isEmpty) {
      BlueBanner.show(context, '추가할 행동이 없습니다.');
      return;
    }

    try {
      final duration = end.difference(start).inDays + 1;

      // 행동 이름을 tasks 형식으로 변환 (chip_id 포함)
      final behaviorToChip = Week7AddDisplayScreen.globalBehaviorToChip;
      final tasks = chosenBehaviors
          .map((behavior) => {
                'label': behavior,
                'chip_id': behaviorToChip[behavior], // 추가된 행동이면 chip_id 전달
              })
          .toList();

      final response = await _week7Api.createScheduleEvent(
        startDate: start,
        endDate: end,
        tasks: tasks,
      );

      // 응답에서 생성된 이벤트로 업데이트
      final savedEvent = CalendarEvent.fromApiResponse(response);
      if (mounted) {
        setState(() => _savedEvents.add(savedEvent));
        BlueBanner.show(
          context,
          '${chosenBehaviors.length}개의 행동이 '
              '${start.month}월 ${start.day}일부터 ${end.month}월 ${end.day}일까지 '
              '(${duration}일간) 캘린더에 추가되었습니다.',
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      if (!mounted) return;
      BlueBanner.show(context, '캘린더에 추가하는데 실패했습니다: $e');
    }
  }

  // ✅ 위에서 네가 준 “펼쳐지는 행동 선택” 다이얼로그 스타일로 교체
  void _showAddEventDialog() {
    // 다이얼로그 안에서 쓸 초기값들
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    final allBehaviors = [...widget.behaviorsToKeep];
    // 기본은 전부 체크
    final Map<String, bool> selected = {
      for (final b in allBehaviors) b: false,
    };

    bool isExpanded = true; // 처음엔 열려있게

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, innerSetState) {
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

                    // 헤더 박스 (접히는 부분)
                    GestureDetector(
                      onTap: () {
                        innerSetState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
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
                                horizontal: 12,
                                vertical: 10,
                              ),
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // 선택된 행동들만 모으기
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
                          backgroundColor: const Color(0xFF8ED7FF),
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: '8주차 - 스케줄 관리'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
          child: Column(
            children: [
              // 위쪽: 스크롤 되는 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 20, bottom: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
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

                            // ✅ 저장된 캘린더 이벤트 UI
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
                                  onPressed: widget.behaviorsToKeep.isNotEmpty
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

              // 아래: 항상 바닥에 붙는 네비게이션
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: '다음',
                  onBack: () => Navigator.pop(context),
                  onNext: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const Week8UserJourneyScreen(),
                      transitionDuration: Duration.zero,
                      reverseTransitionDuration: Duration.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
