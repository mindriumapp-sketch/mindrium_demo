import 'package:dio/dio.dart';

import 'api_client.dart';

/// 이완(점진적 이완 등) 관련 로그 전용 API 래퍼.
/// MongoDB + FastAPI의 /relaxation_tasks 계열 엔드포인트를 감싼다.
class RelaxationApi {
  final ApiClient _client;
  RelaxationApi(this._client);

  /// 이완 세션 로그 저장/업데이트
  ///
  /// - 같은 [relax_id]로 여러 번 호출하면 서버에서 해당 세션 도큐먼트를 덮어쓴다(upsert).
  /// - [start_time], [end_time] 은 ISO8601(UTC) 문자열로 직렬화된다.
  /// - [logs] 는 `{ action, timestamp, elapsed_seconds }` 형태의 맵 리스트여야 한다.
  /// - [latitude], [longitude], [address_name], [duration_time] 은 nullable.
  Future<Map<String, dynamic>> saveRelaxationTask({
    String? relaxId,
    required String taskId,
    int? weekNumber,
    required DateTime startTime,
    DateTime? endTime,
    required List<Map<String, dynamic>> logs,
    double? latitude,
    double? longitude,
    String? addressName,
    int? durationTime,
  }) async {
    final payload = <String, dynamic>{
      if (relaxId != null) 'relax_id': relaxId,
      'task_id': taskId,
      if (weekNumber != null) 'week_number': weekNumber,
      'start_time': startTime.toUtc().toIso8601String(),
      'logs': logs,
      if (endTime != null) 'end_time': endTime.toUtc().toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (addressName != null) 'address_name': addressName,
      if (durationTime != null) 'duration_time': durationTime,
    };

    final res = await _client.dio.post(
      '/relaxation_tasks',
      data: payload,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /relaxation_tasks response',
    );
  }

  /// 이완 세션 로그 목록 조회
  ///
  /// - [week_number] 가 주어지면 해당 주차의 로그만 필터링.
  Future<List<Map<String, dynamic>>> listRelaxationTasks({
    int? weekNumber,
    String? taskId,   // ✅ 추가
  }) async {
    final query = <String, dynamic>{};
    if (weekNumber != null) {
      query['week_number'] = weekNumber;
    }
    if (taskId != null) {
      query['task_id'] = taskId;  // ✅ 서버 쿼리 파라미터 이름
    }

    final res = await _client.dio.get(
      '/relaxation_tasks',
      queryParameters: query.isEmpty ? null : query,
    );

    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /relaxation_tasks list response',
    );
  }

  /// 특정 주차(또는 전체)에서 가장 최근 이완 세션 로그 1개 조회
  ///
  /// - [week_number] 가 지정되면 해당 주차의 로그 중 최신 1개,
  ///   없으면 전체 로그 중 최신 1개를 반환.
  /// - 로그가 전혀 없으면 `null` 반환.
  Future<Map<String, dynamic>?> getLatestRelaxationTask({
    int? weekNumber,
    String? taskId,   // ✅ 추가
  }) async {
    final query = <String, dynamic>{};
    if (weekNumber != null) {
      query['week_number'] = weekNumber;
    }
    if (taskId != null) {
      query['task_id'] = taskId;
    }

    final res = await _client.dio.get(
      '/relaxation_tasks/latest',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = res.data;

    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;

    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /relaxation_tasks/latest response',
    );
  }

  /// 이완 점수(relaxation_score)만 업데이트
  ///
  /// - 다른 화면에서 점수 측정 후 호출.
  /// - 서버 라우터: PATCH /relaxation_tasks/{relax_id}/score
  Future<Map<String, dynamic>> updateRelaxationScore({
    required String relaxId,
    required double relaxationScore,
  }) async {
    final res = await _client.dio.patch(
      '/relaxation_tasks/$relaxId/score',
      data: {
        'relaxation_score': relaxationScore,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /relaxation_tasks/{relaxId}/score response',
    );
  }
}
