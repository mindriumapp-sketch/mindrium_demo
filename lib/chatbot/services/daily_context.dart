// lib/services/daily_context.dart
/// ✅ 주차별 요약 및 앵커(최근 활동/일기) 생성을 담당하는 유틸 클래스
import 'dart:math';

class DailyContext {
  /// ✅ 주차별 대표 활동명 (fallback 용)
  static const Map<int, String> weekActivityMap = {
    1: '디지털 치료기기 적응 및 자기관리 연습',
    2: '걱정 일기(ABC 모델) 작성 및 감정 탐색',
    3: '자동사고 탐색 및 사고 전환 연습',
    4: '대안적 사고를 행동으로 옮기는 실천 연습',
    5: '불안 직면 및 회피 행동 줄이기',
    6: '도전 행동 피드백 및 자기효능감 강화',
    7: '생활습관 루틴 점검 및 조절 연습',
    8: '8주간 활동 회고 및 자기이해 강화',
  };

  // ✅ 안전한 중첩 접근
  static dynamic safeGet(Map<String, dynamic>? data, List<String> path) {
    dynamic current = data;
    for (final key in path) {
      if (current is Map && current.containsKey(key)) {
        current = current[key];
      } else if (current is List) {
        final idx = int.tryParse(key);
        if (idx != null && idx >= 0 && idx < current.length) {
          current = current[idx];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }

  // ✅ 안전한 List 변환
  static List<Map<String, dynamic>> _asList(dynamic src) =>
      (src is List) ? src.whereType<Map<String, dynamic>>().toList() : [];

  // ✅ 안전한 날짜 파싱
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  // ✅ 문자열 날짜 변환
  static String _toLocalReadable(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  // ✅ 주차별 컨텍스트 생성 (주제별 대표 데이터 자동 매칭)
  static Map<String, dynamic> buildContextForWeek(
      Map<String, dynamic> user, int week) {
    final diaries = _asList(user['diaries']);
    final tags = _asList(user['customTags']);
    final habits = _asList(user['habits']);
    final relax = _asList(user['relaxationTasks']);
    final surveys = _asList(user['surveys']);
    final screen = _asList(user['screenTime']);
    final worries = _asList(user['worryGroups']);

    List<Map<String, dynamic>> selected = [];

    switch (week) {
      case 1:
        selected = relax.take(2).toList();
        break;
      case 2:
        selected = diaries
            .where((d) => safeGet(d, ['activatingEvents']) != null)
            .take(2)
            .toList();
        break;
      case 3:
      case 4:
        selected = tags
            .where((t) => (t['type'] as String?)?.startsWith('B') ?? false)
            .take(3)
            .toList();
        break;
      case 5:
      case 6:
        selected = habits.take(2).toList();
        break;
      case 7:
        selected = screen.isNotEmpty ? screen : relax.take(1).toList();
        break;
      case 8:
        selected = surveys.take(2).toList();
        break;
      default:
        selected = diaries.take(1).toList();
    }

    // ✅ 최신순 정렬
    selected.sort((a, b) {
      final da = _parseDate(a['updatedAt'] ??
          a['createdAt'] ??
          a['endTime'] ??
          a['startTime'] ??
          a['date']);
      final db = _parseDate(b['updatedAt'] ??
          b['createdAt'] ??
          b['endTime'] ??
          b['startTime'] ??
          b['date']);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    // ✅ 표시 텍스트 후보
    final summary = selected.map((e) {
      return e['name'] ??
          e['behaviorText'] ??
          e['description'] ??
          e['thought'] ??
          e['title'] ??
          (e['relaxationScores'] != null
              ? '이완 점수 ${e['relaxationScores']}점'
              : null);
    }).whereType<String>().toList();

    return {
      'week': week,
      'topic': weekActivityMap[week] ?? '주차별 활동',
      'contextItems': summary,
      'raw': selected,
    };
  }

  /// ✅ 주차 단위 요약 (날짜 기반 자동 필터링)
  static String buildWeekSummary(Map<String, dynamic> user, int currentWeek) {
    final createdAt = _parseDate(user['createdAt']);
    if (createdAt == null) return '(시작일 정보가 없습니다.)';

    final weekStart = createdAt.add(Duration(days: (currentWeek - 1) * 7));
    final weekEnd = weekStart.add(const Duration(days: 7));

    bool _inWeek(Map<String, dynamic> x) {
      final d = _parseDate(x['updatedAt'] ??
          x['createdAt'] ??
          x['startTime'] ??
          x['endTime'] ??
          x['date']);
      return d != null && !d.isBefore(weekStart) && d.isBefore(weekEnd);
    }

    final diaries = _asList(user['diaries']).where(_inWeek).toList();
    final relax = _asList(user['relaxationTasks']).where(_inWeek).toList();
    final worries = _asList(user['worryGroups']).where(_inWeek).toList();
    final habits = _asList(user['habits']).where(_inWeek).toList();
    final screens = _asList(user['screenTime']).where(_inWeek).toList();
    final surveys = _asList(user['surveys']).where(_inWeek).toList();

    final buffer = StringBuffer();
    buffer.writeln('이번 주(${currentWeek}주차)는 "${weekActivityMap[currentWeek] ?? '활동'}"을 중심으로 진행되었어요.');

    if (relax.isNotEmpty) {
      final scores = relax
          .map((t) => (t['relaxationScores'] ?? 0))
          .whereType<num>()
          .toList();
      if (scores.isNotEmpty) {
        final avg = (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1);
        buffer.writeln('• 이완 훈련 ${relax.length}회 (평균 점수 $avg점)');
      }
    }
    if (diaries.isNotEmpty) {
      buffer.writeln('• 걱정 일기 ${diaries.length}회 작성');
    }
    if (worries.isNotEmpty) {
      buffer.writeln('• 주요 걱정 주제: ${worries.map((x) => x['groupName']).join(', ')}');
    }
    if (habits.isNotEmpty) {
      buffer.writeln('• 습관/행동 기록 ${habits.length}회');
    }
    if (screens.isNotEmpty) {
      final total = screens
          .map((x) => (x['durationMinutes'] ?? 0))
          .whereType<num>()
          .fold<num>(0, (a, b) => a + b);
      buffer.writeln('• 스크린타임 총 ${total.round()}분');
    }
    if (surveys.isNotEmpty) {
      buffer.writeln('• 설문 참여: ${surveys.map((s) => s['title']).join(', ')}');
    }

    return buffer.isEmpty ? '(이번 주 기록이 아직 없습니다.)' : buffer.toString().trim();
  }

  /// ✅ 최신 앵커: 가장 최근 활동을 기준으로 생성
  static String buildLatestAnchor(Map<String, dynamic> user) {
    final diaries = _asList(user['diaries']);
    final relax = _asList(user['relaxationTasks']);
    final tags = _asList(user['customTags']);
    final habits = _asList(user['habits']);
    final worries = _asList(user['worryGroups']);
    final surveys = _asList(user['surveys']);

    final all = [...diaries, ...relax, ...tags, ...habits, ...worries, ...surveys];
    if (all.isEmpty) {
      return '최근 활동 기록이 명확히 없지만, 지난 몇 주간 시도했던 일 중 인상 깊은 경험을 이야기해볼까요?';
    }

    all.sort((a, b) {
      final da = _parseDate(a['updatedAt'] ??
          a['createdAt'] ??
          a['endTime'] ??
          a['startTime']);
      final db = _parseDate(b['updatedAt'] ??
          b['createdAt'] ??
          b['endTime'] ??
          b['startTime']);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    final latest = all.first;
    final date = _parseDate(latest['updatedAt'] ??
        latest['createdAt'] ??
        latest['endTime'] ??
        latest['startTime']);
    final when = date != null ? _toLocalReadable(date) : '(날짜 정보 없음)';

    final text = (latest['description'] ??
            latest['behaviorText'] ??
            latest['thought'] ??
            latest['title'] ??
            latest['groupName'] ??
            '')
        .toString()
        .trim();

    String src = '활동';
    if (latest.containsKey('relaxationScores')) src = '이완 훈련';
    else if (latest.containsKey('beliefText')) src = '대안적 사고';
    else if (latest.containsKey('behaviorText')) src = '행동 기록';
    else if (latest.containsKey('groupName')) src = '걱정 주제';
    else if (latest.containsKey('title')) src = '설문';

    if (text.isEmpty) {
      return '($src, $when)\n최근 기록 내용은 명확하지 않지만, 그 시기의 경험을 함께 돌아볼까요?';
    }
    return '($src, $when)\n$text';
  }
}
