DateTime? _parseDate(dynamic value) {
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

int _parseMinutes(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  return 0;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw is String && raw.trim().isNotEmpty) return raw.trim();
  }
  return null;
}

class ScreenTimeEntry {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String? label;
  final String? source;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ScreenTimeEntry({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.label,
    required this.source,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ScreenTimeEntry.fromJson(Map<String, dynamic> json) {
    final id = json['entryId'] ?? json['entry_id'];
    final start = _parseDate(json['startTime'] ?? json['start_time']);
    final end = _parseDate(json['endTime'] ?? json['end_time']);
    final created = _parseDate(json['createdAt'] ?? json['created_at']) ?? start ?? DateTime.now().toUtc();
    final updated = _parseDate(json['updatedAt'] ?? json['updated_at']) ?? created;

    return ScreenTimeEntry(
      id: (id ?? 'unknown').toString(),
      startTime: start ?? created,
      endTime: end,
      durationMinutes: _parseMinutes(json['durationMinutes'] ?? json['duration_minutes']),
      label: _readString(json, const ['label', 'name', 'title']),
      source: _readString(json, const ['source', 'provider']),
      note: _readString(json, const ['note', 'notes', 'memo', 'description']),
      createdAt: created,
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() => {
        'entryId': id,
        'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime!.toIso8601String(),
        'durationMinutes': durationMinutes,
        'label': label,
        'source': source,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  String get prettyDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}시간 ${minutes}분';
    }
    return '${minutes}분';
  }

  ScreenTimeEntry copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? label,
    String? source,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ScreenTimeEntry(
      id: id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      label: label ?? this.label,
      source: source ?? this.source,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
