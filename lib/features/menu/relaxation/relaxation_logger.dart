import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/relaxation_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// 점진적 이완 세션용 로거
///
/// ✅ 유지한 것들
/// - logEvent(String action)
/// - logAutosaveTick()  → autosave_* 는 DB 저장 시 필터링
/// - setFullyCompleted()  → 완주 여부 플래그
/// - saveLogs()  → 한 세션당 한 도큐먼트 upsert
///
/// ✅ 바뀐 것들
/// - Firestore → FastAPI + Mongo (`RelaxationApi.saveRelaxationTask`)
/// - endTime / durationTime 은 **완주(_fullyCompleted=true)**일 때만 기록
/// - 완주 전 saveLogs: realLogs + autosave_checkpoint 1개만 추가
class RelaxationLogger {
  final String taskId;
  final int? weekNumber;
  double? _latitude;
  double? _longitude;
  String? _addressName;

  final DateTime _sessionStart = DateTime.now();
  final List<Map<String, dynamic>> _logEntries = [];
  // 완주 여부(오디오+Rive 모두 끝났을 때만 endTime 기록)
  bool _fullyCompleted = false;

  // REST API 클라이언트
  late final ApiClient _client;
  late final RelaxationApi _api;

  // 🔥 이 세션에서 서버가 준 relax_id 저장
  String? _relaxId;

  RelaxationLogger({
    required this.taskId,
    this.weekNumber,
    ApiClient? client,
    RelaxationApi? api,
  }) {
    // ApiClient / RelaxationApi 주입 안 했으면 내부에서 간단 생성
    _client = client ?? ApiClient(tokens: TokenStorage());
    _api = api ?? RelaxationApi(_client);
  }

  /// 외부(플레이어)에서 오디오+Rive 모두 끝났을 때 호출
  /// (기존 구현 그대로 유지)
  void setFullyCompleted() {
    _fullyCompleted = true;
  }

  /// 공통 이벤트 로깅
  ///
  /// - action 예시:
  ///   - "start"
  ///   - "autosave_tick"
  ///   - "audio_complete"
  ///   - "pause" / "resume"
  ///   - "final_save_xxx"
  ///   - "session_complete"
  ///   - "rive_state_machine_missing"
  ///   - "rive_complete"
  void logEvent(String action) {
    final now = DateTime.now();
    final elapsed = now.difference(_sessionStart).inSeconds;

    _logEntries.add({
      "action": action,
      "timestamp": now.toUtc().toIso8601String(),
      "elapsed_seconds": elapsed,
    });

    // 방어적: session_complete 로그가 들어오면 완주로 간주
    if (action == "session_complete") {
      _fullyCompleted = true;
    }
  }

  /// 주기 자동저장 시 호출해도 됨.
  /// (메모리에만 남고 DB 저장시 autosave_* 는 제외 → 기존 동작 유지)
  void logAutosaveTick() {
    logEvent("autosave_tick");
  }

  /// 실제 DB 저장 (기존 saveLogs 이름 유지)
  ///
  /// - autosave_* action 은 realLogs에서 제거
  /// - _fullyCompleted == false:
  ///     realLogs + 마지막 autosave_checkpoint 1개
  /// - _fullyCompleted == true:
  ///     realLogs만 저장 + endTime / durationTime 기록
  Future<void> saveLogs() async {
    if (_logEntries.isEmpty) return;

    // 혹시 setFullyCompleted() 안 불렀더라도,
    // session_complete 이벤트가 있으면 완주로 처리
    if (!_fullyCompleted &&
        _logEntries.any((e) => e["action"] == "session_complete")) {
      _fullyCompleted = true;
    }

    final now = DateTime.now();

    // autosave_* 는 개별 항목으로 DB에 올리지 않음
    final List<Map<String, dynamic>> realLogs = _logEntries.where((e) {
      final a = (e["action"] ?? "").toString();
      return !a.startsWith("autosave");
    }).toList();

    // 완주 전: realLogs + 마지막 autosave_checkpoint (endTime 기록 X)
    // 완주 시: autosave 모두 제거(realLogs만) + endTime 기록
    final List<Map<String, dynamic>> logsForDb;
    if (_fullyCompleted) {
      logsForDb = realLogs;
    } else {
      logsForDb = [
        ...realLogs,
        {
          "action": "autosave_checkpoint",
          "timestamp": now.toUtc().toIso8601String(),
          "elapsed_seconds": now
              .difference(_sessionStart)
              .inSeconds,
        },
      ];
    }

    // 완주시에만 endTime / durationTime 채움
    final DateTime? endTime = _fullyCompleted ? now : null;
    final int? durationTime =
    _fullyCompleted ? now
        .difference(_sessionStart)
        .inSeconds : null;

    try {
      // 🔥 서버에 현재 relaxId를 같이 보냄 (처음엔 null → 새로 생성)
      final res = await _api.saveRelaxationTask(
        relaxId: _relaxId,
        taskId: taskId,
        weekNumber: weekNumber,
        startTime: _sessionStart,
        endTime: endTime,
        logs: logsForDb,
        latitude: _latitude,
        longitude: _longitude,
        addressName: _addressName,
        durationTime: durationTime,
      );

      // 🔥 응답에서 relax_id 받아서 내부에 캐싱
      final dynamic newId = res['relax_id'];
      if (newId is String && newId.isNotEmpty) {
        _relaxId = newId;
      }

      debugPrint(
        'RelaxationLogger: logs saved (relaxId=$_relaxId, taskId=$taskId, '
            'count=${_logEntries.length}, fullyCompleted=$_fullyCompleted)',
      );
    } catch (e, st) {
      debugPrint('RelaxationLogger.saveLogs error: $e\n$st');
      rethrow;
    }
  }

// ──────────────────────────────────────────────────────────
// [옵션] 위치 업데이트 — 나중에 필요해지면 아래 전부 주석 해제
  void updateLocation({
    double? latitude,
    double? longitude,
    String? addressName,
  }) {
    _latitude = latitude;
    _longitude = longitude;
    _addressName = addressName;
  }
// ──────────────────────────────────────────────────────────
}
