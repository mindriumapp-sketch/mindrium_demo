import 'package:flutter/material.dart';
import 'package:gad_app_team/features/7th_treatment/week7_final_screen.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/calendar_sheet.dart';
import 'dart:convert';
import 'package:gad_app_team/widgets/eduhome_bg.dart';

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

class Week7CalendarSummaryScreen extends StatefulWidget {
  const Week7CalendarSummaryScreen({super.key});

  @override
  State<Week7CalendarSummaryScreen> createState() =>
      _Week7CalendarSummaryScreenState();
}

class _Week7CalendarSummaryScreenState
    extends State<Week7CalendarSummaryScreen> {
  List<CalendarEvent> _savedEvents = [];
  bool _isLoading = true;

  // 색상 토큰
  static const Color _bluePrimary = Color(0xFF339DF1);
  static const Color _blueDeep = Color(0xFF667EEA);
  static const double _sidePad = 34;

  // 진한 하늘색
  static const Color _matrixBadgeBlue = Color(0xFF8ED7FF);

  @override
  void initState() {
    super.initState();
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList('calendar_events') ?? [];

      // ✅ 여기만 원본 스타일로 되돌림: 하나씩 파싱하고 실패한 것만 버린다
      final List<CalendarEvent> parsed = [];
      for (final eventJson in eventsJson) {
        try {
          final data = jsonDecode(eventJson);
          parsed.add(CalendarEvent.fromJson(data));
        } catch (e) {
          // 파싱 하나 실패해도 전체가 안 죽도록
          debugPrint('캘린더 이벤트 파싱 실패: $e');
        }
      }

      setState(() {
        _savedEvents = parsed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('캘린더 이벤트 로드 실패: $e');
      setState(() => _isLoading = false);
    }
  }

  // 고유 행동 목록
  List<String> _uniqueBehaviors() {
    final s = <String>{};
    for (final e in _savedEvents) {
      s.addAll(e.behaviors);
    }
    final list = s.toList()..sort();
    return list;
  }

  String _ymd(DateTime d) => '${d.month}월 ${d.day}일';

  @override
  Widget build(BuildContext context) {
    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: '7주차 - 캘린더 요약'),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(_bluePrimary),
                  ),
                )
                    : _savedEvents.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                  padding:
                  const EdgeInsets.fromLTRB(0, 20, 0, 24),
                  child: Column(
                    children: [
                      SizedBox(height: _sidePad),
                      CalendarSheet(
                        title: '캘린더 요약',
                        whitePadding: const EdgeInsets.fromLTRB(
                          24,
                          28,
                          24,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding:
                                EdgeInsets.only(bottom: 30),
                                child: Text(
                                  '계획된 건강한 생활 습관들을 확인하세요',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF718096),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8,
                                right: 8,
                                bottom: 20,
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '계획된 행동 일정표',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2D3748),
                                      ),
                                    ),
                                  ),
                                  _countPill(
                                    '${_uniqueBehaviors().length}개 행동',
                                  ),
                                ],
                              ),
                            ),
                            ..._buildBehaviorCards(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
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
                  onNext: () async {
                    //await _saveSession();
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => Week7FinalScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _countPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _matrixBadgeBlue,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _matrixBadgeBlue.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Widget> _buildBehaviorCards() {
    final behaviors = _uniqueBehaviors();
    if (behaviors.isEmpty) return [const SizedBox.shrink()];

    return behaviors.map((b) {
      final related =
      _savedEvents.where((e) => e.behaviors.contains(b)).toList();

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xF0F6FBFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2F0FF)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              b,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: related.map((e) {
                final duration =
                    e.endDate.difference(e.startDate).inDays + 1;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE3ECFF)),
                    boxShadow: const [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_ymd(e.startDate)} ~ ${_ymd(e.endDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF274690),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$duration일',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FF)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: _blueDeep.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFF3E5F5)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: const Color(0xFF1976D2).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '저장된 캘린더 이벤트가 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              '이전 화면에서 캘린더에 추가해보세요',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF718096),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
