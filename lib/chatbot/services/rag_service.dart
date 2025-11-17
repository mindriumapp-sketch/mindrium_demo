import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'gpt_api.dart';

/// RAG (Retrieval-Augmented Generation) 서비스
/// 사용자 입력과 가장 유사한 예제를 찾아서 반환 (OpenAI Embeddings 사용)
class RagService {
  RagService(this.api);
  
  final GptApi api;
  List<Map<String, dynamic>> _ragData = [];  // String → dynamic (embedding 포함)
  bool _loaded = false;

  /// rag_singleton_with_embeddings.jsonl 파일 로드 (임베딩 포함)
  Future<void> loadRagData() async {
    if (_loaded) return;
    
    try {
      print('📚 RAG 데이터 로딩 중...');
      final jsonlString = await rootBundle.loadString('assets/data/rag_singleton_with_embeddings.jsonl');
      final lines = jsonlString.split('\n').where((line) => line.trim().isNotEmpty).toList();
      
      _ragData = [];
      int loadedCount = 0;
      
      // JSONL 형식 - 각 라인이 독립적인 JSON 객체
      for (final line in lines) {
        try {
          final item = jsonDecode(line) as Map<String, dynamic>;
          final queryText = item['query']?.toString() ?? '';
          final responseText = item['response']?.toString() ?? '';
          final id = item['id']?.toString() ?? '';
          final embeddingList = item['embedding'] as List<dynamic>?;
          
          if (queryText.isEmpty || embeddingList == null || embeddingList.isEmpty) {
            continue;
          }
          
          // 임베딩을 List<double>로 변환
          final embedding = embeddingList.map((e) => (e as num).toDouble()).toList();
          
          _ragData.add({
            'id': id,
            'query': queryText,
            'response': responseText,
            'embedding': embedding,  // 파일에서 읽은 임베딩 벡터
          });
          
          loadedCount++;
        } catch (e) {
          continue;
        }
      }
      
      _loaded = true;
      print('✅ RAG 데이터 로드 완료: ${_ragData.length}개 항목 (임베딩 차원: ${_ragData.isNotEmpty ? (_ragData[0]['embedding'] as List).length : 0})');
    } catch (e) {
      print('❌ RAG 파일 로드 실패: $e');
    }
  }

  /// 임베딩 벡터 간 코사인 유사도 계산
  double _cosineSimilarity(List<double> vec1, List<double> vec2) {
    if (vec1.isEmpty || vec2.isEmpty || vec1.length != vec2.length) return 0.0;
    
    // 내적 계산
    double dotProduct = 0.0;
    for (int i = 0; i < vec1.length; i++) {
      dotProduct += vec1[i] * vec2[i];
    }
    
    // 벡터 크기 계산
    double norm1 = sqrt(vec1.fold(0.0, (sum, val) => sum + val * val));
    double norm2 = sqrt(vec2.fold(0.0, (sum, val) => sum + val * val));
    
    if (norm1 == 0 || norm2 == 0) return 0.0;
    
    return dotProduct / (norm1 * norm2);
  }

  /// 사용자 입력과 가장 유사한 RAG 항목 찾기 (임베딩 기반, 상위 K개 반환)
  Future<List<Map<String, dynamic>>> findTopKSimilar(String userInput, {int k = 3}) async {
    if (!_loaded || _ragData.isEmpty) {
      print('❌ RAG 데이터가 로드되지 않음');
      return [];
    }

    // 사용자 입력을 임베딩으로 변환
    final userEmbedding = await api.getEmbedding(userInput);

    // 모든 항목에 대해 유사도 계산
    final similarities = <Map<String, dynamic>>[];
    
    for (final item in _ragData) {
      final queryEmbedding = item['embedding'] as List<double>? ?? [];
      final similarity = _cosineSimilarity(userEmbedding, queryEmbedding);
      
      similarities.add({
        'id': item['id'],
        'query': item['query'],
        'response': item['response'],
        'similarity': similarity,
      });
    }

    // 유사도 기준으로 내림차순 정렬
    similarities.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));

    // 상위 K개 선택
    final topK = similarities.take(k).toList();

    // 결과 출력
    print('📚 RAG 검색 결과 (상위 $k개):');
    for (int i = 0; i < topK.length; i++) {
      final item = topK[i];
      print('   ${i + 1}. (유사도: ${((item['similarity'] as double) * 100).toStringAsFixed(1)}%) "${item['query']}"');
    }

    return topK;
  }
}

