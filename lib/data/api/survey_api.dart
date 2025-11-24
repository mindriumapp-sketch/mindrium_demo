import 'package:dio/dio.dart';

import 'api_client.dart';

class SurveyApi {
  final ApiClient _client;
  SurveyApi(this._client);

  Future<Map<String, dynamic>> submitSurvey({
    required String surveyType,
    Map<String, dynamic>? answers,
    String? description,
  }) async {
    final payload = <String, dynamic>{
      'type': surveyType,
      if (description != null) 'description': description,
      if (answers != null) 'answers': answers,
    };

    final res = await _client.dio.post('/users/me/surveys', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/surveys response',
    );
  }

  Future<Map<String, dynamic>> setSurveyCompleted(String status) async {
    final res = await _client.dio.put('/users/me', data: {
      'survey_completed': status,
    });
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me update response',
    );
  }

  Future<List<Map<String, dynamic>>> getSurveys() async {
    final res = await _client.dio.get('/users/me/surveys');
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
      message: 'Invalid /users/me/surveys response',
    );
  }
}
