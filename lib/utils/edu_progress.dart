// lib/utils/edu_progress.dart
import 'package:shared_preferences/shared_preferences.dart';

class EduProgress {
  static const lastKey = 'edu.last_route';

  /// 진행도 키: 논리키(routeKey) 또는 라우트 문자열을 그대로 사용
  static String readKey(String routeOrKey) => 'edu.read.$routeOrKey';

  /// 진행률 저장 (읽은 페이지)
  /// - routeOrKey: 'week1_part1' 같은 논리키를 권장
  static Future<void> save(String routeOrKey, int read) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(readKey(routeOrKey), read);
  }

  /// 마지막으로 열었던 라우트 저장 (예: '/education1')
  static Future<void> setLastRoute(String route) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(lastKey, route);
  }

  /// 라우트별(혹은 논리키별) 읽은 페이지 조회
  static Future<int> getRead(String routeOrKey) async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(readKey(routeOrKey)) ?? 0;
  }

  /// 마지막으로 열었던 라우트 조회 (예: '/education1')
  static Future<String?> getLastRoute() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(lastKey);
  }
}
