import 'package:flutter/material.dart';
import 'daycounter.dart';
import 'api/users_api.dart';
import 'api/api_client.dart';
import 'storage/token_storage.dart';

class UserProvider extends ChangeNotifier {
  // REST 기반 클라이언트 (간단한 내부 생성; 필요 시 DI로 교체 가능)
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _client = ApiClient(tokens: _tokens);
  late final UsersApi _usersApi = UsersApi(_client);

  String _userName = '사용자';
  String get userName => _userName;

  String _userEmail = '';
  String get userEmail => _userEmail;

  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;

  String _uid = '';
  String get userId => _uid;

  /// 사용자 정보 로딩 (FastAPI /users/me 기반)
  Future<void> loadUserData({UserDayCounter? dayCounter}) async {
    try {
      final me = await _usersApi.me();

      _userName = (me['name'] as String?)?.trim().isNotEmpty == true
          ? (me['name'] as String)
          : '사용자';
      _userEmail = (me['email'] as String?) ?? '';
      _uid = (me['id'] as String?) ?? (me['_id'] as String? ?? '');

      final createdAtRaw = me['createdAt'] ?? me['created_at'];
      DateTime? parsedCreatedAt;
      if (createdAtRaw is String) {
        parsedCreatedAt = DateTime.tryParse(createdAtRaw);
      } else if (createdAtRaw is DateTime) {
        parsedCreatedAt = createdAtRaw;
      }

      if (parsedCreatedAt != null) {
        _createdAt = parsedCreatedAt;
        dayCounter?.setCreatedAt(parsedCreatedAt);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('유저 정보 불러오기 실패: $e');
    }
  }

  /// 사용자 이름 변경
  void updateUserName(String name) {
    _userName = name;
    notifyListeners();
  }
}
