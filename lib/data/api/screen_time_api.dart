import 'package:dio/dio.dart';

import 'api_client.dart';
import '../models/screen_time_entry.dart';
import '../models/screen_time_summary.dart';

String _isoString(DateTime value) => value.toUtc().toIso8601String();

class ScreenTimeApi {
  final ApiClient _client;
  ScreenTimeApi(this._client);

  Future<List<ScreenTimeEntry>> listEntries({
    DateTime? startFrom,
    DateTime? endBefore,
    int limit = 100,
  }) async {
    final query = <String, dynamic>{
      if (startFrom != null) 'start_from': _isoString(startFrom),
      if (endBefore != null) 'end_before': _isoString(endBefore),
      'limit': limit,
    };

    final res = await _client.dio.get('/users/me/screen-time', queryParameters: query);
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((raw) => ScreenTimeEntry.fromJson(raw.cast<String, dynamic>()))
          .toList();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/screen-time response',
    );
  }

  Future<ScreenTimeEntry> createEntry({
    required DateTime startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? label,
    String? source,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      'start_time': _isoString(startTime),
      if (endTime != null) 'end_time': _isoString(endTime),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      if (source != null && source.trim().isNotEmpty) 'source': source.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final res = await _client.dio.post('/users/me/screen-time', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ScreenTimeEntry.fromJson(data);
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/screen-time (POST) response',
    );
  }

  Future<ScreenTimeEntry> updateEntry(
    String entryId, {
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? label,
    String? source,
    String? note,
  }) async {
    final payload = <String, dynamic>{
      if (startTime != null) 'start_time': _isoString(startTime),
      if (endTime != null) 'end_time': _isoString(endTime),
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (label != null) 'label': label,
      if (source != null) 'source': source,
      if (note != null) 'note': note,
    };

    final res = await _client.dio.put('/users/me/screen-time/$entryId', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ScreenTimeEntry.fromJson(data);
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/screen-time update response',
    );
  }

  Future<void> deleteEntry(String entryId) async {
    await _client.dio.delete('/users/me/screen-time/$entryId');
  }

  Future<ScreenTimeSummary> getSummary() async {
    final res = await _client.dio.get('/users/me/screen-time/summary');
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return ScreenTimeSummary.fromJson(data);
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/screen-time/summary response',
    );
  }
}
