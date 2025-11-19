class ScreenTimeSummary {
  final double totalMinutes;
  final double todayMinutes;
  final double weekMinutes;
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
    return ScreenTimeSummary(
      totalMinutes: (json['totalMinutes'] as num?)?.toDouble() ?? 0,
      todayMinutes: (json['todayMinutes'] as num?)?.toDouble() ?? 0,
      weekMinutes: (json['weekMinutes'] as num?)?.toDouble() ?? 0,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      lastEntryAt: _parseDate(json['lastEntryAt']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    return null;
  }
}

class ScreenTimeEntry {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final double durationMinutes;
  final DateTime createdAt;
  final String? platform;

  const ScreenTimeEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.createdAt,
    this.platform,
  });

  factory ScreenTimeEntry.fromJson(Map<String, dynamic> json) {
    return ScreenTimeEntry(
      id: json['id']?.toString() ?? '',
      startTime: DateTime.parse(json['start_time'] as String).toUtc(),
      endTime: DateTime.parse(json['end_time'] as String).toUtc(),
      durationMinutes: (json['duration_minutes'] as num?)?.toDouble() ?? 0,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now().toUtc(),
      platform: json['platform'] as String?,
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) return DateTime.tryParse(raw)?.toUtc();
    return null;
  }
}
