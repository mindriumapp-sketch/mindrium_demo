// lib/services/gpt_api.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// ⚠️ 개발용 키는 코드에 직접 포함하지 말고,
/// flutter run --dart-define=OPENAI_API_KEY=sk-... 로 전달하는 것을 권장.
/// 또는 .env / 백엔드 프록시를 통해 관리하세요.
class GptApi {
  GptApi(this.apiKey, {this.model = 'gpt-4o-mini', this.embeddingModel = 'text-embedding-3-large'});

  final String apiKey;
  final String model;
  final String embeddingModel;

  /// history: [{role:'system'|'user'|'assistant', content:'...'}, ...]
  /// userMessage: 현재 사용자 발화
  Future<String> chat(List<Map<String, String>> history, String userMessage) async {
    if (apiKey.isEmpty) {
      throw Exception('❌ OpenAI API key가 설정되지 않았습니다. (--dart-define=OPENAI_API_KEY=...)');
    }

    final List<Map<String, String>> messages = [
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    try {
      final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
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
        final text = (data['choices']?[0]?['message']?['content'] ?? '').toString().trim();
        if (text.isEmpty) return '응답이 비어 있습니다.';
        return text;
      } else {
        final errorBody = response.body.isNotEmpty ? response.body : '(no body)';
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
    if (apiKey.isEmpty) {
      throw Exception('❌ OpenAI API key가 설정되지 않았습니다.');
    }

    try {
      final uri = Uri.parse('https://api.openai.com/v1/embeddings');
      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': embeddingModel,
              'input': text,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['data']?[0]?['embedding'];
        if (embedding is List) {
          return embedding.map((e) => (e as num).toDouble()).toList();
        }
        return [];
      } else {
        print('❌ 임베딩 API 오류: ${response.statusCode} ${response.body}');
        return [];
      }
    } on TimeoutException {
      print('❌ 임베딩 요청 시간 초과');
      return [];
    } catch (e) {
      print('❌ 임베딩 요청 중 오류: $e');
      return [];
    }
  }
}
