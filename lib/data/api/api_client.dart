import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../storage/token_storage.dart';

String _resolveBaseUrl(String? override) {
  if (override != null && override.trim().isNotEmpty) {
    return override;
  }
  if (kIsWeb) {
    return 'http://localhost:8050';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8050';
  }
  return 'http://127.0.0.1:8050';
}

class ApiClient {
  final Dio dio;
  final TokenStorage tokens;
  final String baseUrl;

  ApiClient({
    required this.tokens,
    String? baseUrl,
  })  : baseUrl = _resolveBaseUrl(baseUrl),
        dio = Dio(BaseOptions(baseUrl: _resolveBaseUrl(baseUrl))) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await tokens.access;
          if (access != null) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (e, handler) async {
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
      final res = await dio.post('/auth/refresh', data: {'refresh_token': refresh});
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
