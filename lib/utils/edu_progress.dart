// lib/utils/edu_progress.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EduProgress {
  static const _nsPrefix = 'edu'; // namespace prefix

  // ──────────────────────────
  // 🔐 유저별 네임스페이스 키 생성기
  // ──────────────────────────
  static Future<String> _nsKey(String raw) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    return '$_nsPrefix.$uid.$raw';
  }

  // (이전 공개용 단순 키 함수는 더이상 외부에서 쓰지 않도록 내부화)
  static Future<String> _readKey(String routeOrKey) async =>
      _nsKey('read.$routeOrKey');

  static Future<String> _lastKey() async => _nsKey('last_route');

  // ✅ 주차 완료 중복 방지용 로컬 키 (user-scoped)
  static Future<String> _weekDoneKey(int weekNo) async =>
      _nsKey('week.done.$weekNo');

  static Future<void> markWeekDone(int weekNo) async {
    debugPrint("🔄 [EduProgress] markWeekDone($weekNo) 호출됨");

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;
    if (uid == null) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final nextWeek = weekNo + 1;

    // ✅ Firestore 업데이트 (completed + unlocked 분리)
    await userRef.set({
      'completed_education': FieldValue.increment(1),
      'completed_weeks': {'$weekNo': true},
    }, SetOptions(merge: true));

    if (nextWeek <= 8) {
      await userRef.set({
        'unlocked_weeks': {'$nextWeek': true},
      }, SetOptions(merge: true));
      debugPrint("🟩 [EduProgress] 다음 주차($nextWeek) unlock 완료");
    }

    // ✅ 로컬 기록
    final p = await SharedPreferences.getInstance();
    final key = await _weekDoneKey(weekNo);
    await p.setBool(key, true);
    debugPrint("📍 [EduProgress] 로컬 완료 플래그 저장: $key = true");
  }



  // ──────────────────────────
  // 진행률(읽은 페이지) 저장/조회 — user-scoped
  // ──────────────────────────
  static Future<void> save(String routeOrKey, int read) async {
    final p = await SharedPreferences.getInstance();
    final key = await _readKey(routeOrKey);
    await p.setInt(key, read);
    debugPrint("📝 [EduProgress] save read: $key = $read");
  }

  static Future<int> getRead(String routeOrKey) async {
    final p = await SharedPreferences.getInstance();
    final key = await _readKey(routeOrKey);
    final v = p.getInt(key) ?? 0;
    debugPrint("📖 [EduProgress] getRead: $key → $v");
    return v;
  }

  // ──────────────────────────
  // 마지막 라우트 저장/조회 — user-scoped
  // ──────────────────────────
  static Future<void> setLastRoute(String route) async {
    final p = await SharedPreferences.getInstance();
    final key = await _lastKey();
    await p.setString(key, route);
    debugPrint("🧭 [EduProgress] setLastRoute: $key = $route");
  }

  static Future<String?> getLastRoute() async {
    final p = await SharedPreferences.getInstance();
    final key = await _lastKey();
    final v = p.getString(key);
    debugPrint("🧭 [EduProgress] getLastRoute: $key → $v");
    return v;
  }

  // ──────────────────────────
  // (선택) 유저 전환 감지 시 로컬 초기화 헬퍼
  // ──────────────────────────
  /// 로그인 전환 시 호출하면, 이전 유저의 로컬 키와 섞이는 문제를 원천 차단.
  /// 보수적으로 네임스페이스 전체를 날리지 않고, 필요 필드만 초기화하려면 여기서 처리.
  static Future<void> clearLocalIfUserSwitched() async {
    final p = await SharedPreferences.getInstance();
    const lastUidKey = '$_nsPrefix.__last_uid';
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
    final lastUid = p.getString(lastUidKey);

    if (lastUid != currentUid) {
      // 💡 같은 네임스페이스를 쓰므로 굳이 전체를 비우지 않아도 됨.
      // 필요하면 특정 키(예: 캐시된 진행도)를 초기화하는 로직을 넣을 수 있음.
      await p.setString(lastUidKey, currentUid);
      debugPrint("🔁 [EduProgress] user switched: $lastUid → $currentUid (로컬 네임스페이스 분리로 안전)");
    }
  }
}
