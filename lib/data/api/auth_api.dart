import 'package:dio/dio.dart';
import 'api_client.dart';
import '../storage/token_storage.dart';

class AuthApi {
  final ApiClient _client;
  final TokenStorage _tokens;

  AuthApi(this._client, this._tokens);

  Future<void> signup({
    required String email,
    required String password,
    required String name,
    String? code,
    String gender = 'male',  // 기본값 추가
  }) async {
    final body = {
      'email': email,
      'password': password,
      'name': name,
      'gender': gender,  // gender 필드 추가
      if (code != null && code.isNotEmpty) 'code': code,
    };
    await _client.dio.post('/auth/signup', data: body);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Invalid login response',
      );
    }
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access == null || refresh == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Tokens missing in response',
      );
    }
    await _tokens.save(access, refresh);
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _client.dio.get('/users/me');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid me response',
    );
  }

  Future<void> logout() async {
    await _tokens.clear();
  }

  Future<String?> requestPasswordResetToken(String email) async {
    final res = await _client.dio.post('/auth/password/reset/start', data: {
      'email': email,
    });
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data['token_debug'] as String?;
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid password reset start response',
    );
  }

  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    await _client.dio.post('/auth/password/reset/finish', data: {
      'token': token,
      'new_password': newPassword,
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.post('/auth/password/change', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}
