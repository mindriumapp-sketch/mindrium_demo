
// File: lib/utils/battle_voice_selector.dart
// A thin wrapper around speech_to_text for the battle scene flow.
// Usage:
//   final voice = BattleVoiceSelector();
//   await voice.initialize();
//   voice.startListening(onPartial: (t){...}, onFinal:(t){...});
//   voice.stop(); voice.dispose();
//
// Also provides a simple best-match helper for alternative-thought chips.

import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;

typedef TextHandler = void Function(String);

class CharacterBattleAsr {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _ready = false;
  bool _listening = false;
  String _recognized = '';
  DateTime? _startedAt;

  bool get isReady => _ready;
  bool get isListening => _listening;
  String get recognizedText => _recognized;

  /// Initialize microphone/STT.
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    try {
      _ready = await _speech.initialize(
        onStatus: (s) {
          if (onStatus != null) onStatus(s);
          if (s == 'notListening') _listening = false;
        },
        onError: (e) {
          if (onError != null) onError(e);
          _listening = false;
        },
      );
    } catch (e) {
      _ready = false;
      if (onError != null) onError(e);
    }
    return _ready;
  }

  /// Start listening. Calls [onPartial] repeatedly and [onFinal] once.
  Future<void> startListening({
    String localeId = 'ko_KR',
    Duration listenFor = const Duration(seconds: 20),
    Duration pauseFor = const Duration(seconds: 3),
    TextHandler? onPartial,
    TextHandler? onFinal,
  }) async {
    if (!_ready) {
      final ok = await initialize();
      if (!ok) return;
    }
    _recognized = '';
    _listening = true;
    _startedAt = DateTime.now();

    await _speech.listen(
      localeId: localeId,
      listenFor: listenFor,
      pauseFor: pauseFor,
      partialResults: true,
      onResult: (r) {
        _recognized = r.recognizedWords;
        if (onPartial != null) onPartial(_recognized);
        if (r.finalResult) {
          _listening = false;
          if (onFinal != null) onFinal(_recognized.trim());
        }
      },
    );
  }

  /// Stop listening.
  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
    _listening = false;
  }

  void dispose() {
    // speech_to_text doesn't expose a dispose; make sure we stop.
    try { _speech.stop(); } catch (_) {}
  }

  // ---------- Matching Helpers ----------

  /// Return the index of the most similar entry in [skills] to [utter].
  /// Returns -1 if skills empty or utter empty.
  static int chooseBestIndex(List<String> skills, String utter) {
    final q = utter.trim().toLowerCase();
    if (q.isEmpty || skills.isEmpty) return -1;
    double best = -1;
    int bestIdx = -1;
    for (int i = 0; i < skills.length; i++) {
      final s = skills[i].toLowerCase();
      final score = _similarity(q, s);
      if (score > best) {
        best = score;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Token Jaccard + containment bonus.
  static double _similarity(String a, String b) {
    final ta = a.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).toSet();
    final tb = b.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).toSet();
    if (ta.isEmpty || tb.isEmpty) {
      return (a.contains(b) || b.contains(a)) ? 1.0 : 0.0;
    }
    final inter = ta.intersection(tb).length.toDouble();
    final union = (ta.length + tb.length - inter).toDouble();
    final jaccard = union == 0 ? 0.0 : inter / union;
    final contain = (a.contains(b) || b.contains(a)) ? 0.3 : 0.0;
    return jaccard + contain;
  }
}
