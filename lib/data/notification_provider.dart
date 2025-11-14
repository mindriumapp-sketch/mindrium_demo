// ─────────────────────────  Dart Std  ─────────────────────────
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

// ─────────────────────────  Flutter  ──────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;

// ─────────────────────  3rd‑party Packages  ───────────────────
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:geolocator/geolocator.dart';
import 'package:geofence_service/geofence_service.dart' as gf;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────  Local  ────────────────────────────
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/app.dart';

/// ───────────────────────── MODELS ─────────────────────────
enum RepeatOption { none, daily, weekly }

class NotificationSetting {
  // final DateTime startDate;
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
    // DateTime? startDate,
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
  })  : //startDate = startDate ?? DateTime.now(),
        savedAt = savedAt ?? DateTime.now();

  Map<String, dynamic> toJson({bool includeSavedAt = true}) {
    final map = <String, dynamic>{
      // 'startDate': Timestamp.fromDate(startDate),
      'reminderMinutes': reminderMinutes,
    };
    if (includeSavedAt) {
      map['savedAt'] = Timestamp.fromDate(savedAt);
    }

    if (abcId != null) map['abcId'] = abcId;
    debugPrint('[NOTI] abcId=$abcId');

    // ── 시간(시각) 정보 ──
    if (time != null) {
      final hh = time!.hour.toString().padLeft(2, '0');
      final mm = time!.minute.toString().padLeft(2, '0');
      final repForKey = (repeatOption == RepeatOption.none)
          ? RepeatOption.daily
          : repeatOption;
      final normalizedWeekdays = (repForKey == RepeatOption.weekly && weekdays.isNotEmpty)
          ? (weekdays.toSet().toList()..sort())
          : <int>[];
      final wdCsv = normalizedWeekdays.join(',');

      map['time'] = '$hh:$mm';
      map['repeatOption'] = repeatOption.name;
      if (repForKey == RepeatOption.weekly && normalizedWeekdays.isNotEmpty) {
        map['weekdays'] = normalizedWeekdays;
      }
      // 👇 시간 전용 중복 방지를 위한 키(시간/반복/요일 조합)
      map['timeKey'] = 't=$hh:$mm|rep=${repForKey.name}|wd=$wdCsv';
    }

    // ── 위치(좌표) 정보 ──
    if (latitude != null && longitude != null) {
      map
        ..['latitude'] = latitude
        ..['longitude'] = longitude
        ..['location'] = location;
      if (description != null) {
        map['description'] = description;
      }
    }
    if (cause != null) {
      map['cause'] = cause;
    }
    // Location timing flags
    map['notifyEnter'] = notifyEnter;
    map['notifyExit']  = notifyExit;
    return map;
  }

  

  /// Same as [toJson] but kept for backward‑compat. UI 코드에서 사용됩니다.
  Map<String, dynamic> toMap({bool includeSavedAt = true}) =>
      toJson(includeSavedAt: includeSavedAt);

  factory NotificationSetting.fromJson(Map<String, dynamic> json,
      {String? id,}) {
    TimeOfDay? tod;
    // DateTime sd = DateTime.now();
    RepeatOption ro = RepeatOption.none;
    List<int> wd = [];
    final int? rm = json['reminderMinutes'] as int?;
    // 시간 관련 필드 (method 관계없이 존재하면 파싱)
    if (json['time'] != null) {
      final p = (json['time'] as String).split(':');
      tod = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
    }
    // if (json['startDate'] != null) {
    //   sd = (json['startDate'] as Timestamp).toDate();
    // }
    if (json['repeatOption'] != null) {
      ro = RepeatOption.values
          .firstWhere((e) => e.name == json['repeatOption']);
    }
    if (ro == RepeatOption.weekly && json['weekdays'] is List) {
      wd = List<int>.from(json['weekdays']);
    }
    return NotificationSetting(
      time: tod,
      // startDate: sd,
      repeatOption: ro,
      weekdays: wd,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      location: json['location'] as String?,
      cause: json['cause'] as String?,
      description: json['description'] as String?,
      id: id,
      abcId: json['abcId'] as String?,
      reminderMinutes: rm,
      savedAt: (json['savedAt'] as Timestamp?)?.toDate(),
      notifyEnter: json['notifyEnter'] as bool? ?? false,
      notifyExit: json['notifyExit'] as bool? ?? false,
    );
  }

  /// Firestore 문서 -> NotificationSetting (id 포함)
factory NotificationSetting.fromDoc(DocumentSnapshot doc) {
  final parent = doc.reference.parent.parent;         
  final setting = NotificationSetting.fromJson(
    doc.data() as Map<String, dynamic>,
    id: doc.id,
  );
  return setting.copyWith(abcId: parent?.id);
}
}

/// ───────────────────────── PROVIDER ─────────────────────────
class NotificationProvider extends ChangeNotifier {
  static final NotificationProvider _inst = NotificationProvider._internal();
  factory NotificationProvider() => _inst;
  NotificationProvider._internal() {
    _ready = _init();
  }

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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final snap = await FirebaseFirestore.instance
            .collectionGroup('notification_settings')
            .get();

        DocumentSnapshot<Map<String, dynamic>>? latest;
        for (final d in snap.docs) {
          if (d.reference.path.contains('/users/$uid/')) {
            latest = d;
            break;
          }
        }

        if (latest != null) {
          _current = NotificationSetting.fromDoc(latest);
          await _applySetting(_current!);
        }
      } catch (e) {
        debugPrint('[NOTI] preload failed: $e');
      }
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

  // Returns the notification_settings collection for a user's abcId.
  CollectionReference<Map<String, dynamic>> _abcNotiCol(
      String uid, String abcId) =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('abc_models')
          .doc(abcId)
          .collection('notification_settings');

  /* ─────────── 새 알림 생성 ─────────── */
  Future<void> createAndSchedule(NotificationSetting setting, {required String abcId}) async {
    await _ready;
    if (!await _ensure(Permission.notification)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[NOTI] createAndSchedule skipped: no user');
      return;
    }
    final uid = user.uid;
    final NotificationSetting s = setting.copyWith(abcId: abcId);

    // (1) 이미 Firestore 문서가 있는지 먼저 확인 -----------------------------
    String? docId = setting.id;

    if (docId == null) {
      // 분기: 시간 전용 vs. 좌표/지오펜스
      final hasTime   = setting.time != null;
      final hasCoords = setting.latitude != null && setting.longitude != null;
      final hasAddr   = (setting.location?.isNotEmpty ?? false);

      if (hasTime && !hasCoords && !hasAddr) {
        // ── 시간 전용: timeKey로 중복 방지 ──
        final key = _timeKeyOf(s);
        if (key != null) {
          final dup = await _abcNotiCol(uid, abcId)
              .where('timeKey', isEqualTo: key)
              .limit(1)
              .get();

          if (dup.docs.isNotEmpty) {
            docId = dup.docs.first.id;
            await _abcNotiCol(uid, abcId)
                .doc(docId)
                .set(setting.toJson(includeSavedAt: false), SetOptions(merge: true));
          } else {
            final ref = await _abcNotiCol(uid, abcId).add(setting.toJson());
            docId = ref.id;
          }
        }
      } else if (hasCoords) {
        // ── 위치 기반: 좌표+플래그로 중복 방지 ──
        final dup = await _abcNotiCol(uid, abcId)
            .where('latitude',    isEqualTo: setting.latitude)
            .where('longitude',   isEqualTo: setting.longitude)
            .where('notifyEnter', isEqualTo: setting.notifyEnter)
            .where('notifyExit',  isEqualTo: setting.notifyExit)
            .limit(1)
            .get();

        if (dup.docs.isNotEmpty) {
          docId = dup.docs.first.id;
          await _abcNotiCol(uid, abcId)
              .doc(docId)
              .set(setting.toJson(includeSavedAt: false), SetOptions(merge: true));
        } else {
          final ref = await _abcNotiCol(uid, abcId).add(setting.toJson());
          docId = ref.id;
        }
      } else {
        // 주소만 있는 경우 등 → 키가 없으므로 새 문서
        final ref = await _abcNotiCol(uid, abcId).add(setting.toJson());
        docId = ref.id;
      }
    } else {
      // id 가 주어졌으면 그대로 업데이트
      await _abcNotiCol(uid, abcId)
          .doc(docId)
          .set(setting.toJson(includeSavedAt: false), SetOptions(merge: true));
    }

    // (2) 로컬 상태 & 알림 스케줄 ------------------------------------------
    _current = s.copyWith(id: docId);
    await _reSchedule(_current!);
    notifyListeners();
  }

  /// 외부(UI)에서 새 알림을 저장 + 스케줄링할 때 사용
  Future<void> createSchedule(NotificationSetting setting, {required String abcId}) =>
      createAndSchedule(setting, abcId: abcId);
// ───────────────────────── 기존 알림 업데이트 + 재스케줄 ─────────────────────────
  Future<void> updateAndSchedule(NotificationSetting setting, {required String abcId}) async {
    await _ready;                               // 초기화 보장

    // 1) 문서 ID가 없으면 새로 추가
    if (setting.id == null) {
      await createAndSchedule(setting, abcId: abcId);
      return;
    }

    // Firestore 문서는 createAndSchedule 에서 처리됨.

    // 3) 로컬 상태 갱신 + 스케줄 다시 등록
    _current = setting;
    await _reSchedule(_current!);
    notifyListeners();
  }

  /// 외부(UI)에서 기존 알림을 갱신 + 재스케줄 할 때 사용
  Future<void> updateSchedule(NotificationSetting setting, {required String abcId}) =>
      updateAndSchedule(setting, abcId: abcId);

  /// ★ 시간만 수정
  Future<void> updateTimeOfDay(String abcId, String docId, TimeOfDay t) async {
    await _ready;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[NOTI] updateTimeOfDay skipped: no user');
      return;
    }
    final uid = user.uid;
    final docRef = _abcNotiCol(uid, abcId).doc(docId);
    final snap = await docRef.get();
    RepeatOption rep = RepeatOption.none;
    List<int> wd = [];
    final data = snap.data();
    if (data != null) {
      final roName = data['repeatOption'] as String?;
      if (roName != null) {
        try {
          rep = RepeatOption.values.firstWhere((e) => e.name == roName);
        } catch (_) {}
      }
      if (rep == RepeatOption.weekly && data['weekdays'] is List) {
        wd = List<int>.from(data['weekdays']);
      }
    }
    final repForKey = (rep == RepeatOption.none) ? RepeatOption.daily : rep;
    final normalizedWd = (repForKey == RepeatOption.weekly && wd.isNotEmpty)
        ? (wd.toSet().toList()..sort())
        : <int>[];
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final wdCsv = normalizedWd.join(',');
    await docRef.update({
      'time': '$hh:$mm',
      'timeKey': 't=$hh:$mm|rep=${repForKey.name}|wd=$wdCsv',
    });

    _current = _current?.copyWith(time: t);
    await _reSchedule(_current!);
    notifyListeners();
  }

  /// ★ 위치 알림 설명만 수정
  Future<void> updateLocationDescription(String abcId, String docId, String desc) async {
    await _ready;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[NOTI] updateLocationDescription skipped: no user');
      return;
    }
    final uid = user.uid;
    await _abcNotiCol(uid, abcId)
        .doc(docId)
        .update({'description': desc});

    _current = _current?.copyWith(description: desc);
    notifyListeners();
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
    await _cancelRecordedIds(id);
    // 지오펜스/타이머를 문서 단위로 정리
    _geoRegionByDocId.remove(id);
    _geoSettingByDocId.remove(id);
    await _restartGeofenceService();
    _clearLocationTimersForDoc(id);

    // 현재 캐시에 같은 알림이 있으면 초기화
    if (_current?.id == id && _current?.abcId == abcId) {
      _current = null;
      notifyListeners();
    }
  }
  // ───────────────────────── 모든 스케줄 취소 ─────────────────────────
  /// ABC 상세 화면에서 “알림을 설정하지 않을래요” 체크 시 호출
  Future<void> cancelAllSchedules({required String abcId}) async {
    await _ready;          // 초기화 보장

    // 1) 등록된 모든 로컬 알림 & 지오펜스 취소
    await _cancelAll();

    // 2) 내부 캐시 초기화
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
