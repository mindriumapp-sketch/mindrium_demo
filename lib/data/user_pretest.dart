import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// FastAPI 백엔드 기반 설문/진행도 조회 도우미
class UserDatabase {
  static final TokenStorage _tokens = TokenStorage();
  static ApiClient? _client;
  static UserDataApi? _userDataApi;

  static UserDataApi _api() {
    _client ??= ApiClient(tokens: _tokens);
    _userDataApi ??= UserDataApi(_client!);
    return _userDataApi!;
  }

  /// 설문 완료 여부 확인 (FastAPI /users/me/progress)
  static Future<bool> hasCompletedSurvey() async {
    try {
      final progress = await _api().getProgress();
      return progress['before_survey_completed'] == true;
    } catch (_) {
      return false;
    }
  }
}
