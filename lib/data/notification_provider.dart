// ─────────────────────────  Dart Std  ─────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

// ─────────────────────────  Flutter  ──────────────────────────
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

// ─────────────────────  3rd‑party Packages  ───────────────────
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:geofence_service/geofence_service.dart' as gf;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────  Local  ────────────────────────────
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/app.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/notification_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// ───────────────────────── MODELS ─────────────────────────
enum RepeatOption { none, daily, weekly }

class NotificationSetting {
  final RepeatOption repeatOption;
  final List<int> weekdays;
  final TimeOfDay? time;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? reminderMinutes;
  final String? description;
  final String? id;
  final String? abcId;
  final DateTime savedAt;
  final String? cause;
  final bool notifyEnter;
  final bool notifyExit;

  NotificationSetting({
    this.cause,
    this.time,
    this.repeatOption = RepeatOption.none,
    this.weekdays = const [],
    this.location,
    this.latitude,
    this.longitude,
    this.description,
    this.reminderMinutes,
    this.id,
    this.abcId,
    DateTime? savedAt,
    required this.notifyEnter,
    required this.notifyExit,
  }) : savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool includeSavedAt = true}) {
    final map = <String, dynamic>{
      'reminder_minutes': reminderMinutes,
      'description': description,
      'cause': cause,
      'notify_enter': notifyEnter,
      'notify_exit': notifyExit,
    };
    if (abcId != null) {
      map['abc_id'] = abcId;
    }
    if (includeSavedAt) {
      map['saved_at'] = savedAt.toIso8601String();
    }

    if (time != null) {
      final hh = time!.hour.toString().padLeft(2, '0');
      final mm = time!.minute.toString().padLeft(2, '0');
      final repForKey =
          (repeatOption == RepeatOption.none) ? RepeatOption.daily : repeatOption;
      final normalizedWeekdays = (repForKey == RepeatOption.weekly && weekdays.isNotEmpty)
          ? (weekdays.toSet().toList()..sort())
          : <int>[];
      final wdCsv = normalizedWeekdays.join(',');

      map['time'] = '$hh:$mm';
      map['repeat_option'] = repeatOption.name;
      if (normalizedWeekdays.isNotEmpty) {
        map['weekdays'] = normalizedWeekdays;
      }
      map['time_key'] = 't=$hh:$mm|rep=${repForKey.name}|wd=$wdCsv';
    }

    if (latitude != null && longitude != null) {
      map
        ..['latitude'] = latitude
        ..['longitude'] = longitude;
    }
    if (location != null && location!.isNotEmpty) {
      map['location'] = location;
    }
    if (description == null || description!.isEmpty) {
      map.remove('description');
    }
    map.removeWhere((key, value) => value == null);
    return map;
  }

  Map<String, dynamic> toMap({bool includeSavedAt = true}) =>
      toJson(includeSavedAt: includeSavedAt);

  factory NotificationSetting.fromJson(
    Map<String, dynamic> json, {
    String? id,
  }) {
    final repeatName = json['repeat_option'] ?? json['repeatOption'];
    final savedAtRaw = json['saved_at'] ?? json['savedAt'];

    return NotificationSetting(
      id: id ??
          json['id']?.toString() ??
          json['_id']?.toString() ??
          json['settingId']?.toString(),
      abcId: json['abc_id']?.toString() ?? json['abcId']?.toString(),
      time: _timeOfDayFrom(json['time']),
      repeatOption: _repeatOptionFrom(repeatName),
      weekdays: _weekdaysFrom(json['weekdays'] ?? json['weekDays']),
      latitude: _doubleFrom(json['latitude']),
      longitude: _doubleFrom(json['longitude']),
      location: json['location']?.toString(),
      cause: json['cause']?.toString(),
      description: json['description']?.toString(),
      reminderMinutes: _intFrom(json['reminder_minutes'] ?? json['reminderMinutes']),
      savedAt: _dateFrom(savedAtRaw),
      notifyEnter: _boolFrom(json['notify_enter'] ?? json['notifyEnter']),
      notifyExit: _boolFrom(json['notify_exit'] ?? json['notifyExit']),
    );
  }
}

TimeOfDay? _timeOfDayFrom(dynamic raw) {
  if (raw == null) return null;
  if (raw is TimeOfDay) return raw;
  final text = raw.toString();
  if (!text.contains(':')) return null;
  final parts = text.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

RepeatOption _repeatOptionFrom(dynamic raw) {
  if (raw == null) return RepeatOption.none;
  final text = raw.toString();
  return RepeatOption.values.firstWhere(
    (e) => e.name == text,
    orElse: () => RepeatOption.none,
  );
}

List<int> _weekdaysFrom(dynamic raw) {
  if (raw is List) {
    return raw
        .map((e) => e is num ? e.toInt() : int.tryParse(e.toString()) ?? 0)
        .where((e) => e > 0)
        .toSet()
        .toList()
      ..sort();
  }
  return const [];
}

double? _doubleFrom(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

int? _intFrom(dynamic raw) {
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw);
  return null;
}

DateTime? _dateFrom(dynamic raw) {
  if (raw is DateTime) return raw;
  if (raw is String) return DateTime.tryParse(raw);
  if (raw is int) {
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }
  return null;
}

bool _boolFrom(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final lower = raw.toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
  return false;
}

/// ───────────────────────── PROVIDER ─────────────────────────
class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _inst = NotificationProvider._internal();
  factory NotificationProvider() => _inst;
  NotificationProvider._internal() {
    _apiClient = ApiClient(tokens: _tokens);
    _notificationApi = NotificationApi(_apiClient);
    _ready = _init();
  }

  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient;
  late final NotificationApi _notificationApi;
  late final Future<void> _ready;
  NotificationSetting? _current;
  NotificationSetting? get current => _current;

  final _fln = FlutterLocalNotificationsPlugin();
  final _geofence = gf.GeofenceService.instance.setup(
    interval: 60000,
    accuracy: 100,
    loiteringDelayMs: 10000,
  );

  // 위치+시간 조합 타이머를 문서별로 관리
  final Map<String, List<Timer>> _locationTimersByDocId = {};
  final Map<String, List<int>> _scheduledNotificationIds = {};

  // ── Multi‑geofence support (문서별 Region/Setting/상태) ──
  final Map<String, gf.Geofence> _geoRegionByDocId = {};
  final Map<String, NotificationSetting> _geoSettingByDocId = {};

  String _regionIdForDoc(String docId) => 'record_region_$docId';
  String _docIdFromRegionId(String regionId) =>
      regionId.startsWith('record_region_') ? regionId.substring('record_region_'.length) : regionId;

  RepeatOption _effectiveRepeatOption(NotificationSetting s) {
    if (s.time != null && s.repeatOption == RepeatOption.none) {
      return RepeatOption.daily;
    }
    return s.repeatOption;
  }

  /// Returns a stable deduplication key for time-based schedules.
  /// Format: t=HH:MM|rep=daily|wd=1,3,5 (weekdays sorted, only if weekly)
  String? _timeKeyOf(NotificationSetting s) {
    if (s.time == null) return null;
    final rep = _effectiveRepeatOption(s);
    final hh = s.time!.hour.toString().padLeft(2, '0');
    final mm = s.time!.minute.toString().padLeft(2, '0');
    final normalizedWeekdays = (rep == RepeatOption.weekly && s.weekdays.isNotEmpty)
        ? (s.weekdays.toSet().toList()..sort())
        : <int>[];
    final wdCsv = normalizedWeekdays.join(',');
    return 't=$hh:$mm|rep=${rep.name}|wd=$wdCsv';
  }

  /* ─────────── 초기화 ─────────── */
  Future<void> _init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    await _fln.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        debugPrint('[NOTI] rawPayload=${resp.payload}');
        if (payload == null || !payload.startsWith('/') || navigatorKey.currentState == null) {
          return;
        }
        final uri = Uri.parse(payload);
        debugPrint('[NAV] path=${uri.path} params=${uri.queryParameters}');

        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          uri.path,
          (r) => r.isFirst,
          arguments: uri.queryParameters.isEmpty ? null : uri.queryParameters,
        );
      },
    );

    // 앱이 알림 클릭으로 시작된 경우 라우트 처리
    final launchDetails = await _fln.getNotificationAppLaunchDetails();
    final initialResp   = launchDetails?.notificationResponse;
    final initialPayload = initialResp?.payload;

    if ((launchDetails?.didNotificationLaunchApp ?? false) &&
        initialPayload?.startsWith('/') == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final uri = Uri.parse(initialPayload!);
        navigatorKey.currentState?.pushNamed(
          uri.path,
          arguments: uri.queryParameters,
        );
      });
    }

    // await Geolocator.requestPermission();

    try {
      final latest = await _notificationApi.fetchLatest();
      if (latest != null) {
        _current = NotificationSetting.fromJson(latest);
        await _applySetting(_current!);
      }
    } on DioException catch (e) {
      debugPrint('[NOTI] preload failed: ${e.message}');
    } catch (e) {
      debugPrint('[NOTI] preload failed: $e');
    }
    notifyListeners();
  }

  /* ─────────── 권한 헬퍼 ─────────── */
  Future<bool> _ensure(Permission p) async =>
      (await p.status).isGranted || (await p.request()).isGranted;

  int _notificationBaseId(NotificationSetting s) {
    final key = s.id ?? '${s.savedAt.millisecondsSinceEpoch}-${s.hashCode}';
    return key.hashCode & 0x7fffffff;
  }

  void _recordScheduledId(NotificationSetting s, int id) {
    final docId = s.id;
    if (docId == null) return;
    final bucket = _scheduledNotificationIds.putIfAbsent(docId, () => <int>[]);
    if (!bucket.contains(id)) bucket.add(id);
  }

  Future<void> _cancelRecordedIds(String docId) async {
    final ids = _scheduledNotificationIds.remove(docId);
    if (ids == null) return;
    for (final id in ids) {
      await _fln.cancel(id);
    }
  }

  void _clearAllRecordedIds() {
    _scheduledNotificationIds.clear();
  }

  Future<List<NotificationSetting>> fetchSettings({
    String? abcId,
    bool locationOnly = false,
  }) async {
    await _ready;
    try {
      final docs = await _notificationApi.list(
        abcId: abcId,
        locationOnly: locationOnly,
      );
      return docs.map(NotificationSetting.fromJson).toList();
    } on DioException catch (e) {
      debugPrint('[NOTI] fetchSettings failed: ${e.message}');
      return const [];
    } catch (e) {
      debugPrint('[NOTI] fetchSettings failed: $e');
      return const [];
    }
  }

  Future<NotificationSetting> _persistRemoteSetting(NotificationSetting setting) async {
    final abcId = setting.abcId;
    if (abcId == null || abcId.isEmpty) {
      throw StateError('abcId is required to persist notification settings');
    }
    final saved = await _notificationApi.upsert(
      abcId: abcId,
      body: setting.toJson(includeSavedAt: false),
      id: setting.id,
    );
    return NotificationSetting.fromJson(saved);
  }

  /* ─────────── 새 알림 생성 ─────────── */
  Future<NotificationSetting?> createAndSchedule(NotificationSetting setting, {required String abcId}) async {
    await _ready;
    if (!await _ensure(Permission.notification)) return null;

    final NotificationSetting s = setting.copyWith(abcId: abcId);

    try {
      final saved = await _persistRemoteSetting(s);
      _current = saved;
      await _reSchedule(_current!);
      notifyListeners();
      return saved;
    } on DioException catch (e) {
      debugPrint('[NOTI] createAndSchedule failed: ${e.message}');
    } catch (e) {
      debugPrint('[NOTI] createAndSchedule failed: $e');
    }
    return null;
  }

  /// 외부(UI)에서 새 알림을 저장 + 스케줄링할 때 사용
  Future<NotificationSetting?> createSchedule(NotificationSetting setting, {required String abcId}) =>
      createAndSchedule(setting, abcId: abcId);
// ───────────────────────── 기존 알림 업데이트 + 재스케줄 ─────────────────────────
  Future<NotificationSetting?> updateAndSchedule(NotificationSetting setting, {required String abcId}) async {
    await _ready;                               // 초기화 보장

    // 1) 문서 ID가 없으면 새로 추가
    if (setting.id == null) {
      return await createAndSchedule(setting, abcId: abcId);
    }

    try {
      final saved = await _persistRemoteSetting(setting.copyWith(abcId: abcId));
      _current = saved;
      await _reSchedule(_current!);
      notifyListeners();
      return saved;
    } on DioException catch (e) {
      debugPrint('[NOTI] updateAndSchedule failed: ${e.message}');
    } catch (e) {
      debugPrint('[NOTI] updateAndSchedule failed: $e');
    }
    return null;
  }

  /// 외부(UI)에서 기존 알림을 갱신 + 재스케줄 할 때 사용
  Future<NotificationSetting?> updateSchedule(NotificationSetting setting, {required String abcId}) =>
      updateAndSchedule(setting, abcId: abcId);

  /// ★ 시간만 수정
  Future<void> updateTimeOfDay(String abcId, String docId, TimeOfDay t) async {
    await _ready;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final payload = <String, dynamic>{
      'time': '$hh:$mm',
    };
    final currentForKey = (_current != null && _current!.id == docId) ? _current : null;
    if (currentForKey != null) {
      final updated = currentForKey.copyWith(time: t);
      final timeKey = _timeKeyOf(updated);
      if (timeKey != null) {
        payload['time_key'] = timeKey;
      }
      payload['repeat_option'] = updated.repeatOption.name;
      if (updated.repeatOption == RepeatOption.weekly && updated.weekdays.isNotEmpty) {
        payload['weekdays'] = (updated.weekdays.toSet().toList()..sort());
      }
    }
    try {
      await _notificationApi.updateTime(
        abcId: abcId,
        settingId: docId,
        body: payload,
      );
      if (_current != null && _current!.id == docId) {
        _current = _current!.copyWith(time: t);
        await _reSchedule(_current!);
      }
      notifyListeners();
    } on DioException catch (e) {
      debugPrint('[NOTI] updateTimeOfDay failed: ${e.message}');
    } catch (e) {
      debugPrint('[NOTI] updateTimeOfDay failed: $e');
    }
  }

  /// ★ 위치 알림 설명만 수정
  Future<void> updateLocationDescription(String abcId, String docId, String desc) async {
    await _ready;
    try {
      await _notificationApi.updateDescription(
        abcId: abcId,
        settingId: docId,
        description: desc,
      );
      if (_current != null && _current!.id == docId) {
        _current = _current!.copyWith(description: desc);
        notifyListeners();
      }
    } on DioException catch (e) {
      debugPrint('[NOTI] updateLocationDescription failed: ${e.message}');
    } catch (e) {
      debugPrint('[NOTI] updateLocationDescription failed: $e');
    }
  }

  // ───────────────────────── 스케줄 적용/갱신 ─────────────────────────
  Future<void> _reSchedule(NotificationSetting s) async {
    await _cancelAll();
    await _applySetting(s);
  }

  /// Applies a [NotificationSetting] by scheduling the appropriate notification(s)
  /// based on time, location, or both.
  Future<void> _applySetting(NotificationSetting s) async {
    final hasTime   = s.time != null;
    final hasCoords = s.latitude != null && s.longitude != null;
    final hasAddr   = (s.location?.isNotEmpty ?? false);

    // ── 분기 ──
    if (hasTime && hasCoords) {
      // 위치 + 시간 → 지정 시각에 위치 검사
      await _scheduleTimeAndLocation(s);
      return;
    }

    // 시간만
    if (hasTime) {
      await _scheduleTimeOnly(s);
      return;
    }

    // 위치만
    if (hasCoords || hasAddr) {
      await _scheduleLocationOnly(s);
    }
  }

  // ─────────────────────────  Title / Body Helpers  ─────────────────────────
  String _titleFor(NotificationSetting? s) {
    // 모든 (리마인더 제외) 알림의 제목은 고정
    return '걱정 일기 알림';
  }

  String _bodyFor(NotificationSetting? s) {
    if (s?.cause != null && s!.cause!.trim().isNotEmpty) {
      // 원인(걱정 내용)이 있으면 그 내용을 강조
      return '"${s.cause}"에 대한 알림이에요!';
    }
    // 원인이 없으면 기본 문구
    return '불안에 대해 집중해 보세요!';
  }

  tz.TZDateTime _nextDailyOccurrence(TimeOfDay tod, {tz.TZDateTime? from}) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      tod.hour,
      tod.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextWeeklyOccurrence(int weekday, TimeOfDay tod,
      {tz.TZDateTime? from}) {
    final now = from ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      tod.hour,
      tod.minute,
    );
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _scheduleNotificationInstance({
    required NotificationSetting setting,
    required int id,
    required tz.TZDateTime dateTime,
    DateTimeComponents? matchComponents,
    bool isReminder = false,
  }) async {
    final exact = await _ensure(Permission.scheduleExactAlarm);
    final title = isReminder ? '다시 알림: ${_titleFor(setting)}' : _titleFor(setting);
    final body = isReminder ? '조금 전 알림을 다시 알려드려요.' : _bodyFor(setting);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel',
        'Daily Notification',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final payload = '/before_sud?abcId=${setting.abcId ?? ''}';

    Future<void> schedule(AndroidScheduleMode mode) => _fln.zonedSchedule(
          id,
          title,
          body,
          dateTime,
          details,
          payload: payload,
          androidScheduleMode: mode,
          matchDateTimeComponents: matchComponents,
        );

    try {
      await schedule(exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      } else {
        rethrow;
      }
    }
    _recordScheduledId(setting, id);
  }

  Future<void> _scheduleTimeOnly(NotificationSetting setting) async {
    final repeat = _effectiveRepeatOption(setting);
    final tod = setting.time!;
    final base = _notificationBaseId(setting);
    final reminderMinutes = setting.reminderMinutes ?? 0;
    int offset = 0;

    Future<void> scheduleOccurrence(tz.TZDateTime first,
        DateTimeComponents? match) async {
      final id = base + offset;
      offset += 1;
      await _scheduleNotificationInstance(
        setting: setting,
        id: id,
        dateTime: first,
        matchComponents: match,
      );

      if (reminderMinutes > 0) {
        final reminderDate = first.add(Duration(minutes: reminderMinutes));
        final reminderId = base + offset;
        offset += 1;
        await _scheduleNotificationInstance(
          setting: setting,
          id: reminderId,
          dateTime: reminderDate,
          matchComponents: match,
          isReminder: true,
        );
      }
    }

    if (repeat == RepeatOption.weekly && setting.weekdays.isNotEmpty) {
      final uniqueWeekdays = setting.weekdays.toSet().toList()..sort();
      for (final weekday in uniqueWeekdays) {
        final first = _nextWeeklyOccurrence(weekday, tod);
        await scheduleOccurrence(first, DateTimeComponents.dayOfWeekAndTime);
      }
    } else {
      final first = _nextDailyOccurrence(tod);
      final match = repeat == RepeatOption.none
          ? null
          : DateTimeComponents.time;
      await scheduleOccurrence(first, match);
    }
  }

  Future<void> _scheduleLocationOnly(NotificationSetting setting) async {
    if (!(setting.notifyEnter || setting.notifyExit)) {
      return;
    }
    if (setting.latitude != null && setting.longitude != null) {
      await _ensureGeofenceForDoc(
        setting: setting,
        lat: setting.latitude!,
        lng: setting.longitude!,
        address: setting.description ?? setting.location ?? '',
      );
    } else if ((setting.location?.isNotEmpty ?? false)) {
      await _startGeofenceFromAddress(setting.location!, setting: setting);
    }
  }

  Future<void> _scheduleTimeAndLocation(NotificationSetting setting) async {
    if (!await _ensure(Permission.locationWhenInUse)) return;
    final repeat = _effectiveRepeatOption(setting);
    final tod = setting.time!;
    final tzNow = tz.TZDateTime.now(tz.local);

    final List<_LocationSchedule> schedules;
    if (repeat == RepeatOption.weekly && setting.weekdays.isNotEmpty) {
      final unique = setting.weekdays.toSet().toList()..sort();
      schedules = unique
          .map((weekday) => _LocationSchedule(
                _nextWeeklyOccurrence(weekday, tod, from: tzNow),
                weekday,
              ))
          .toList();
    } else {
      schedules = [
        _LocationSchedule(
          _nextDailyOccurrence(tod, from: tzNow),
          null,
        ),
      ];
    }

    for (final schedule in schedules) {
      _queueLocationTimer(setting, schedule, repeat);
    }
  }

  void _queueLocationTimer(NotificationSetting setting, _LocationSchedule schedule,
      RepeatOption repeat) {
    final runAt = schedule.dateTime;
    final wait = runAt.toLocal().difference(DateTime.now());
    final duration = wait.isNegative ? Duration.zero : wait;
    final docId = setting.id;
    final timer = Timer(duration, () async {
      await _performLocationCheck(setting);

      if (repeat == RepeatOption.none) {
        return;
      }
      final nextFrom = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 1));
      final tz.TZDateTime nextRun = schedule.weekday != null
          ? _nextWeeklyOccurrence(schedule.weekday!, setting.time!, from: nextFrom)
          : _nextDailyOccurrence(setting.time!, from: nextFrom);

      _queueLocationTimer(
        setting,
        _LocationSchedule(nextRun, schedule.weekday),
        repeat,
      );
    });

    if (docId != null) {
      final bucket = _locationTimersByDocId.putIfAbsent(docId, () => <Timer>[]);
      bucket.add(timer);
    } else {
      // fallback (id가 없을 일은 거의 없음)
      final bucket = _locationTimersByDocId.putIfAbsent('_', () => <Timer>[]);
      bucket.add(timer);
    }
  }

  Future<void> _performLocationCheck(NotificationSetting setting) async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final targetLat = setting.latitude!;
      final targetLng = setting.longitude!;
      final dist = _haversineDistance(pos.latitude, pos.longitude, targetLat, targetLng);
      if (dist <= 100) {
        await _showNow(
          title: _titleFor(setting),
          body: _bodyFor(setting),
          reminderMinutes: setting.reminderMinutes,
          abcId: setting.abcId,
        );
      }
    } catch (_) {
      // ignore location errors
    }
  }

  Future<void> _stopGeofenceMonitoring() async {
    await _geofence.stop();
    _geofence.clearAllListeners();
    _geofence.clearGeofenceList();
  }

  Future<void> _restartGeofenceService() async {
    // geofence 리스트가 비면 서비스 중지
    if (_geoRegionByDocId.isEmpty) {
      await _stopGeofenceMonitoring();
      return;
    }
    if (!await _ensure(Permission.activityRecognition)) return;
    if (!await _ensure(Permission.locationWhenInUse)) return;

    // 서비스 리셋
    await _geofence.stop();
    _geofence.clearAllListeners();
    _geofence.clearGeofenceList();

    // 상태 변화 리스너 (단일 글로벌 리스너에서 문서별 분기)
    _geofence.addGeofenceStatusChangeListener((g, r, status, loc) async {
      final docId = _docIdFromRegionId(g.id);
      final s = _geoSettingByDocId[docId];
      if (s == null) return;

      if ((status == gf.GeofenceStatus.ENTER || status == gf.GeofenceStatus.DWELL) && s.notifyEnter) {
        await _showNow(
          title: _titleFor(s),
          body: _bodyFor(s),
          reminderMinutes: s.reminderMinutes,
          abcId: s.abcId,
        );
      }
      if (status == gf.GeofenceStatus.EXIT && s.notifyExit) {
        await _showNow(
          title: _titleFor(s),
          body: _bodyFor(s),
          reminderMinutes: s.reminderMinutes,
          abcId: s.abcId,
        );
      }
    });

    // 현재 등록된 모든 지오펜스로 시작
    await _geofence.start(_geoRegionByDocId.values.toList());
  }

  Future<void> _ensureGeofenceForDoc({
    required NotificationSetting setting,
    required double lat,
    required double lng,
    required String address,
  }) async {
    if (setting.id == null) return; // 안전장치
    final docId = setting.id!;
    final region = gf.Geofence(
      id: _regionIdForDoc(docId),
      latitude: lat,
      longitude: lng,
      radius: [gf.GeofenceRadius(id: '100m', length: 100)],
    );
    // 상태 저장 (설정 값도 보관해 콜백에서 사용)
    _geoRegionByDocId[docId] = region;
    _geoSettingByDocId[docId] = setting.copyWith(
      latitude: lat,
      longitude: lng,
      description: setting.description ?? address,
      location: setting.location ?? address,
    );
    // 서비스 재기동
    await _restartGeofenceService();
  }

  void _clearLocationTimers() {
    for (final entry in _locationTimersByDocId.entries) {
      for (final t in entry.value) {
        t.cancel();
      }
    }
    _locationTimersByDocId.clear();
  }

  void _clearLocationTimersForDoc(String docId) {
    final list = _locationTimersByDocId.remove(docId);
    if (list == null) return;
    for (final t in list) {
      t.cancel();
    }
  }

  /// Returns the great‑circle distance between two lat/lng pairs **in metres**
  /// using the Haversine formula.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6_371_000; // metres
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  /// Degrees → Radians
  double _degToRad(double deg) => deg * math.pi / 180;


  // ───────────────────────── 지오펜스 ─────────────────────────
  Future<void> _startGeofenceFromAddress(String addr, {NotificationSetting? setting}) async {
    try {
      final key = vworldApiKey;
      final uri = Uri.parse(
        'http://api.vworld.kr/req/address'
        '?service=address&request=getcoord'
        '&address=${Uri.encodeComponent(addr)}'
        '&type=road&inputCoordSystem=WGS84GEO&output=json&key=$key',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return;

      final j = json.decode(res.body) as Map<String, dynamic>;
      final p = j['response']?['result']?['point'] as Map<String, dynamic>?;
      final lat = double.tryParse(p?['y']?.toString() ?? '');
      final lng = double.tryParse(p?['x']?.toString() ?? '');
      if (lat == null || lng == null) return;

      if (setting != null) {
        await _ensureGeofenceForDoc(
          setting: setting,
          lat: lat,
          lng: lng,
          address: addr,
        );
      }
    } catch (_) {}
    return;
  }

  // ───────────────────────── 즉시 푸시 ─────────────────────────
  Future<void> _showNow({
    required String title, 
    required String body, 
    int? reminderMinutes,
    String? abcId,
  }) async {
    final route = '/before_sud?abcId=${abcId ?? _current?.abcId ?? ''}';
    debugPrint('[NOTI] payload=$route'); 
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch % 1000000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'Instant Push',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: route
    );

    if (reminderMinutes != null && reminderMinutes > 0) {
      final when = DateTime.now().add(Duration(minutes: reminderMinutes));
      await _fln.zonedSchedule(
        DateTime.now().millisecondsSinceEpoch % 1000000 + 1,
        '다시 알림: $title',
        body,
        tz.TZDateTime.from(when, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_channel',
            'Instant Push',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: route,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  // ───────────────────────── 취소 ─────────────────────────
  Future<void> _cancelAll() async {
    await _fln.cancelAll();
    await _stopGeofenceMonitoring();
    _clearLocationTimers();
    _clearAllRecordedIds();
    _geoRegionByDocId.clear();
    _geoSettingByDocId.clear();
  }
  /* ─────────── 단일 스케줄 취소 ─────────── */
  /// 특정 알림 문서(id) 하나만 취소합니다.
  /// 🔹 [id]      : Firestore notification_settings 문서 ID  
  /// 🔹 [abcId]   : 상위 ABC 모델 ID (사용하지 않더라도 시그니처 유지)
  Future<void> cancelSchedule({
    required String id,
    required String abcId,
  }) async {
    await _ready;
    try {
      await _notificationApi.deleteSetting(abcId: abcId, settingId: id);
    } catch (e) {
      debugPrint('[NOTI] cancelSchedule remote delete failed: $e');
    }
    await _cancelRecordedIds(id);
    _geoRegionByDocId.remove(id);
    _geoSettingByDocId.remove(id);
    await _restartGeofenceService();
    _clearLocationTimersForDoc(id);
    if (_current?.id == id && _current?.abcId == abcId) {
      _current = null;
      notifyListeners();
    }
  }
  // ───────────────────────── 모든 스케줄 취소 ─────────────────────────
  /// ABC 상세 화면에서 “알림을 설정하지 않을래요” 체크 시 호출
  Future<void> cancelAllSchedules({required String abcId}) async {
    await _ready;          // 초기화 보장
    try {
      final docs = await _notificationApi.list(abcId: abcId);
      for (final doc in docs) {
        final id = doc['id']?.toString() ?? doc['_id']?.toString();
        if (id == null) continue;
        try {
          await _notificationApi.deleteSetting(abcId: abcId, settingId: id);
        } catch (e) {
          debugPrint('[NOTI] cancelAllSchedules delete failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[NOTI] cancelAllSchedules list failed: $e');
    }
    await _cancelAll();
    _current = null;
    notifyListeners();
  }
}

// 확장: 어디서든 사용할 수 있는 copyWith
class _LocationSchedule {
  final tz.TZDateTime dateTime;
  final int? weekday;
  const _LocationSchedule(this.dateTime, this.weekday);
}

extension NotificationSettingCopyExt on NotificationSetting {
  NotificationSetting copyWith({
    String? id,
    String? abcId,
    TimeOfDay? time,
    // DateTime? startDate,
    RepeatOption? repeatOption,
    List<int>? weekdays,
    double? latitude,
    double? longitude,
    String? location,
    int? reminderMinutes,
    String? description,
    String? cause,
    DateTime? savedAt,
    bool? notifyEnter,
    bool? notifyExit,
  }) {
    return NotificationSetting(
      id: id ?? this.id,
      abcId: abcId ?? this.abcId,
      time: time ?? this.time,
      // startDate: startDate ?? this.startDate,
      repeatOption: repeatOption ?? this.repeatOption,
      weekdays: weekdays ?? this.weekdays,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      description: description ?? this.description,
      cause: cause ?? this.cause,
      savedAt: savedAt ?? this.savedAt,
      notifyEnter: notifyEnter ?? this.notifyEnter,
      notifyExit:  notifyExit  ?? this.notifyExit,
    );
  }
}
