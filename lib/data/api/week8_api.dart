import 'package:dio/dio.dart';

import 'api_client.dart';

class Week8Api {
  final ApiClient _client;
  Week8Api(this._client);

  /// 8주차 세션 조회
  Future<Map<String, dynamic>?> fetchWeek8Session() async {
    final res = await _client.dio.get(
      '/users/me/practice-sessions',
      queryParameters: {'week_number': 8},
    );
    final data = res.data;
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map) {
        return first.map((key, value) => MapEntry(key.toString(), value));
      }
    }
    if (data is List && data.isEmpty) {
      return null;
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid practice session response',
    );
  }

  /// 효과성 평가 저장
  Future<Map<String, dynamic>> updateEffectiveness({
    required List<Map<String, dynamic>> evaluations,
  }) async {
    final payload = {
      'evaluations': evaluations,
    };

    final res = await _client.dio.put(
      '/users/me/practice-sessions/week8/effectiveness',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid week8 effectiveness response',
    );
  }

  /// 사용자 여정 답변 저장
  Future<Map<String, dynamic>> updateUserJourney({
    required List<Map<String, dynamic>> responses,
  }) async {
    final payload = {
      'responses': responses,
    };

    final res = await _client.dio.put(
      '/users/me/practice-sessions/week8/user-journey',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid week8 user journey response',
    );
  }

  /// 완료 상태 업데이트
  Future<Map<String, dynamic>> updateCompletion(bool completed) async {
    final res = await _client.dio.patch(
      '/users/me/practice-sessions/week8/completed',
      data: {'completed': completed},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid week8 completion response',
    );
  }
}

