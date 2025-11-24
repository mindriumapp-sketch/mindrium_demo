import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

const String _envBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');

class ApiClient {
  final Dio dio;
  final TokenStorage tokens;
  final String baseUrl;

  static String _resolveBaseUrl(String? override) {
    if (override != null && override.isNotEmpty) {
      return override;
    }
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return 'http://10.0.2.2:8080';
  }

  ApiClient({
    required this.tokens,
    String? baseUrl,
  })  : baseUrl = _resolveBaseUrl(baseUrl),
        dio = Dio(BaseOptions(baseUrl: _resolveBaseUrl(baseUrl))) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // refresh 요청은 인터셉터를 우회
          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }
          final access = await tokens.access;
          if (access != null) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          // refresh 요청 자체의 에러는 재시도하지 않음
          if (e.requestOptions.extra['skipAuth'] == true) {
            return handler.next(e);
          }
          if (e.response?.statusCode == 401) {
            final ok = await _tryRefresh();
            if (ok) {
              final req = e.requestOptions;
              try {
                final response = await dio.fetch(req);
                return handler.resolve(response);
              } catch (re) {
                return handler.next(re as DioException);
              }
            }
          }
          handler.next(e);
        },
      ),
    );
  }

  Future<bool> _tryRefresh() async {
    final refresh = await tokens.refresh;
    if (refresh == null) return false;
    try {
      // refresh 요청은 인터셉터를 우회하여 무한 루프 방지
      final res = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
        options: Options(extra: {'skipAuth': true}),
      );
      final data = res.data;
      if (data is Map<String, dynamic>) {
        final access = data['access_token'] as String?;
        final newRefresh = data['refresh_token'] as String? ?? refresh;
        if (access == null) return false;
        await tokens.save(access, newRefresh);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
