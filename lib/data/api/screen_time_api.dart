import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/screen_time_summary.dart';

class ScreenTimeApi {
  ScreenTimeApi(this._client);

  final ApiClient _client;

  Future<ScreenTimeSummary> fetchSummary() async {
    final res = await _client.dio.get('/users/me/screen-time/summary');
    final data = res.data as Map<String, dynamic>;
    return ScreenTimeSummary.fromJson(data);
  }

  Future<List<ScreenTimeEntry>> fetchEntries({int limit = 20}) async {
    final res = await _client.dio.get(
      '/users/me/screen-time',
      queryParameters: {'limit': limit},
    );
    final list = (res.data as List<dynamic>).cast<Map<String, dynamic>>();
    return list.map(ScreenTimeEntry.fromJson).toList(growable: false);
  }

  Future<void> logSession({
    required DateTime start,
    required DateTime end,
    String? platform,
  }) async {
    try {
      await _client.dio.post('/users/me/screen-time', data: {
        'start_time': start.toUtc().toIso8601String(),
        'end_time': end.toUtc().toIso8601String(),
        if (platform != null) 'platform': platform,
      });
    } on DioException {
      rethrow;
    }
  }
}
