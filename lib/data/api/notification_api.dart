import 'package:dio/dio.dart';

import 'api_client.dart';

class NotificationApi {
  final ApiClient _client;
  NotificationApi(this._client);

  Future<List<Map<String, dynamic>>> list({
    String? abcId,
    bool locationOnly = false,
  }) async {
    final query = <String, dynamic>{};
    if (abcId != null) query['abc_id'] = abcId;
    if (locationOnly) query['location_only'] = true;
    final res = await _client.dio.get(
      '/notifications',
      queryParameters: query.isEmpty ? null : query,
    );
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
      message: 'Invalid notifications list response',
    );
  }

  Future<Map<String, dynamic>?> fetchLatest() async {
    final res = await _client.dio.get('/notifications/latest');
    return _castToMap(res.data);
  }

  Future<Map<String, dynamic>> upsert({
    required String abcId,
    required Map<String, dynamic> body,
    String? id,
  }) async {
    final hasId = id != null && id.isNotEmpty;
    final path = hasId ? '/notifications/$abcId/$id' : '/notifications/$abcId';
    final Response res = hasId
        ? await _client.dio.put(path, data: body)
        : await _client.dio.post(path, data: body);
    final map = _castToMap(res.data);
    if (map != null) return map;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid notifications response',
    );
  }

  Future<Map<String, dynamic>?> updateTime({
    required String abcId,
    required String settingId,
    required Map<String, dynamic> body,
  }) async {
    final res =
        await _client.dio.patch('/notifications/$abcId/$settingId/time', data: body);
    return _castToMap(res.data);
  }

  Future<Map<String, dynamic>?> updateDescription({
    required String abcId,
    required String settingId,
    required String description,
  }) async {
    final res = await _client.dio.patch(
      '/notifications/$abcId/$settingId/description',
      data: {'description': description},
    );
    return _castToMap(res.data);
  }

  Future<void> deleteSetting({
    required String abcId,
    required String settingId,
  }) async {
    await _client.dio.delete('/notifications/$abcId/$settingId');
  }

  Map<String, dynamic>? _castToMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }
}
