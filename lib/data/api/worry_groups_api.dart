import 'package:dio/dio.dart';
import 'api_client.dart';

class WorryGroupsApi {
  final ApiClient _client;
  WorryGroupsApi(this._client);

  /// 모든 걱정 그룹 조회 (아카이브되지 않은 것만)
  Future<List<Map<String, dynamic>>> listWorryGroups({
    bool includeArchived = false,
  }) async {
    final res = await _client.dio.get(
      '/users/me/worry-groups',
      queryParameters: {if (includeArchived) 'include_archived': true},
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
      message: 'Invalid /users/me/worry-groups response',
    );
  }

  /// 특정 걱정 그룹 조회
  Future<Map<String, dynamic>> getWorryGroup(String groupId) async {
    final res = await _client.dio.get('/users/me/worry-groups/$groupId');
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/worry-groups/{id} response',
    );
  }

  /// 새 걱정 그룹 생성
  Future<Map<String, dynamic>> createWorryGroup({
    required String groupId,
    required String groupTitle,
    String groupContents = '',
    int? characterId,
  }) async {
    final payload = {
      'group_id': groupId,
      'group_title': groupTitle,
      'group_contents': groupContents,
      if (characterId != null) 'character_id': characterId,
    };

    final res = await _client.dio.post('/users/me/worry-groups', data: payload);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/worry-groups create response',
    );
  }

  /// 걱정 그룹 업데이트
  Future<Map<String, dynamic>> updateWorryGroup(
    String groupId,
    Map<String, dynamic> updates,
  ) async {
    final res = await _client.dio.put(
      '/users/me/worry-groups/$groupId',
      data: updates,
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/worry-groups/{id} update response',
    );
  }

  /// 걱정 그룹 아카이브 (소프트 삭제)
  Future<Map<String, dynamic>> archiveWorryGroup(String groupId) async {
    final res = await _client.dio.post(
      '/users/me/worry-groups/$groupId/archive',
    );
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/worry-groups/{id}/archive response',
    );
  }

  /// 아카이브된 걱정 그룹 목록 조회
  Future<List<Map<String, dynamic>>> getArchivedGroups() async {
    final res = await _client.dio.get('/users/me/worry-groups/archived');
    final data = res.data;
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();
    }
    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid /users/me/worry-groups/archived response',
    );
  }

  /// 걱정 그룹 완전 삭제 (하드 삭제)
  Future<void> deleteWorryGroup(String groupId) async {
    await _client.dio.delete('/users/me/worry-groups/$groupId');
  }
}
