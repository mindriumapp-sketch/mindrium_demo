// lib/services/gpt_api.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// GPT API 호출을 FastAPI 백엔드 프록시로 위임하여 프런트 코드에 키를 노출하지 않음.
class GptApi {
  GptApi({
    String? baseUrl,
    this.model = 'gpt-4o-mini',
    this.embeddingModel = 'text-embedding-3-large',
  }) : baseUrl = _resolveBaseUrl(baseUrl);

  static const _envProxyBase = String.fromEnvironment(
    'AI_PROXY_BASE_URL',
    defaultValue: '',
  );
  static const _envApiBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  final String baseUrl;
  final String model;
  final String embeddingModel;

  static String _resolveBaseUrl(String? override) {
    if (override != null && override.isNotEmpty) return override;
    if (_envProxyBase.isNotEmpty) return _envProxyBase;
    if (_envApiBase.isNotEmpty) return _envApiBase;
    if (kIsWeb) {
      // 웹에서는 Render 백엔드 서버 사용 (배포용)
      // 로컬 테스트: http://localhost:8080
      return 'http://127.0.0.1:8000';
    }
    return 'http://115.145.134.180:8070';
  }

  Uri _endpoint(String path) {
    final normalized =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    final trimmed = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$normalized/$trimmed');
  }

  /// history: [{role:'system'|'user'|'assistant', content:'...'}, ...]
  /// userMessage: 현재 사용자 발화
  Future<String> chat(
    List<Map<String, String>> history,
    String userMessage,
  ) async {
    final List<Map<String, String>> messages = [
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final response = await http
          .post(
            _endpoint('/ai/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.6,
              'max_tokens': 800,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['reply'] ?? '').toString().trim();
        if (text.isEmpty) return '응답이 비어 있습니다.';
        return text;
      } else {
        final errorBody =
            response.body.isNotEmpty ? response.body : '(no body)';
        return '⚠️ 서버 오류 (${response.statusCode})\n$errorBody';
      }
    } on TimeoutException {
      return '⚠️ 요청 시간이 초과되었습니다. (Timeout)';
    } catch (e) {
      return '⚠️ 요청 중 오류 발생: $e';
    }
  }

  /// 텍스트를 임베딩 벡터로 변환 (RAG용)
  Future<List<double>> getEmbedding(String text) async {
    try {
      final response = await http
          .post(
            _endpoint('/ai/embedding'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'model': embeddingModel, 'input': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['embedding'];
        if (embedding is List) {
          return embedding.map((e) => (e as num).toDouble()).toList();
        }
        return [];
      } else {
        debugPrint('❌ 임베딩 API 오류: ${response.statusCode} ${response.body}');
        return [];
      }
    } on TimeoutException {
      debugPrint('❌ 임베딩 요청 시간 초과');
      return [];
    } catch (e) {
      debugPrint('❌ 임베딩 요청 중 오류: $e');
      return [];
    }
  }
}
