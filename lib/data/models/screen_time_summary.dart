class ScreenTimeSummary {
  final int totalMinutes;
  final int todayMinutes;
  final int weekMinutes;
  final int sessions;
  final DateTime? lastEntryAt;

  const ScreenTimeSummary({
    required this.totalMinutes,
    required this.todayMinutes,
    required this.weekMinutes,
    required this.sessions,
    required this.lastEntryAt,
  });

  factory ScreenTimeSummary.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value.toUtc();
      if (value is String) {
        try {
          return DateTime.parse(value).toUtc();
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    int readInt(String key1, [String? key2]) {
      final raw = json[key1] ?? (key2 != null ? json[key2] : null);
      if (raw is int) return raw;
      if (raw is double) return raw.round();
      if (raw is String) {
        final parsed = int.tryParse(raw);
        if (parsed != null) return parsed;
      }
      return 0;
    }

    return ScreenTimeSummary(
      totalMinutes: readInt('totalMinutes', 'total_minutes'),
      todayMinutes: readInt('todayMinutes', 'today_minutes'),
      weekMinutes: readInt('weekMinutes', 'week_minutes'),
      sessions: readInt('sessions'),
      lastEntryAt: parse(json['lastEntryAt'] ?? json['last_entry_at']),
    );
  }

  String get totalLabel {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }
    return '${minutes}분';
  }
}
