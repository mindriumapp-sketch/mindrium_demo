// lib/services/data_repo.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

/// ✅ 기본 사용자 ID (dummy.json의 patient_id 중 하나)
const String defaultUserId = "OCZQALVZ";

class DataRepo {
  Map<String, Map<String, dynamic>>? _cache;

  /// ✅ dummy.json 로드 (List / Map 구조 모두 자동 인식)
  Future<Map<String, Map<String, dynamic>>> _loadData() async {
    if (_cache != null) return _cache!;

    const path = 'assets/data/dummy.json';
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = jsonDecode(raw);

      final Map<String, Map<String, dynamic>> users = {};

      if (decoded is List) {
        // ✅ 리스트 기반 구조
        for (final item in decoded) {
          if (item is Map && item['patient_id'] != null && item['user'] != null) {
            final id = item['patient_id'].toString();
            final userData = Map<String, dynamic>.from(item['user']);
            userData['patient_id'] = id; // flatten 시 환자 ID 유지
            users[id] = userData;
          }
        }
        debugPrint('📂 [DataRepo] dummy.json (List 구조) 로드 완료, 사용자 ${users.length}명');
      } else if (decoded is Map<String, dynamic>) {
        // ✅ Map 기반 구조 (기존 호환)
        final base = decoded['users'] ?? decoded;
        if (base is Map<String, dynamic>) {
          base.forEach((id, val) {
            if (val is Map<String, dynamic>) {
              val['patient_id'] ??= id;
              users[id.toString()] = val;
            }
          });
          debugPrint('📂 [DataRepo] dummy.json (Map 구조) 로드 완료, 사용자 ${users.length}명');
        }
      } else {
        throw Exception('❌ 지원되지 않는 JSON 루트 구조입니다.');
      }

      if (users.isEmpty) {
        throw Exception('❌ 사용자 데이터를 찾을 수 없습니다.');
      }

      _cache = users;
      return users;
    } catch (e) {
      debugPrint('⚠️ [DataRepo] dummy.json 로드 실패: $e');
      rethrow;
    }
  }

  /// ✅ 모든 사용자 ID 목록 반환
  Future<List<String>> listUserIds() async {
    final all = await _loadData();
    return all.keys.toList();
  }

  /// ✅ 특정 사용자 데이터 반환 (없을 시 null)
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final all = await _loadData();
    final user = all[userId];

    if (user == null) {
      debugPrint('⚠️ [DataRepo] userId=$userId 데이터를 찾을 수 없습니다.');
      return null;
    }

    // 필수 필드 보완
    user['patient_id'] ??= userId;
    user['completedWeek'] ??= 0;
    return user;
  }

  /// ✅ 기본 사용자 반환 (fallback)
  Future<Map<String, dynamic>?> getDefaultUser() async {
    return await getUser(defaultUserId);
  }

  /// ✅ 캐시 초기화 (디버깅용)
  void clearCache() {
    _cache = null;
    debugPrint('♻️ [DataRepo] 캐시 초기화 완료');
  }
}
