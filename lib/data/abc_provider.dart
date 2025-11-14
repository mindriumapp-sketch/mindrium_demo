import 'package:flutter/material.dart';
//import 'package:uuid/uuid.dart';

class AbcRecord {
  final String id;
  final String activatingEvent; // A: 불안을 유발한 상황
  final String belief; // B: 당시 생각/신념
  final String consequence; // C: 감정/행동
  final DateTime createdAt;
  final int realityScore; // 현실성 (1~10)
  final int validityScore; // 타당성 (1~10)
  final int alternativeScore; // 대안 가능성 (1~10)
  final String alternative; // 대안적 생각

  AbcRecord({
    required this.id,
    required this.activatingEvent,
    required this.belief,
    required this.consequence,
    required this.createdAt,
    this.realityScore = 0,
    this.validityScore = 0,
    this.alternativeScore = 0,
    this.alternative = '',
  });

  AbcRecord copyWith({
    String? activatingEvent,
    String? belief,
    String? consequence,
    int? realityScore,
    int? validityScore,
    int? alternativeScore,
    String? alternative,
  }) {
    return AbcRecord(
      id: id,
      activatingEvent: activatingEvent ?? this.activatingEvent,
      belief: belief ?? this.belief,
      consequence: consequence ?? this.consequence,
      createdAt: createdAt,
      realityScore: realityScore ?? this.realityScore,
      validityScore: validityScore ?? this.validityScore,
      alternativeScore: alternativeScore ?? this.alternativeScore,
      alternative: alternative ?? this.alternative,
    );
  }
}

class AbcProvider extends ChangeNotifier {
  final List<AbcRecord> _records = [];

  List<AbcRecord> get records => List.unmodifiable(_records);

  void addRecord(AbcRecord record) {
    _records.add(record);
    notifyListeners();
  }

  void updateRecord(AbcRecord record) {
    final idx = _records.indexWhere((r) => r.id == record.id);
    if (idx != -1) {
      _records[idx] = record;
      notifyListeners();
    }
  }

  AbcRecord? getLastRecord() => _records.isNotEmpty ? _records.last : null;
}
