import 'package:dio/dio.dart';

import 'api_client.dart';

class SudApi {
  final ApiClient _client;
  SudApi(this._client);

  Future<Map<String, dynamic>> createSudScore({
    required String diaryId,
    required int beforeScore,
    int? afterScore,
  }) async {
    final payload = <String, dynamic>{
      'diaryId': diaryId,
      'before_sud': beforeScore,
      if (afterScore != null) 'after_sud': afterScore,
    };

    final res = await _client.dio.post('/sud-scores', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /sud-scores response',
    );
  }

  Future<List<Map<String, dynamic>>> listSudScores(String diaryId) async {
    final res = await _client.dio.get('/sud-scores/$diaryId');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((raw) => raw.map((k, v) => MapEntry(k.toString(), v)))
          .map((raw) => Map<String, dynamic>.from(raw))
          .toList();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /sud-scores/{id} response',
    );
  }

  Future<Map<String, dynamic>> updateSudScore({
    required String diaryId,
    required String sudId,
    int? beforeScore,
    int? afterScore,
    double? latitude,
    double? longitude,
  }) async {
    final payload = <String, dynamic>{
      if (beforeScore != null) 'before_sud': beforeScore,
      if (afterScore != null) 'after_sud': afterScore,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    final res = await _client.dio.put('/sud-scores/$diaryId/$sudId', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /sud-scores update response',
    );
  }
}
