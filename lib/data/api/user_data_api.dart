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

  Future<Map<String, dynamic>> getProgress() async {
    final res = await _client.dio.get('/users/me/progress');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/progress response',
    );
  }

  Future<List<Map<String, dynamic>>> getArchivedGroups() async {
    final res = await _client.dio.get('/users/me/worry-groups/archived');
    final data = res.data;
    if (data is List) {
      final mapped = data
          .whereType<Map>()
          .map((raw) => raw.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
      return mapped.cast<Map<String, dynamic>>();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/worry-groups/archived response',
    );
  }

  Future<List<Map<String, dynamic>>> getCustomTags() async {
    final res = await _client.dio.get('/users/me/custom-tags');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((raw) => raw.map((key, value) => MapEntry(key.toString(), value)))
          .toList()
          .cast<Map<String, dynamic>>();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/custom-tags response',
    );
  }

  Future<Map<String, dynamic>> createCustomTag({
    required String text,
    required String type,
  }) async {
    final res = await _client.dio.post(
      '/users/me/custom-tags',
      data: {
        'text': text,
        'type': type,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/custom-tags (POST) response',
    );
  }

  Future<Map<String, dynamic>> createPracticeSession({
    required int weekNumber,
    required List<String> negativeItems,
    required List<String> positiveItems,
    Map<String, dynamic>? classificationQuiz,
  }) async {
    final payload = <String, dynamic>{
      'week_number': weekNumber,
      'negative_items': negativeItems,
      'positive_items': positiveItems,
      if (classificationQuiz != null) 'classification_quiz': classificationQuiz,
    };

    final res = await _client.dio.post(
      '/users/me/practice-sessions',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/practice-sessions (POST) response',
    );
  }

  Future<List<Map<String, dynamic>>> getPracticeSessions({int? weekNumber}) async {
    final res = await _client.dio.get(
      '/users/me/practice-sessions',
      queryParameters: {
        if (weekNumber != null) 'week_number': weekNumber,
      },
    );
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((raw) => raw.map((key, value) => MapEntry(key.toString(), value)))
          .toList()
          .cast<Map<String, dynamic>>();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/practice-sessions response',
    );
  }
}
