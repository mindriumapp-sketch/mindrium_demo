// lib/services/orchestrator.dart
// import 'dart:convert';
import 'agents.dart';
import 'gpt_api.dart';
import 'rag_service.dart';
import 'daily_context.dart';
import 'data_repo.dart';
import 'package:flutter/foundation.dart';

/// 🧠 주차 기반 CBT 상담 흐름 오케스트레이터 (GPT + Context 확장형)
class Orchestrator {
  Orchestrator(this.agents, this.api, this.dataRepo, {required this.currentWeek});

  final Agents agents;
  final GptApi api;
  final DataRepo dataRepo;
  final int currentWeek;

  late final RagService _ragService;

  /// ✅ RAG 초기화
  Future<void> initializeRag() async {
    _ragService = RagService(api);
    await _ragService.loadRagData();
  }

  /// ✅ 주차별 기본 컨셉 프롬프트
  String _conceptPromptForWeek(int week) {
    switch (week) {
      case 1:
        return '이번 주는 디지털 치료기기를 사용하며 자기관리를 익히는 단계예요. 최근의 활동이나 루틴은 어떻게 유지되고 있나요?';
      case 2:
        return '이번 주는 걱정 일기(ABC 모델)를 중심으로 감정과 생각을 탐색하는 단계예요. 최근 작성한 기록 중 기억에 남는 부분이 있었나요?';
      case 3:
      case 4:
        return '이번 주는 인지치료 단계예요. 떠오른 자동적인 생각을 다른 시각에서 바라보는 연습을 함께 해보고 있어요.';
      case 5:
      case 6:
        return '이번 주는 행동치료 단계예요. 불안을 피하지 않고 직면하는 시도를 이어가는 중이에요. 최근 시도했던 활동이 있었나요?';
      case 7:
        return '이번 주는 생활습관 루틴을 점검하고 조정하는 단계예요. 수면, 운동, 명상 등 일상 루틴을 살펴보는 시간을 가져볼까요?';
      case 8:
        return '이번 주는 치료를 마무리하며 지난 변화를 돌아보는 단계예요. 그동안의 활동 중 특히 달라졌다고 느낀 부분이 있으신가요?';
      default:
        return '오늘은 최근의 경험이나 활동을 중심으로 이야기를 나눠볼까요?';
    }
  }

  /// ✅ 메인 대화 핸들러
  Future<List<Map<String, String>>> handle(
    List<Map<String, String>> history,
    String userMessage, {
    String? attachedDiary,
    String? stage,
  }) async {
    final out = <Map<String, String>>[];

    // --- 사용자 데이터 로드 ---
    final user = await dataRepo.getUser(defaultUserId);
    if (user == null) {
      out.add({
        'sender': 'ai',
        'role': 'notice',
        'message': '⚠️ 사용자 데이터를 불러오지 못했습니다.',
      });
      return out;
    }

    final int week = user['completedWeek'] ?? currentWeek;
    final userName = user['name'] ?? '사용자님';

    // --- 주차별 컨텍스트 로드 ---
    final weekSummary = DailyContext.buildWeekSummary(user, week);
    final anchor = DailyContext.buildLatestAnchor(user);
    final weekContext = DailyContext.buildContextForWeek(user, week);
    final conceptText = _conceptPromptForWeek(week);

    final topic = weekContext['topic'] ?? '이번 주 활동';
    final contextItems = (weekContext['contextItems'] as List?)?.join(', ') ?? '';

    // --- Stage 자동 추정 ---
    String inferStage(String anchorText) {
      final lower = anchorText.toLowerCase();
      if (lower.contains('생각') || lower.contains('믿음')) return 'reframe';
      if (lower.contains('행동') || lower.contains('시도')) return 'experiment';
      if (lower.contains('감정') || lower.contains('불안')) return 'define';
      return 'define';
    }

    final inferredStage = stage ?? inferStage(anchor);

    // --- RAG 검색 (보조 활용) ---
    final ragResults = await _ragService.findTopKSimilar(userMessage, k: 3);
    String ragReference = '';
    if (ragResults.isNotEmpty &&
        (ragResults[0]['similarity'] as double? ?? 0) > 0.6) {
      ragReference = '\n\n[참고 상담 사례]\n';
      for (final r in ragResults) {
        final sim = (r['similarity'] as double? ?? 0);
        if (sim > 0.6) {
          ragReference +=
              '• ${r['query']} → ${r['response']} (유사도 ${(sim * 100).toStringAsFixed(1)}%)\n';
        }
      }
    }

    // --- GPT 첫 턴 (세션 시작) ---
    if (history.isEmpty) {
      final contextPrompt = '''
당신은 따뜻하고 공감적인 CBT 상담사입니다.
지금은 ${userName}님의 ${week}주차 세션(${topic})을 시작하는 시점이에요.

이번 주 단계:
$conceptText

최근 활동 요약:
$weekSummary

최근 수행한 활동(앵커):
$anchor

주차별 주요 데이터:
${contextItems.isNotEmpty ? contextItems : '(관련 데이터 없음)'}

이 정보를 바탕으로:
1) 사용자의 최근 활동을 한두 문장으로 요약 (“최근에는 ○○ 활동을 하셨네요.”)
2) 그 경험을 통해 느낀 점이나 변화, 어려움을 공감적으로 물어보기

조건:
- ‘과제’ 대신 ‘활동’, ‘연습’, ‘시도’ 등의 표현 사용
- 존댓말, 공감형 어조 유지 (“~느끼셨나요?”, “~어땠나요?”)
- 구체적인 활동명을 언급
- 인용부호나 목록 사용 금지
---
$ragReference
''';

      final firstMessage = await api.chat([], contextPrompt);
      out.add({
        'sender': 'ai',
        'role': 'assistant',
        'message': firstMessage.trim(),
      });
      return out;
    }

    // --- 이후 턴: 인지왜곡 검증 ---
    final verdict =
        await agents.validate(history, userMessage, attachedDiary: attachedDiary);
    final valid = verdict['valid'] == true;

    if (!valid) {
      debugPrint('⚠️ [Validator] 인지왜곡 감지: ${verdict['distortions']}');
    }

    // --- GPT 후속 대화 ---
    final nextPrompt = '''
당신은 ${week}주차 (${topic}) 단계의 CBT 상담을 진행 중입니다.
현재 세션 단계(stage)는 ${inferredStage}입니다.
다음 정보를 모두 참고해 응답을 생성하세요.

최근 활동 요약:
$weekSummary

주차별 관련 데이터:
${contextItems.isNotEmpty ? contextItems : '(관련 데이터 없음)'}

조건:
- 따뜻하고 공감적인 어조 유지
- 사용자의 감정, 생각, 행동을 반영하며 탐색 유도
- 한 번에 하나의 주제만 다룸
- ‘과제’ 대신 ‘활동’, ‘시도’, ‘연습’ 등의 표현 사용
- 인용부호, 번호, 해시태그 금지
---
RAG 참고:
$ragReference
''';

    final stepReply = await api.chat(
      [...history, {'role': 'user', 'content': userMessage}],
      nextPrompt,
    );

    out.add({
      'sender': 'ai',
      'role': 'assistant',
      'message': stepReply.trim(),
    });

    return out;
  }
}
