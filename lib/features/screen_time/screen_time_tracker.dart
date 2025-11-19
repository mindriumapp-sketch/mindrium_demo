import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/screen_time_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// Automatically records foreground screen time sessions by observing the app lifecycle.
class ScreenTimeAutoTracker extends StatefulWidget {
  const ScreenTimeAutoTracker({required this.child, super.key});

  final Widget child;

  @override
  State<ScreenTimeAutoTracker> createState() => _ScreenTimeAutoTrackerState();
}

class _ScreenTimeAutoTrackerState extends State<ScreenTimeAutoTracker>
    with WidgetsBindingObserver {
  static const _prefsKey = 'screen_time_session_start';
  static const _pendingKey = 'screen_time_pending_sessions';
  static const _minSessionSeconds = 5;

  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final ScreenTimeApi _screenTimeApi = ScreenTimeApi(_apiClient);

  SharedPreferences? _prefs;
  DateTime? _activeSessionStartUtc;
  bool _initialised = false;
  bool _isClosingActive = false;
  bool _isFlushingQueue = false;
  final bool _trackingEnabled = !kIsWeb;

  @override
  void initState() {
    super.initState();
    if (_trackingEnabled) {
      WidgetsBinding.instance.addObserver(this);
      _bootstrap();
    }
  }

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    await _recoverCrashedSession();
    await _flushPendingQueue();
    _initialised = true;

    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState == null || lifecycleState == AppLifecycleState.resumed) {
      unawaited(_startSession());
    }
  }

  Future<void> _recoverCrashedSession() async {
    final stored = _prefs?.getString(_prefsKey);
    if (stored == null) return;
    final parsed = DateTime.tryParse(stored)?.toUtc();
    await _prefs?.remove(_prefsKey);
    if (parsed == null) return;
    await _enqueuePending(parsed, DateTime.now().toUtc(), _platformLabel());
  }

  @override
  void dispose() {
    if (_trackingEnabled) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_initialised || !_trackingEnabled) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_startSession());
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        unawaited(_completeCurrentSession());
        break;
    }
  }

  Future<void> _startSession() async {
    if (!_trackingEnabled) return;
    if (_activeSessionStartUtc != null || _isClosingActive) return;
    final now = DateTime.now().toUtc();
    _activeSessionStartUtc = now;
    await _prefs?.setString(_prefsKey, now.toIso8601String());
    unawaited(_flushPendingQueue());
  }

  Future<void> _completeCurrentSession() async {
    if (!_trackingEnabled) return;
    if (_activeSessionStartUtc == null || _isClosingActive) return;
    _isClosingActive = true;
    final start = _activeSessionStartUtc!;
    final end = DateTime.now().toUtc();
    final platform = _platformLabel();
    final seconds = end.difference(start).inSeconds;

    _activeSessionStartUtc = null;
    await _prefs?.remove(_prefsKey);

    if (seconds < _minSessionSeconds) {
      _isClosingActive = false;
      return;
    }

    try {
      await _screenTimeApi.logSession(
        start: start,
        end: end,
        platform: platform,
      );
    } on DioException catch (e, stack) {
      debugPrint('Failed to log screen time: ${e.message}');
      if (kDebugMode) {
        debugPrintStack(stackTrace: stack);
      }
      await _enqueuePending(start, end, platform);
    } finally {
      _isClosingActive = false;
      unawaited(_flushPendingQueue());
    }
  }

  Future<void> _enqueuePending(
    DateTime start,
    DateTime end,
    String? platform,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final payload = jsonEncode({
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'platform': platform,
    });
    final queue = prefs.getStringList(_pendingKey) ?? <String>[];
    queue.add(payload);
    await prefs.setStringList(_pendingKey, queue);
  }

  Future<void> _flushPendingQueue() async {
    final prefs = _prefs;
    if (prefs == null || _isFlushingQueue) return;
    final queue = List<String>.from(prefs.getStringList(_pendingKey) ?? const []);
    if (queue.isEmpty) return;
    _isFlushingQueue = true;

    try {
      final remaining = <String>[];
      for (final raw in queue) {
        final payload = _decodePendingPayload(raw);
        if (payload == null) {
          continue;
        }
        try {
          await _screenTimeApi.logSession(
            start: payload.start,
            end: payload.end,
            platform: payload.platform ?? _platformLabel(),
          );
        } on DioException catch (e) {
          debugPrint('Retrying screen time later: ${e.message}');
          remaining.add(raw);
        }
      }

      await prefs.setStringList(_pendingKey, remaining);
    } finally {
      _isFlushingQueue = false;
    }
  }

  _PendingPayload? _decodePendingPayload(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final start = DateTime.tryParse(json['start']?.toString() ?? '')?.toUtc();
      final end = DateTime.tryParse(json['end']?.toString() ?? '')?.toUtc();
      if (start == null || end == null) return null;
      return _PendingPayload(
        start: start,
        end: end,
        platform: json['platform'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  String? _platformLabel() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return "android";
      case TargetPlatform.iOS:
        return "ios";
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return "desktop";
      case TargetPlatform.fuchsia:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PendingPayload {
  const _PendingPayload({
    required this.start,
    required this.end,
    this.platform,
  });

  final DateTime start;
  final DateTime end;
  final String? platform;
}
