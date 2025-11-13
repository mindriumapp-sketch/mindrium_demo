// lib/main.dart (2025-10-22 — 완전 통합 버전)
// Stage-based emotion + spike + streak relief + GPT logs + RAG
import 'dart:io' if (dart.library.html) 'utils/file_stub.dart' show Platform, File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:async';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

// --- services ---
import 'services/gpt_api.dart';
import 'services/agents.dart';
import 'services/orchestrator.dart';
import 'services/daily_context.dart';
import 'ui/chat_bubble.dart';
import 'services/data_repo.dart' show DataRepo, defaultUserId;

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const ChatApp());
// }

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const ChatPage();
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // ⚠️ Demo API key — replace with proxy/server injection in production
  static const _apiKey = '';

  // ===== Emotion Decision Parameters =====
  static const double kSwitchStrong = 0.92; // spike accept threshold
  static const double kAltStrong = 0.85;    // streak relief minimum confidence
  static const int kMaxStreak = 3;          // max consecutive identical tone

  final Map<String, String> _defaultByStage = const {
    'define': '생각중',
    'evidence': '생각중',
    'reframe': '따뜻한미소',
    'experiment': '안심격려',
    'wrapup': '따뜻한공감',
  };

  String _lastEmotion = '무표정';
  int _sameEmotionStreak = 0;

  // ===== Services =====
  late final GptApi _api;
  late final Agents _agents;
  late final Orchestrator _orc;
  late final DataRepo _repo;

  // ===== Chat State =====
  String? _selectedUserId;
  String? _anchorToday;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;
  File? _jsonLogFile;
  final bool _autoTurn = true;
  final bool _autoSend = true;

  // ===== Conversation Context =====
  final List<Map<String, String>> _history = [
    {
      'role': 'system',
      'content':
          '당신은 인지행동치료(CBT)를 적용하는 따뜻하고 공감적인 상담사입니다. '
          '사용자의 일기나 기록에 기반하여 대화를 시작하고, 부드럽게 감정 및 생각 탐색, '
          '그리고 행동 실험으로 유도하세요. 항상 친절하고 인간적인 톤으로 진행되어야 하며, '
          '사용자에게 부담을 주지 않도록 주의하세요.'
    },
  ];
  final List<Map<String, String>> _uiMessages = [];

  // ===== STT/TTS =====
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  bool _listening = false;
  String _recognized = '';

  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  bool _ttsEnabled = true;
  bool _isTtsSpeaking = false;

  DateTime? _sttGuardUntil;
  final Duration _sttCooldown = const Duration(seconds: 3); // 1031 수정 (기존; milliseconds:800)
  bool _ttsPrimed = false;
  bool _userGestured = false;
  DateTime? _listenStartedAt;
  bool get _canStartListening {
    if (_isTtsSpeaking) return false;
    if (_sttGuardUntil != null && DateTime.now().isBefore(_sttGuardUntil!)) return false;
    if (!_sessionOpen) return false;
    return true;
  }

  int _userTurnsInSession = 0;
  bool _sessionOpen = true;

  // ===== CBT Stage =====
  String _conversationStage = 'define';

  // ===== Emotion Avatars =====
  String _currentAvatar = 'assets/images/counselor_profile.png';
  final Map<String, String> _emotionToAsset = const {
    '공감슬픔': 'assets/images/counselor_profile_sad.png',
    '난처조심': 'assets/images/counselor_profile_careful.png',
    '놀람': 'assets/images/counselor_profile_surprised.png',
    '따뜻한미소': 'assets/images/counselor_profile_warm_smile.png',
    '따뜻한공감': 'assets/images/counselor_profile_warm_empathy.png',
    '무표정': 'assets/images/counselor_profile_neutral.png',
    '생각중': 'assets/images/counselor_profile_thinking.png',
    '안심격려': 'assets/images/counselor_profile_reassure.png',
    '안타까움': 'assets/images/counselor_profile_sad2.png',
  };

  String _assetForEmotion(String emo) => _emotionToAsset[emo] ?? _emotionToAsset['무표정']!;

  Map<String, String> _pickEmotionAvatar(String text) {
    final t = text.toLowerCase();
    String emo = '무표정';
    String reason = '기본값';
    if (RegExp(r'(미안|죄송|곤란|조심|불편|어렵|힘들|우울|슬프|눈물|속상)').hasMatch(t)) {
      emo = '공감슬픔'; reason = '슬픔/부담 키워드';
    } else if (RegExp(r'(깜짝|놀람|헉|충격|정말요|진짜요)').hasMatch(t)) {
      emo = '놀람'; reason = '놀람 키워드';
    } else if (RegExp(r'(다행|편안|안심|괜찮)').hasMatch(t)) {
      emo = '안심격려'; reason = '안심 키워드';
    } else if (RegExp(r'(생각|고민|정리|되돌아)').hasMatch(t)) {
      emo = '생각중'; reason = '성찰 키워드';
    } else if (RegExp(r'(따뜻|위로|고마|격려|응원|좋아요|잘하셨어요|멋져요|훌륭)').hasMatch(t)) {
      emo = '따뜻한공감'; reason = '긍정/격려 키워드';
    }
    final asset = _emotionToAsset[emo] ?? _emotionToAsset['무표정']!;
    return {'asset': asset, 'emotion': emo, 'reason': reason};
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  // ===== Initialization =====
  Future<void> _bootstrap() async {
    try {
      await _initJsonLog();

      _api = GptApi(_apiKey, embeddingModel: 'text-embedding-3-large');
      _agents = Agents(_api);
      _repo = DataRepo();

      // ✅ 사용자 데이터 로드 후 completedWeek 반영
      final user = await _repo.getUser(defaultUserId);
      final int currentWeek = user?['completedWeek'] ?? 1;
      debugPrint('[BOOT] Loaded user=$defaultUserId, completedWeek=$currentWeek');

      _orc = Orchestrator(_agents, _api, _repo, currentWeek: currentWeek);

      await Future.wait([_initTts(), _initStt(), _orc.initializeRag()]);

      setState(() => _selectedUserId = defaultUserId);
      await _openWithData();
    } catch (e, st) {
      debugPrint('bootstrap error: $e\n$st');
    }
  }

  // ===== 로그 =====
  Future<void> _initJsonLog() async {
    if (kIsWeb) return; // 웹은 path_provider 미지원 → 스킵
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!await logsDir.exists()) await logsDir.create(recursive: true);
      final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
      _jsonLogFile = File('${logsDir.path}/chat_session_$ts.json');
      await _jsonLogFile!.writeAsString(jsonEncode({
        'sessionId': ts,
        'startedAt': DateTime.now().toIso8601String(),
        'messages': <Map<String, dynamic>>[]
      }), flush: true);
    } catch (e) {
      debugPrint('init json log error: $e');
    }
  }

  Future<void> _appendJsonLogMessage({
    required String role,
    required String text,
    Map<String, dynamic>? extra,
  }) async {
    if (kIsWeb || _jsonLogFile == null) return;
    try {
      final raw = await _jsonLogFile!.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final List<dynamic> messages = (data['messages'] as List?) ?? <dynamic>[];
      messages.add({
        'ts': DateTime.now().toIso8601String(),
        'role': role,
        'text': text,
        if (extra != null) ...extra,
      });
      data['messages'] = messages;
      await _jsonLogFile!.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('append json log error: $e');
    }
  }

  // ===== STT / TTS =====
  Future<void> _initStt() async {
    _speechReady = await _speech.initialize(
      onStatus: (s) async {
        debugPrint('STT status: $s');

        // 조기 종료(시작 ≤3초)면 부드럽게 1회 재시작
        final started = _listenStartedAt;
        final elapsed = started == null ? Duration.zero : DateTime.now().difference(started);
        if ((s == 'done' || s == 'notListening') && elapsed < const Duration(seconds: 3)) {
          await Future.delayed(const Duration(milliseconds: 250));
          if (!_listening && _speechReady && _canStartListening) {
            await _toggleListening();
            return;
          }
        }
        if (s == 'notListening') {
          if (_listening) setState(() => _listening = false);
          if (_autoSend && _recognized.trim().isNotEmpty) {
            _controller.text = _recognized.trim();
            await _send();
          }
        }
      },
      onError: (e) {
        final detail = e.permanent ? ' (permanent)' : '';
        final rawMsg = e.errorMsg.trim();
        final errorText = rawMsg.isEmpty ? '알 수 없는 오류' : rawMsg;
        _appendUi('notice', 'STT 오류: $errorText$detail');
      },
      debugLogging: true,
    );
    if (!_speechReady) {
      _appendUi('notice', '마이크 초기화에 실패했습니다. (권한/HTTPS 확인)');
    }
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ko-KR');
      if (kIsWeb) {
        await _tts.setSpeechRate(0.5); // 0.9 -> 1031 수정
      } else if (Platform.isAndroid) {
        await _tts.setSpeechRate(0.5); // 0.9 -> 1031 수정
      } else if (Platform.isIOS) {
        await _tts.setSpeechRate(0.5);
        await _tts.setSharedInstance(true);
      } else {
        await _tts.setSpeechRate(1.0);
      }
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);

      try {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.duckOthers
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      } catch (_) {}

      _tts.setStartHandler(() async {
        _isTtsSpeaking = true;
        if (_speech.isListening) {
          try {
            await _speech.stop();
          } catch (_) {}
          if (mounted) setState(() => _listening = false);
        }
      });
      _tts.setCompletionHandler(() async {
        _isTtsSpeaking = false;
        _sttGuardUntil = DateTime.now().add(_sttCooldown);
        await Future.delayed(const Duration(seconds: 1)); // 1031 수정. 추가
        if (mounted) setState(() {});
      });
      _tts.setCancelHandler(() async {
        _isTtsSpeaking = false;
        _sttGuardUntil = DateTime.now().add(_sttCooldown);
        if (mounted) setState(() {});
      });
      _tts.setErrorHandler((msg) async {
        debugPrint('TTS error: $msg');
        _isTtsSpeaking = false;
        _sttGuardUntil = DateTime.now().add(_sttCooldown);
        if (mounted) setState(() {});
      });

      _ttsReady = true;
    } catch (e) {
      _ttsReady = false;
      _appendUi('notice', 'TTS 초기화 실패: $e');
    }
  }

  // 🔊 웹용 TTS priming: 사용자 제스처 이후 1회만 수행
  Future<void> _primeTts() async {
    if (_ttsPrimed || !_ttsReady || !_ttsEnabled) return;
    if (!kIsWeb) {
      _ttsPrimed = true;
      return;
    }
    try {
      await _tts.setVolume(0.0);
      await _tts.speak('a');
      await Future.delayed(const Duration(milliseconds: 200));
      await _tts.stop();
      await _tts.setVolume(1.0);
      _ttsPrimed = true;
      debugPrint('TTS primed.');
    } catch (e) {
      debugPrint('TTS prime failed: $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!_ttsReady || !_ttsEnabled) return;

    if (kIsWeb && !_userGestured) {
      _appendUi('notice', '스피커 버튼을 한번 눌러 음성을 활성화해 주세요.');
      return;
    }
    await _primeTts();

    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
      setState(() => _listening = false);
    }

    String norm = text.replaceAll('\n', ' ').trim();
    norm = norm.replaceAll(RegExp(r'\*\*'), '').replaceAll(RegExp(r'\*'), '');
    if (norm.isEmpty) return;

    final completer = Completer<void>();
    _isTtsSpeaking = true;
    _sttGuardUntil = null;

    _tts.setCompletionHandler(() async {
      _isTtsSpeaking = false;
      _sttGuardUntil = DateTime.now().add(_sttCooldown);
      if (!completer.isCompleted) completer.complete();
      if (mounted) setState(() {});
    });
    _tts.setCancelHandler(() async {
      _isTtsSpeaking = false;
      _sttGuardUntil = DateTime.now().add(_sttCooldown);
      if (!completer.isCompleted) completer.complete();
      if (mounted) setState(() {});
    });
    _tts.setErrorHandler((msg) async {
      debugPrint('TTS error (speak): $msg');
      _isTtsSpeaking = false;
      _sttGuardUntil = DateTime.now().add(_sttCooldown);
      if (!completer.isCompleted) completer.complete();
      if (mounted) setState(() {});
    });

    await _tts.stop();
    final result = await _tts.speak(norm);
    if (result == 1) {
      await completer.future.timeout(const Duration(seconds: 60), onTimeout: () {});
    }

    // 자동 STT는 쿨다운 이후에만
    if (_autoTurn && _sessionOpen && _speechReady && mounted) {
      final now = DateTime.now();
      final until = _sttGuardUntil ?? now;
      final wait = until.isAfter(now) ? until.difference(now) : Duration.zero;
      if (wait > Duration.zero) await Future.delayed(wait);
      // 1031 수정 🕒 TTS → STT 전환 딜레이 추가
      await Future.delayed(const Duration(seconds: 1)); // 1초~2초 정도 추천
      if (_canStartListening && !_speech.isListening && !_listening) {
        await _toggleListening();
      }
    }
  }

  // ===== STT 토글 =====
  Future<void> _toggleListening() async {
    _userGestured = true;
    await _primeTts();
    await _waitForGuard();

    // 1031 수정 마이크 초기화 안정화 시간 추가
    await Future.delayed(const Duration(milliseconds: 800));

    if (!_speechReady) {
      _appendUi('notice', 'STT 준비 안됨');
      return;
    }
    if (!_canStartListening) {
      await _waitForGuard();
      if (!_canStartListening) {
        _appendUi('notice', '지금은 음성을 시작할 수 없어요');
        return;
      }
    }

    if (_listening) {
      try {
        await _speech.cancel(); // 1031 수정 stop() -> cancel()
      } catch (_) {}
      setState(() => _listening = false);
      if (_recognized.trim().isNotEmpty) {
        _controller.text = _recognized.trim();
        await _send();
      }
      return;
    }

    if (!_speech.isAvailable) {
      _appendUi('notice', '마이크 사용이 불가합니다');
      return;
    }

    setState(() {
      _recognized = '';
      _listening = true;
    });

    _listenStartedAt = DateTime.now();
    await _speech.listen(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 100), // 1031 수정
      pauseFor: const Duration(seconds: 15), // 1031 수정
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
      onResult: (r) async {
        // 🎤 실시간 인식된 단어를 바로 입력창에 반영
        setState(() {
          _recognized = r.recognizedWords;
          _controller.text = r.recognizedWords;
        });

        // 🎯 최종 결과일 때만 자동 전송
        if (_autoSend && r.finalResult && _recognized.trim().isNotEmpty) {
          await Future.delayed(const Duration(seconds: 2)); // 1031 수정 텀 추가
          try {
            await _speech.stop();
          } catch (_) {}
          setState(() => _listening = false);
          await _send();
          _controller.clear();
        }
      },
    );
  }

  Future<void> _waitForGuard() async {
    final now = DateTime.now();
    final until = _sttGuardUntil ?? now;
    final wait = until.isAfter(now) ? until.difference(now) : Duration.zero;
    if (wait > Duration.zero) await Future.delayed(wait);
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildAiProfileFor(String assetPath) {
    return CircleAvatar(
      radius: 32,
      backgroundImage: AssetImage(assetPath),
      backgroundColor: Colors.transparent,
    );
  }

  // ===== 사용자 데이터 열기 =====
  Future<void> _openWithData() async {
    if (_selectedUserId == null || _loading) return;

    setState(() {
      _loading = true;
      _uiMessages.clear();
      _userTurnsInSession = 0;
    });

    final user = await _repo.getUser(_selectedUserId!);
    if (user == null) {
      setState(() {
        _loading = false;
        _uiMessages.add({'sender': 'ai', 'message': '사용자 데이터를 찾을 수 없습니다.'});
      });
      return;
    }

    // ✅ 주차 계산 방식 변경 (weekNumber 없을 때 날짜 기반)
    final int week = user['completedWeek'] ?? 1;
    final userName = user['name'] ?? '사용자님';

    // ✅ 수정된 DailyContext 호출
    final summary = DailyContext.buildWeekSummary(user, week);
    final anchor = DailyContext.buildLatestAnchor(user);

    // 🧭 주차별 톤 (기존 동일)
    final conceptText = switch (week) {
      1 => '이번 주는 디지털 치료기기를 익히며 자기관리를 시작하는 단계예요.',
      2 => '이번 주는 걱정 일기(ABC)를 중심으로 생각과 감정을 함께 탐색해볼 거예요.',
      3 || 4 => '이번 주는 인지치료 단계예요. 떠오르는 생각과 그 근거를 함께 살펴봐요.',
      5 || 6 => '이번 주는 행동치료 단계예요. 불안을 피하지 않고 직면하는 연습을 이어가볼까요?',
      7 => '이번 주는 생활습관 교정 단계예요. 수면, 운동, 명상 루틴을 점검해볼 시간이에요.',
      8 => '이번 주는 치료를 마무리하며 지난 변화를 돌아보는 단계예요.',
      _ => '오늘은 최근 경험을 중심으로 이야기를 나눠볼까요?',
    };

    // 🧠 요약 + 앵커 통합 텍스트
    final contextSummary = '''
  안녕하세요, $userName님. $conceptText

  📘 최근 기록 요약:
  $summary

  🪞 최근 앵커 기록:
  $anchor
  ''';

    // 🧩 GPT에게 “요약 + 앵커 기반 오프닝 생성” 요청
    final openingPrompt = '''
  당신은 따뜻하고 공감적인 CBT 상담사입니다.
  아래 사용자의 최근 기록을 참고하여,
  "활동 내용을 간단히 되짚고, 자연스럽게 유도하는 질문" 한 문단을 생성하세요.

  조건:
  - '과제' 대신 '활동', '연습', '시도' 등의 단어 사용
  - 사용자의 최근 활동 내용을 한 문장 정도 상기시킨 후 질문으로 마무리
  - 너무 추상적인 질문 피하고, 대답 방향이 보이게 유도
  - 존댓말 사용, 2~3문장 내로 자연스럽게 작성
  ---
  $contextSummary
  ''';

    String firstMessage;
    try {
      firstMessage = await _api.chat([], openingPrompt);
    } catch (e) {
      firstMessage = '안녕하세요, $userName님. 이번 주 대화를 시작해볼까요?';
    }

    final neutral = _emotionToAsset['무표정']!;
    setState(() {
      _uiMessages.add({
        'sender': 'ai',
        'message': firstMessage.trim(),
        'role': 'assistant',
        'avatar': neutral,
      });
      _currentAvatar = neutral;
      _loading = false;
      _conversationStage = 'define';
      _lastEmotion = '무표정';
      _sameEmotionStreak = 0;
    });

    if (!kIsWeb) {
      await _speak(firstMessage);
    } else {
      _appendUi('notice', '스피커 또는 마이크 버튼을 눌러 음성을 활성화해 주세요.');
    }
  }


  // ===== 감정 선택 규칙 =====
  String _decideEmotionLabel({
    required String stage,
    required String gptLabel,
    required double? confidence,
    required String messageForHeuristic,
  }) {
    String rule = 'stage-default';
    String pick = _defaultByStage[stage] ?? '따뜻한공감';

    if (confidence != null && confidence >= kSwitchStrong) {
      pick = gptLabel;
      rule = 'strong-spike';
    } else if (confidence != null && confidence >= 0.9 && gptLabel != pick) {
      pick = gptLabel;
      rule = 'stage+accept-90';
    }

    if (_lastEmotion == pick) {
      _sameEmotionStreak += 1;
    } else {
      _sameEmotionStreak = 1;
    }

    if (_sameEmotionStreak >= kMaxStreak) {
      final alt = _pickEmotionAvatar(messageForHeuristic)['emotion'] ?? '무표정';
      if (alt != pick && (confidence == null || confidence >= kAltStrong)) {
        pick = alt;
        rule = 'streak-relief';
      }
      _sameEmotionStreak = 0;
    }

    _lastEmotion = pick;
    debugPrint('[EMO][DECIDE] stage=$stage pick=$pick rule=$rule');
    return pick;
  }

  // ===== 전송 로직 =====
  Future<void> _send() async {
    _userGestured = true;
    await _primeTts();
    if (!_sessionOpen) return;

    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    try {
      await _tts.stop();
    } catch (_) {}

    setState(() {
      _controller.clear();
      _uiMessages.add({'sender': 'user', 'message': text, 'role': 'user'});
      _loading = true;
    });
    _appendJsonLogMessage(role: 'user', text: text);
    _jumpToBottom();

    if (!_history.any((m) => m['content']?.startsWith('[stage]') ?? false)) {
      _history.add({'role': 'system', 'content': '[stage] $_conversationStage'});
    }

    _history.add({'role': 'user', 'content': text});

    String lastAiMessage = '응답을 생성하지 못했습니다.';

    try {
      final result = await _orc.handle(_history, text, attachedDiary: _anchorToday);

      for (final msg in result) {
        if (msg['sender'] == 'ai') {
          final replyText = msg['message'] ?? '';
          lastAiMessage = replyText;

          // 🎭 감정 분석 및 아바타 적용
          String finalLabel = '무표정';
          String asset = _assetForEmotion('무표정');
          try {
            final emo = await _agents.analyzeEmotion(lastAiMessage);
            final label = emo['emotion'] ?? '무표정';
            final conf = (emo['confidence'] is num)
                ? (emo['confidence'] as num).toDouble()
                : 0.8;
            finalLabel = _decideEmotionLabel(
              stage: _conversationStage,
              gptLabel: label,
              confidence: conf,
              messageForHeuristic: lastAiMessage,
            );
            asset = _assetForEmotion(finalLabel);
          } catch (e) {
            final h = _pickEmotionAvatar(lastAiMessage);
            finalLabel = _decideEmotionLabel(
              stage: _conversationStage,
              gptLabel: h['emotion']!,
              confidence: null,
              messageForHeuristic: lastAiMessage,
            );
            asset = h['asset']!;
          }

          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          setState(() {
            _uiMessages.add({...msg, 'avatar': asset});
            _currentAvatar = asset;
          });

          _appendJsonLogMessage(role: 'ai', text: lastAiMessage);
          _jumpToBottom();

          // ✅ 상담사 발화 1회만 TTS 출력
          await _speak(lastAiMessage);
        }
      }

      _history.add({'role': 'assistant', 'content': lastAiMessage});
      _updateStageBy(lastAiMessage);
      _userTurnsInSession++;
      debugPrint('[TURN] userTurns=$_userTurnsInSession');

    } catch (e) {
      lastAiMessage = '죄송합니다. 오류가 발생했습니다: $e';
      _uiMessages.add({'sender': 'ai', 'message': lastAiMessage, 'role': 'assistant'});
      // ⚠️ 오류 시에만 한 번 읽기
      await _speak(lastAiMessage);
    } finally {
      setState(() => _loading = false);
      _jumpToBottom();

      // ❌ 여기서 _speak 제거됨 (중복 재생 방지)

      if (_userTurnsInSession >= 5 && _sessionOpen) {
        _sessionOpen = false;
        if (mounted) {
          await _showSummaryDialog(context);
        }
      }
    }
  }

  // ===== 스테이지 업데이트 =====
  void _updateStageBy(String message) {
    final lower = message.toLowerCase();
    String next = _conversationStage;

    if (lower.contains('증거') || lower.contains('근거')) {
      next = 'evidence';
    } else if (lower.contains('다르게') || lower.contains('대안')) {
      next = 'reframe';
    } else if (lower.contains('실험') || lower.contains('시도')) {
      next = 'experiment';
    } else if (lower.contains('정리') || lower.contains('요약')) {
      next = 'wrapup';
    }

    setState(() => _conversationStage = next);
    debugPrint('[STAGE] -> $next');
  }

  // ===== Wrap-up 요약 =====
  Future<void> _generateSummary() async {
    final turnCount = _userTurnsInSession;
    final histLen = _history.where((m) => m['role'] == 'user' || m['role'] == 'assistant').length;
    debugPrint('[SUMMARY] histLen=$histLen, turns=$turnCount');

    if (histLen < 6) {
      _appendUi('notice', '아직 요약할 대화가 부족합니다.');
      if (!_sessionOpen) setState(() => _sessionOpen = true);
      return;
    }

    final lastUser = _history.lastWhere(
      (m) => m['role'] == 'user',
      orElse: () => {'content': ''},
    )['content'] ?? '';

    final lastAi = _history.lastWhere(
      (m) => m['role'] == 'assistant',
      orElse: () => {'content': ''},
    )['content'] ?? '';

    try {
      final summary = await _agents.summarize(_history, lastUser, lastAi);

      _uiMessages.add({
        'sender': 'ai',
        'message': summary,
        'role': 'assistant',
      });

      setState(() {
        _conversationStage = 'wrapup';
        _sessionOpen = false;
      });

      _appendJsonLogMessage(role: 'ai', text: summary);
      await _speak(summary);
    } catch (e) {
      _appendUi('notice', '요약 실패: $e');
      // ✅ 요약 실패 시 세션 다시 활성화
      if (!_sessionOpen) {
        setState(() => _sessionOpen = true);
      }
    }
  }

  Future<void> _showSummaryDialog(BuildContext context) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('대화 마무리'),
        content: const Text('지금까지의 대화를 잠시 정리할까요, 아니면 조금 더 이어갈까요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _generateSummary();
            },
            child: const Text('정리하기'),
          ),
          TextButton(
            onPressed: () async{ //1031 async 추가
              Navigator.of(context).pop();
              setState(() {
                _sessionOpen = true;
                _userTurnsInSession = 0;
              });
              await Future.delayed(const Duration(seconds: 2)); // 1031 수정. 딜레이 추가
              _appendUi('ai', '좋아요, 조금 더 이야기해볼까요? 최근에 마음에 남은 일이나 생각이 있었나요?');
            },
            child: const Text('계속 대화'),
          ),
        ],
      ),
    );
  }

  void _appendUi(String role, String msg) {
    if (mounted) {
      setState(() => _uiMessages.add({'sender': 'ai', 'role': role, 'message': msg}));
      _jumpToBottom();
    }
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          splashRadius: 22,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_)=>false),
        ),
      ),
        title: const Text('디지털 CBT 상담'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: '세션 재시작',
            onPressed: _openWithData,
          ),
          IconButton(
            icon: const Icon(Icons.summarize),
            tooltip: '요약 생성',
            onPressed: _generateSummary,
          ),
          IconButton(
            icon: Icon(_ttsEnabled ? Icons.volume_up : Icons.volume_off),
            tooltip: '음성 출력 전환',
            onPressed: () => setState(() => _ttsEnabled = !_ttsEnabled),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                itemCount: _uiMessages.length,
                itemBuilder: (context, i) {
                  final m = _uiMessages[i];
                  final sender = m['sender'] ?? '';
                  final msg = m['message'] ?? '';
                  final avatar = m['avatar'] ?? _currentAvatar;
                  final role = m['role'] ?? 'assistant';

                  if (role == 'notice') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Text(
                        msg,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: ChatBubble(
                      text: msg,
                      isAi: sender == 'ai',
                      profileWidget: (sender == 'ai' && role != 'notice')
                          ? Padding(
                              padding: const EdgeInsets.only(left: 8.0, right: 6.0),
                              child: _buildAiProfileFor(avatar),
                            )
                          : const Padding(
                              padding: EdgeInsets.only(left: 8.0, right: 6.0),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.transparent,
                                backgroundImage: AssetImage('assets/images/user_profile.png'),
                              ),
                            ),
                      isNotice: role == 'notice',
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                        color: _listening ? Colors.redAccent : Colors.grey),
                    onPressed: _toggleListening,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _loading ? '응답 생성 중...' : '메시지를 입력하세요',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: _loading ? Colors.grey : Colors.blueAccent,
                    onPressed: _loading ? null : _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    try {
      _speech.stop();
      _tts.stop();
    } catch (_) {}
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
