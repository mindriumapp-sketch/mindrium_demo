import 'package:dio/dio.dart';

import 'api_client.dart';

class UserDataApi {
  final ApiClient _client;
  UserDataApi(this._client);

  Future<Map<String, dynamic>?> getCoreValue() async {
    final res = await _client.dio.get('/users/me/core-value');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/core-value response',
    );
  }

  Future<Map<String, dynamic>> updateCoreValue(String coreValue) async {
    final res = await _client.dio.put(
      '/users/me/core-value',
      data: {'core_value': coreValue},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/core-value (PUT) response',
    );
  }

  Future<void> deleteCoreValue() async {
    await _client.dio.delete('/users/me/core-value');
  }
}
