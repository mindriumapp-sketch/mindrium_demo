import 'package:dio/dio.dart';

import 'api_client.dart';

class Week7Api {
  final ApiClient _client;
  Week7Api(this._client);

  Future<Map<String, dynamic>?> fetchWeek7Session() async {
    final res = await _client.dio.get(
      '/users/me/practice-sessions',
      queryParameters: {'week_number': 7},
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

  Future<Map<String, dynamic>> upsertClassificationItem({
    required String chipId,
    required String classification,
    String? reason,
    Map<String, dynamic>? analysis,
  }) async {
    final payload = <String, dynamic>{
      'chip_id': chipId,
      'classification': classification,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (analysis != null) 'analysis': analysis,
    };

    final res = await _client.dio.put(
      '/users/me/practice-sessions/week7/items',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid week7 item upsert response',
    );
  }

  Future<void> deleteClassificationItem(String chipId) async {
    await _client.dio.delete('/users/me/practice-sessions/week7/items/$chipId');
  }

  Future<Map<String, dynamic>> updateCompletion(bool completed) async {
    final res = await _client.dio.patch(
      '/users/me/practice-sessions/week7/completed',
      data: {'completed': completed},
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid week7 completion response',
    );
  }

  String _formatDate(DateTime date) => date.toIso8601String().split('T').first;

  Future<Map<String, dynamic>> createScheduleEvent({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, String?>> tasks,
  }) async {
    final payload = {
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'tasks': tasks,
    };
    final res = await _client.dio.post('/schedule-events', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid schedule event create response',
    );
  }

  Future<List<Map<String, dynamic>>> listScheduleEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = _formatDate(startDate);
    if (endDate != null) query['end_date'] = _formatDate(endDate);

    final res = await _client.dio.get(
      '/schedule-events',
      queryParameters: query.isEmpty ? null : query,
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
      message: 'Invalid schedule events response',
    );
  }

  Future<Map<String, dynamic>> updateScheduleEvent({
    required String eventId,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, String?>> tasks,
  }) async {
    final payload = {
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
      'tasks': tasks,
    };
    final res = await _client.dio.put(
      '/schedule-events/$eventId',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid schedule event update response',
    );
  }

  Future<void> deleteScheduleEvent(String eventId) async {
    await _client.dio.delete('/schedule-events/$eventId');
  }
}

