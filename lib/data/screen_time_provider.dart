import 'package:flutter/foundation.dart';

import 'api/api_client.dart';
import 'api/screen_time_api.dart';
import 'models/screen_time_entry.dart';
import 'models/screen_time_summary.dart';
import 'storage/token_storage.dart';

class ScreenTimeProvider extends ChangeNotifier {
  static const int _maxEntries = 200;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _client = ApiClient(tokens: _tokens);
  late final ScreenTimeApi _api = ScreenTimeApi(_client);
  static const String _defaultSource = 'app';

  List<ScreenTimeEntry> _entries = const [];
  ScreenTimeSummary? _summary;
  bool _isLoading = false;
  bool _initialized = false;
  Object? _lastError;
  Future<void>? _ongoingSync;
  bool _isLimitedView = false;

  List<ScreenTimeEntry> get entries => _entries;
  ScreenTimeSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;
  bool get isLimitedView => _isLimitedView;
  int get maxEntries => _maxEntries;

  Future<void> _syncFromServer() {
    _ongoingSync ??= Future.wait([
      _api.listEntries(limit: _maxEntries),
      _api.getSummary(),
    ]).then((results) {
      final fetchedEntries = List<ScreenTimeEntry>.unmodifiable(results[0] as List<ScreenTimeEntry>);
      final fetchedSummary = results[1] as ScreenTimeSummary;
      _entries = fetchedEntries;
      _summary = fetchedSummary;
      _isLimitedView = fetchedSummary.sessions > fetchedEntries.length;
    }).catchError((error) {
      _lastError = error;
      throw error;
    }).whenComplete(() {
      _ongoingSync = null;
    });
    return _ongoingSync!;
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_initialized && !force) return;
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      await _syncFromServer();
      _initialized = true;
    } catch (_) {
      // _lastError already set inside _syncFromServer
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _syncFromServer();
    } catch (_) {
      // handled in sync
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ScreenTimeEntry?> addEntry({
    required DateTime startTime,
    int? durationMinutes,
    DateTime? endTime,
    String? label,
    String? source,
    String? note,
  }) async {
    try {
      final entry = await _api.createEntry(
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        label: label,
        source: source ?? _defaultSource,
        note: note,
      );
      await _syncFromServer();
      notifyListeners();
      return entry;
    } catch (e) {
      _lastError = e;
      rethrow;
    }
  }

  Future<ScreenTimeEntry?> updateEntry(
    String entryId, {
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? label,
    String? source,
    String? note,
  }) async {
    try {
      final updated = await _api.updateEntry(
        entryId,
        startTime: startTime,
        endTime: endTime,
        durationMinutes: durationMinutes,
        label: label,
        source: source,
        note: note,
      );
      await _syncFromServer();
      notifyListeners();
      return updated;
    } catch (e) {
      _lastError = e;
      rethrow;
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _api.deleteEntry(entryId);
      await _syncFromServer();
      notifyListeners();
    } catch (e) {
      _lastError = e;
      rethrow;
    }
  }
}
