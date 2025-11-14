// relaxation_logger.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ──────────────────────────────────────────────────────────────
// [옵션] 위치 추적을 나중에 켤 때만 아래 두 줄 주석 해제
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart'; // (선택) 좌표→주소 변환
// ──────────────────────────────────────────────────────────────

class SessionLogger {
  final String taskId;
  final int weekNumber;

  final DateTime _sessionStart = DateTime.now();
  final List<Map<String, dynamic>> _logEntries = [];

  // 한 세션=한 문서: 자동 생성된 sessionId (화면마다 한 번 생성되어 고정)
  late final String _sessionId =
      '${taskId}_${_sessionStart.millisecondsSinceEpoch}';

  // 완주 여부(오디오+Rive 모두 끝났을 때만 endTime 기록)
  bool _fullyCompleted = false;

  // ──────────────────────────────────────────────────────────
  // [옵션] 위치 관련 보관 필드 (지금은 사용 안 함; 주석 상태 유지)
  // Position? _startPosition;
  // String? _startAddress; // (선택) 지오코딩 결과 텍스트 주소
  // ──────────────────────────────────────────────────────────

  SessionLogger({
    required this.taskId,
    required this.weekNumber,
  }) {
    // ────────────────────────────────────────────────────────
    // [옵션] 위치 캡처를 켜려면 아래 라인 주석 해제
    // _captureStartLocation();
    // ────────────────────────────────────────────────────────
  }

  /// 외부(플레이어)에서 오디오+Rive 모두 끝났을 때 호출
  void setFullyCompleted() {
    _fullyCompleted = true;
  }

  void logEvent(String action) {
    final now = DateTime.now();
    final elapsed = now.difference(_sessionStart).inSeconds;
    _logEntries.add({
      "action": action,
      "timestamp": now.toIso8601String(),
      "elapsed_seconds": elapsed,
    });
  }

  /// 주기 자동저장 시 호출해도 됨. (메모리에만 남고 DB 저장시 개별 autosave는 제외)
  void logAutosaveTick() {
    logEvent("autosave_tick");
  }

  Future<void> saveLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('relaxation_tasks')
        .doc(_sessionId);

    // autosave_* 는 개별 항목으로 DB에 올리지 않음
    final List<Map<String, dynamic>> realLogs = _logEntries.where((e) {
      final a = (e["action"] ?? "").toString();
      return !a.startsWith("autosave");
    }).toList();

    final now = DateTime.now();

    // 완주 전: realLogs + 마지막에 1개의 autosave_checkpoint (endTime 기록 X)
    // 완주 시: autosave 모두 제거(realLogs만) + endTime 기록
    final List<Map<String, dynamic>> logsForDb = _fullyCompleted
        ? realLogs
        : [
      ...realLogs,
      {
        "action": "autosave_checkpoint",
        "timestamp": now.toIso8601String(),
        "elapsed_seconds": now.difference(_sessionStart).inSeconds,
      },
    ];

    final Map<String, dynamic> data = {
      "sessionId": _sessionId,        // 편의용
      "taskId": taskId,
      "weekNumber": weekNumber,
      "startTime": _sessionStart,
      "updatedAt": FieldValue.serverTimestamp(),
      "logs": logsForDb,
      // ──────────────────────────────────────────────────────
      // [옵션] 위치 필드 (나중에 켤 때만 아래 주석 해제)
      // "startLatitude": _startPosition?.latitude,
      // "startLongitude": _startPosition?.longitude,
      // "startAddress": _startAddress, // (선택)
      // ──────────────────────────────────────────────────────
    };

    if (_fullyCompleted) {
      data["endTime"] = now; // 끝까지 재생됐을 때만 기록
    }

    await docRef.set(data, SetOptions(merge: true)); // 한 문서만 계속 갱신
  }

// ──────────────────────────────────────────────────────────
// [옵션] 위치 캡처 로직 — 나중에 필요해지면 아래 전부 주석 해제
//
// Future<void> _captureStartLocation() async {
//   try {
//     // 1) 권한 체크/요청
//     LocationPermission perm = await Geolocator.checkPermission();
//     if (perm == LocationPermission.denied) {
//       perm = await Geolocator.requestPermission();
//     }
//     if (perm == LocationPermission.deniedForever ||
//         perm == LocationPermission.denied) {
//       return; // 권한 없으면 위치 저장 스킵
//     }
//
//     // 2) 현재 위치 가져오기
//     final pos = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     _startPosition = pos;
//
//     // 3) (선택) 지오코딩으로 주소 얻기
//     try {
//       final placemarks = await placemarkFromCoordinates(
//         pos.latitude, pos.longitude,
//       );
//       if (placemarks.isNotEmpty) {
//         final p = placemarks.first;
//         _startAddress = [
//           p.country,
//           p.administrativeArea,
//           p.locality,
//           p.street,
//           p.name,
//         ].where((e) => (e ?? '').toString().isNotEmpty).join(' ');
//       }
//     } catch (_) {
//       // 지오코딩 실패는 무시 (좌표만 있어도 충분)
//     }
//   } catch (e) {
//     // 위치 획득 실패는 조용히 스킵
//   }
// }
// ──────────────────────────────────────────────────────────
}