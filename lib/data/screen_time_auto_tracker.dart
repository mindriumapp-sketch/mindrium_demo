import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screen_time_provider.dart';

/// 자동 앱 세션 기록기: 앱 실행/백그라운드 전환 시간을 스크린타임으로 저장
class ScreenTimeAutoTracker extends ChangeNotifier with WidgetsBindingObserver {
  static const _storageKey = 'auto_screen_time_session_start';
  static const _autoLabel = '앱 자동 기록';

  ScreenTimeProvider _screenTimeProvider;
  DateTime? _sessionStart;
  bool _enabled = true;
  bool _restoring = false;

  ScreenTimeAutoTracker({required ScreenTimeProvider provider})
      : _screenTimeProvider = provider {
    WidgetsBinding.instance.addObserver(this);
    _restorePendingSession();
    WidgetsBinding.instance.addPostFrameCallback((_) => _beginSessionIfNeeded());
  }

  void updateProvider(ScreenTimeProvider provider) {
    _screenTimeProvider = provider;
  }

  void setEnabled(bool value) {
    _enabled = value;
    if (!_enabled) {
      _endSession(reason: 'disabled');
    } else {
      _beginSessionIfNeeded();
    }
  }

  Future<void> _restorePendingSession() async {
    _restoring = true;
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_storageKey);
    if (iso != null) {
      final stored = DateTime.tryParse(iso);
      if (stored != null) {
        _sessionStart = stored;
        await _endSession(reason: 'restore');
      } else {
        await prefs.remove(_storageKey);
      }
    }
    _restoring = false;
  }

  Future<void> _beginSessionIfNeeded() async {
    if (!_enabled || _restoring) return;
    if (_sessionStart != null) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    _sessionStart = now;
    await prefs.setString(_storageKey, now.toIso8601String());
  }

  Future<void> _endSession({String reason = 'pause'}) async {
    final start = _sessionStart;
    if (start == null) {
      // 혹시 저장된 값이 남아있으면 다시 로드
      final prefs = await SharedPreferences.getInstance();
      final iso = prefs.getString(_storageKey);
      if (iso == null) return;
      final parsed = DateTime.tryParse(iso);
      if (parsed == null) {
        await prefs.remove(_storageKey);
        return;
      }
      _sessionStart = parsed;
    }

    final sessionStart = _sessionStart;
    if (sessionStart == null) return;

    final end = DateTime.now();
    if (!end.isAfter(sessionStart)) {
      return;
    }

    try {
      await _screenTimeProvider.addEntry(
        startTime: sessionStart,
        endTime: end,
        label: _autoLabel,
        source: 'app-session',
        note: '상태: $reason',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      _sessionStart = null;
    } catch (_) {
      // 실패 시 다음 기회에 다시 시도하도록 start를 보존
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, sessionStart.toIso8601String());
      _sessionStart = sessionStart;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _beginSessionIfNeeded();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _endSession(reason: state.name);
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
