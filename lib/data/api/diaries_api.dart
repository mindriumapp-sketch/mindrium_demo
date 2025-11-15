import 'package:dio/dio.dart';

import 'api_client.dart';

class DiariesApi {
  final ApiClient _client;
  DiariesApi(this._client);

  Future<Map<String, dynamic>> createDiary({
    required int groupId,
    required String activatingEvents,
    List<String> belief = const [],
    List<String> consequenceP = const [],
    List<String> consequenceE = const [],
    List<String> consequenceB = const [],
    List<Map<String, dynamic>> sudScores = const [],
    List<dynamic> alternativeThoughts = const [],
    List<Map<String, dynamic>> alarms = const [],
    double? latitude,
    double? longitude,
    String? addressName,
  }) async {
    final payload = <String, dynamic>{
      'group_Id': groupId,
      'activating_events': activatingEvents,
      'belief': belief,
      'consequence_p': consequenceP,
      'consequence_e': consequenceE,
      'consequence_b': consequenceB,
      'sudScores': sudScores,
      'alternativeThoughts': alternativeThoughts,
      'alarms': alarms,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (addressName != null) 'addressName': addressName,
    };

    final res = await _client.dio.post('/diaries', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries response',
    );
  }

  Future<List<Map<String, dynamic>>> listDiaries({int? groupId}) async {
    final res = await _client.dio.get(
      '/diaries',
      queryParameters: {
        if (groupId != null) 'group_id': groupId,
      },
    );
    final data = res.data;
    if (data is List) {
      return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries list response',
    );
  }

  Future<Map<String, dynamic>> getDiary(String diaryId) async {
    final res = await _client.dio.get('/diaries/$diaryId');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries/{id} response',
    );
  }

  Future<Map<String, dynamic>> updateDiary(
    String diaryId,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.dio.put('/diaries/$diaryId', data: body);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries/{id} update response',
    );
  }

  Future<List<Map<String, dynamic>>> listAlarms(String diaryId) async {
    final res = await _client.dio.get('/diaries/$diaryId/alarms');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((raw) => raw.map((k, v) => MapEntry(k.toString(), v)))
          .toList()
          .cast<Map<String, dynamic>>();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries/{id}/alarms response',
    );
  }

  Future<Map<String, dynamic>> createAlarm(
    String diaryId,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.dio.post('/diaries/$diaryId/alarms', data: body);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries/{id}/alarms create response',
    );
  }

  Future<Map<String, dynamic>> updateAlarm(
    String diaryId,
    String alarmId,
    Map<String, dynamic> body,
  ) async {
    final res = await _client.dio.put('/diaries/$diaryId/alarms/$alarmId', data: body);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /diaries/{id}/alarms/{alarm_id} response',
    );
  }

  Future<void> deleteAlarm(String diaryId, String alarmId) async {
    await _client.dio.delete('/diaries/$diaryId/alarms/$alarmId');
  }
}
