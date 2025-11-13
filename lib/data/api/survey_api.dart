import 'package:dio/dio.dart';

import 'api_client.dart';

class SurveyApi {
  final ApiClient _client;
  SurveyApi(this._client);

  Future<Map<String, dynamic>> submitSurvey({
    required String surveyId,
    required String title,
    String? description,
    int? score,
    Map<String, dynamic>? answers,
  }) async {
    final payload = <String, dynamic>{
      'survey_id': surveyId,
      'title': title,
      if (description != null) 'description': description,
      if (score != null) 'score': score,
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
}
