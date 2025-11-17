import 'package:dio/dio.dart';
import 'api_client.dart';

class UsersApi {
  final ApiClient _client;
  UsersApi(this._client);

  Future<Map<String, dynamic>> me() async {
    final res = await _client.dio.get('/users/me');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me response',
    );
  }

  Future<Map<String, dynamic>> updateMe(Map<String, dynamic> body) async {
    final res = await _client.dio.put('/users/me', data: body);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me (PUT) response',
    );
  }
}
