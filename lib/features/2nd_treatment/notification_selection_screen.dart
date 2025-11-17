import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/map_picker.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_group_add.dart'
    show AbcGroupAddScreen;

// ✅ UI 위젯 (업로드한 파일 경로에 맞게 import 경로 조정)
import 'package:gad_app_team/widgets/notification_selection_ui.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/notification_provider.dart'
    show NotificationSetting, RepeatOption, NotificationSettingCopyExt;

class NotificationSelectionScreen extends StatefulWidget {
  final bool fromDirectory;
  final String? label;
  final String? abcId;
  final String? notificationId;
  final String? origin;

  const NotificationSelectionScreen({
    super.key,
    this.fromDirectory = false,
    this.label,
    this.abcId,
    this.notificationId,
    this.origin,
  });

  @override
  State<NotificationSelectionScreen> createState() =>
      _NotificationSelectionScreenState();
}

class _NotificationSelectionScreenState
    extends State<NotificationSelectionScreen> {
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);
  NotificationSetting? _draftTime;
  NotificationSetting? _draftLocation;
  String? _abcId; // 연결된 ABC 문서 ID
  String? _lastDiaryResolveMessage;
  bool _loading = false;

  RepeatOption _repeatOption = RepeatOption.daily;
  final Set<int> _selectedWeekdays = {};
  Duration _reminderDuration = const Duration(hours: 0, minutes: 0);
  bool _noNotification = false;
  bool _isSaving = false; // 저장 중 상태

  NotificationSetting _settingFromAlarm(Map<String, dynamic> alarm) {
    TimeOfDay? tod;
    final timeRaw = alarm['time']?.toString();
    if (timeRaw != null && timeRaw.contains(':')) {
      final parts = timeRaw.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      tod = TimeOfDay(hour: hour, minute: minute);
    }

    RepeatOption repeat = RepeatOption.daily;
    final repeatRaw = alarm['repeat_option']?.toString();
    if (repeatRaw == RepeatOption.weekly.name) {
      repeat = RepeatOption.weekly;
    }

    final weekDays =
        (alarm['weekDays'] as List?)
            ?.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList() ??
        const [];

    final reminderRaw = alarm['reminder_minutes'];
    final reminder =
        reminderRaw is num
            ? reminderRaw.toInt()
            : int.tryParse(reminderRaw?.toString() ?? '');

    return NotificationSetting(
      id: alarm['alarmId']?.toString(),
      abcId: alarm['diaryId']?.toString() ?? _abcId,
      time: tod,
      repeatOption: repeat,
      weekdays: weekDays,
      reminderMinutes: reminder,
      location: alarm['location_desc']?.toString(),
      description: alarm['location_desc']?.toString(),
      notifyEnter: alarm['enter'] == true,
      notifyExit: alarm['exit'] == true,
      cause: widget.label,
    );
  }

  Map<String, dynamic> _alarmPayload(NotificationSetting setting) {
    final weekDays =
        setting.repeatOption == RepeatOption.weekly
            ? (List<int>.from(setting.weekdays)..sort())
            : <int>[];

    final map = <String, dynamic>{
      'time':
          setting.time == null
              ? null
              : '${setting.time!.hour.toString().padLeft(2, '0')}:${setting.time!.minute.toString().padLeft(2, '0')}',
      'location_desc': setting.location ?? setting.description,
      'repeat_option':
          setting.repeatOption == RepeatOption.weekly ? 'weekly' : 'daily',
      'weekDays': weekDays,
      'reminder_minutes': setting.reminderMinutes,
      'enter': setting.notifyEnter,
      'exit': setting.notifyExit,
    };

    map.removeWhere((key, value) => value == null);
    return map;
  }

  Future<String?> _resolveDiaryId() async {
    if (_abcId != null && _abcId!.isNotEmpty) {
      _lastDiaryResolveMessage = null;
      return _abcId;
    }
    if (widget.abcId != null && widget.abcId!.isNotEmpty) {
      _abcId = widget.abcId;
      _lastDiaryResolveMessage = null;
      return _abcId;
    }

    final label = widget.label?.trim();
    if (label == null || label.isEmpty) {
      _lastDiaryResolveMessage = '화면으로 전달된 일기 제목이 없어 일기를 특정할 수 없습니다.';
      return null;
    }

    try {
      final diaries = await _diariesApi.listDiaries();
      if (diaries.isEmpty) {
        _lastDiaryResolveMessage = '저장된 일기가 없습니다. 일기 작성 후 다시 시도해주세요.';
        return null;
      }
      for (final diary in diaries) {
        final title = diary['activating_events']?.toString().trim();
        if (title != null && title == label) {
          final id = diary['diaryId']?.toString();
          if (id != null && id.isNotEmpty) {
            _abcId = id;
            _lastDiaryResolveMessage = null;
            return _abcId;
          }
        }
      }
      _lastDiaryResolveMessage =
          '"$label" 제목으로 저장된 일기를 찾지 못했습니다. 일기 제목을 확인하거나 일기 저장 후 다시 시도해주세요.';
    } on DioException catch (e) {
      final message =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      _lastDiaryResolveMessage = '일기 목록을 불러오지 못했습니다: ${message ?? '알 수 없는 오류'}';
      debugPrint(_lastDiaryResolveMessage);
    } catch (e) {
      _lastDiaryResolveMessage = '일기 목록을 조회하는 중 오류가 발생했습니다: $e';
      debugPrint(_lastDiaryResolveMessage);
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _abcId = widget.abcId;
    _loadExisting();
  }

  /// 기존 알림 설정을 불러와 초깃값으로 반영
  Future<void> _loadExisting() async {
    final diaryId = await _resolveDiaryId();

    if (diaryId == null || diaryId.isEmpty) {
      if (mounted) {
        setState(() {
          _noNotification = false;
          _loading = false;
        });
        final reason = _lastDiaryResolveMessage;
        if (reason != null && reason.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(reason)));
        }
      }
      return;
    }

    setState(() {
      _abcId = diaryId;
      _loading = true;
    });

    try {
      var alarms = await _diariesApi.listAlarms(diaryId);
      if (widget.notificationId != null && widget.notificationId!.isNotEmpty) {
        final filtered = alarms.where(
          (alarm) => alarm['alarmId']?.toString() == widget.notificationId,
        );
        if (filtered.isNotEmpty) {
          alarms = filtered.toList();
        }
      }

      NotificationSetting? timeSetting;
      NotificationSetting? locationSetting;
      final weekSet = <int>{};
      Duration? reminder;

      for (final alarm in alarms) {
        final setting = _settingFromAlarm(alarm);
        final hasLocation =
            setting.notifyEnter ||
            setting.notifyExit ||
            (setting.location?.isNotEmpty ?? false);
        final hasTime = setting.time != null;

        if (hasLocation) {
          locationSetting = setting;
          weekSet.addAll(setting.weekdays);
        } else if (hasTime && timeSetting == null) {
          timeSetting = setting;
          weekSet.addAll(setting.weekdays);
        }

        if (setting.reminderMinutes != null) {
          reminder = Duration(minutes: setting.reminderMinutes!);
        }
      }

      if (timeSetting == null &&
          locationSetting != null &&
          locationSetting.time != null) {
        final loc = locationSetting;
        timeSetting = loc.copyWith(
          latitude: null,
          longitude: null,
          location: null,
          notifyEnter: false,
          notifyExit: false,
        );
      }

      if (!mounted) return;
      setState(() {
        _draftTime = timeSetting;
        _draftLocation = locationSetting;
        _selectedWeekdays
          ..clear()
          ..addAll(
            weekSet.isNotEmpty
                ? weekSet
                : (timeSetting?.weekdays ??
                    locationSetting?.weekdays ??
                    const []),
          );
        _repeatOption =
            (locationSetting ?? timeSetting)?.repeatOption ??
            RepeatOption.daily;
        _reminderDuration = reminder ?? _reminderDuration;
        _noNotification = false;
      });
    } on DioException catch (e) {
      final message =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('알림 정보를 불러오지 못했습니다: ${message ?? '오류'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('알림 정보를 불러오지 못했습니다: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showReminderSheet() async {
    int selHour = _reminderDuration.inHours;
    int selMin = _reminderDuration.inMinutes % 60;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.grey100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => Padding(
            padding: MediaQuery.of(ctx).viewInsets,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 248,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selHour,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (v) => selHour = v,
                            children: List.generate(
                              24,
                              (i) => Center(child: Text('$i시')),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selMin == 0 ? 0 : selMin,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (v) => selMin = v,
                            children: List.generate(
                              60,
                              (i) => Center(child: Text('$i분')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: NavigationButtons(
                    leftLabel: '닫기',
                    rightLabel: '완료',
                    onBack: () => Navigator.pop(ctx),
                    onNext: () {
                      setState(() {
                        _reminderDuration = Duration(
                          hours: selHour,
                          minutes: selMin,
                        );

                        if (_draftTime != null) {
                          _draftTime = _draftTime!.copyWith(
                            reminderMinutes: _reminderDuration.inMinutes,
                          );
                        }
                        if (_draftLocation != null) {
                          _draftLocation = _draftLocation!.copyWith(
                            reminderMinutes: _reminderDuration.inMinutes,
                          );
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
    );
    if (mounted) setState(() {});
    // BlueBanner.show(context, '저장이 완료되었습니다.');
  }

  Future<void> _showRepeatSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.grey100,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder:
              (ctx2, setLocal) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 124,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              title: const Text('반복'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _repeatOption == RepeatOption.daily
                                        ? '매일'
                                        : '매주',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              onTap: () async {
                                final opt = await showDialog<RepeatOption>(
                                  context: ctx,
                                  builder:
                                      (dctx) => SimpleDialog(
                                        title: const Text('반복 설정'),
                                        children: [
                                          SimpleDialogOption(
                                            onPressed:
                                                () => Navigator.pop(
                                                  dctx,
                                                  RepeatOption.daily,
                                                ),
                                            child: const Text('매일'),
                                          ),
                                          SimpleDialogOption(
                                            onPressed:
                                                () => Navigator.pop(
                                                  dctx,
                                                  RepeatOption.weekly,
                                                ),
                                            child: const Text('매주'),
                                          ),
                                        ],
                                      ),
                                );
                                if (opt != null) {
                                  setLocal(() => _repeatOption = opt);
                                }
                              },
                            ),
                          ),
                          if (_repeatOption == RepeatOption.weekly) ...[
                            const SizedBox(height: 4),
                            Center(
                              child: Wrap(
                                spacing: 4,
                                children: List.generate(7, (i) {
                                  final day = i + 1;
                                  final selected = _selectedWeekdays.contains(
                                    day,
                                  );
                                  return FilterChip(
                                    showCheckmark: false,
                                    backgroundColor: Colors.white,
                                    selectedColor: AppColors.indigo,
                                    label: Text(
                                      ['일', '월', '화', '수', '목', '금', '토'][i],
                                      style: TextStyle(
                                        color:
                                            selected
                                                ? Colors.white
                                                : Colors.black,
                                      ),
                                    ),
                                    selected: selected,
                                    onSelected:
                                        (_) => setLocal(() {
                                          selected
                                              ? _selectedWeekdays.remove(day)
                                              : _selectedWeekdays.add(day);
                                        }),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: NavigationButtons(
                        leftLabel: '닫기',
                        rightLabel: '완료',
                        onBack: () => Navigator.pop(ctx),
                        onNext: () => Navigator.pop(ctx),
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _showTimeSheet() async {
    TimeOfDay pickedTime =
        (_draftTime?.time ?? _draftLocation?.time) ??
        const TimeOfDay(hour: 9, minute: 0);

    _repeatOption =
        (_draftTime ?? _draftLocation)?.repeatOption == RepeatOption.weekly
            ? RepeatOption.weekly
            : RepeatOption.daily;
    _selectedWeekdays
      ..clear()
      ..addAll((_draftTime ?? _draftLocation)?.weekdays ?? const []);

    final setting = await showModalBottomSheet<NotificationSetting>(
      context: context,
      backgroundColor: AppColors.grey100,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        TimeOfDay pickedTimeLocal = pickedTime;
        return StatefulBuilder(
          builder:
              (ctx2, setLocal) => Padding(
                padding: MediaQuery.of(ctx).viewInsets,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 248,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        use24hFormat: false,
                        initialDateTime: DateTime(
                          0,
                          0,
                          0,
                          pickedTimeLocal.hour,
                          pickedTimeLocal.minute,
                        ),
                        onDateTimeChanged:
                            (dt) =>
                                pickedTimeLocal = TimeOfDay.fromDateTime(dt),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: NavigationButtons(
                        leftLabel: '닫기',
                        rightLabel: '완료',
                        onBack: () => Navigator.pop(ctx),
                        onNext: () {
                          Navigator.pop(
                            ctx,
                            NotificationSetting(
                              id: _draftTime?.id,
                              abcId: _abcId,
                              time: pickedTimeLocal,
                              cause: widget.label,
                              repeatOption: _repeatOption,
                              weekdays: _selectedWeekdays.toList(),
                              reminderMinutes: _draftTime?.reminderMinutes,
                              notifyEnter: false,
                              notifyExit: false,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
        );
      },
    );

    if (setting != null && mounted) {
      setState(() => _draftTime = setting);
    }
  }

  Future<void> _showLocationSheet() async {
    LatLng? initialLatLng;
    if (_draftLocation?.latitude != null && _draftLocation?.longitude != null) {
      initialLatLng = LatLng(
        _draftLocation!.latitude!,
        _draftLocation!.longitude!,
      );
    }

    final setting = await showModalBottomSheet<NotificationSetting>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SizedBox(
            height: MediaQuery.of(ctx).size.height,
            child: MapPicker(initial: initialLatLng),
          ),
    );

    if (setting != null && mounted) {
      final withRepeat = setting.copyWith(
        repeatOption: _repeatOption,
        weekdays: _selectedWeekdays.toList(),
      );

      final withId = withRepeat.copyWith(
        id: _draftLocation?.id,
        abcId: _abcId,
        cause: widget.label,
        reminderMinutes: _draftLocation?.reminderMinutes,
      );

      final bool isNewLocation = _draftLocation == null;
      final NotificationSetting withDefault =
          isNewLocation && !(withId.notifyEnter || withId.notifyExit)
              ? withId.copyWith(notifyEnter: true)
              : withId;

      setState(() => _draftLocation = withDefault);
    }
  }

  Future<void> _deleteAllAlarms(String diaryId) async {
    final alarms = await _diariesApi.listAlarms(diaryId);
    for (final alarm in alarms) {
      final alarmId = alarm['alarmId']?.toString();
      if (alarmId != null && alarmId.isNotEmpty) {
        await _diariesApi.deleteAlarm(diaryId, alarmId);
      }
    }
  }

  void _showHelpDialog() {
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              '도움말',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            backgroundColor: Colors.grey.shade100,
            insetPadding: const EdgeInsets.all(20),
            contentPadding: const EdgeInsets.all(AppSizes.padding),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 10, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '알림은 걱정 일기에서 작성한 불안의 원인에 집중해 볼 '
                          '위치와 시간을 원하는 방식으로 설정할 수 있어요.',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• 위치 또는 시간 중 최소 하나를 선택해야 해요.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '• 다시 알림은 선택 사항이에요.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '• 하단의 “알림을 설정하지 않을래요.”를 체크하면 알림을 끌 수 있어요.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 24),
                        Text(
                          '위치',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '설정한 장소에 들어가거나 나올 때 알림이 울려요.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '시간',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '지정한 시간과 반복 주기로 알림이 울려요.',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '위치 + 시간',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '지정한 시간에 설정한 장소에 도착하거나 머물러 있을 때 알림이 울려요.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('닫기'),
              ),
            ],
          ),
    );
  }

  void _syncReminderMinutes() {
    final m = _reminderDuration.inMinutes;
    if (_draftTime != null) {
      _draftTime = _draftTime!.copyWith(reminderMinutes: m);
    }
    if (_draftLocation != null) {
      _draftLocation = _draftLocation!.copyWith(reminderMinutes: m);
    }
  }

  void _syncRepeatIntoDrafts() {
    if (_draftTime != null) {
      _draftTime = _draftTime!.copyWith(
        repeatOption: _repeatOption,
        weekdays: _selectedWeekdays.toList(),
      );
    }
    if (_draftLocation != null) {
      _draftLocation = _draftLocation!.copyWith(
        repeatOption: _repeatOption,
        weekdays: _selectedWeekdays.toList(),
      );
    }
  }

  Future<void> _onSavePressed() async {
    if (_isSaving) return;
    _syncRepeatIntoDrafts();

    debugPrint('🔵 알림 저장 시작: _noNotification=$_noNotification');
    setState(() => _isSaving = true);

    try {
      var diaryId = _abcId;
      diaryId ??= await _resolveDiaryId();
      if (diaryId == null || diaryId.isEmpty) {
        if (!mounted) return;
        final reason = _lastDiaryResolveMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reason ?? '일기 정보를 찾을 수 없습니다. 일기를 먼저 저장한 뒤 다시 시도해주세요.',
            ),
          ),
        );
        return;
      }
      _abcId = diaryId;
      final resolvedDiaryId = diaryId;

      // 1) “알림을 설정하지 않을래요”
      if (_noNotification) {
        debugPrint('🟡 알림 안 받을래요 선택됨');
        if (widget.notificationId != null &&
            widget.notificationId!.isNotEmpty) {
          await _diariesApi.deleteAlarm(
            resolvedDiaryId,
            widget.notificationId!,
          );
        } else {
          await _deleteAllAlarms(resolvedDiaryId);
        }

        if (!mounted) return;
        debugPrint('🟢 그룹 선택 팝업 호출 (알림 없음)');
        _showGroupSelectionPopup(resolvedDiaryId);
        return;
      }

      // 2) reminderMinutes 최신화
      _syncReminderMinutes();

      // 위치 + 시간 → 하나의 문서로 합치기
      String? alarmIdToDelete;
      if (_draftTime != null && _draftLocation != null) {
        _draftLocation = _draftLocation!.copyWith(
          time: _draftTime!.time,
          repeatOption: _draftTime!.repeatOption,
          weekdays: _draftTime!.weekdays,
          reminderMinutes:
              _draftLocation!.reminderMinutes ?? _draftTime!.reminderMinutes,
          notifyEnter: false,
          notifyExit: false,
        );

        if (_draftTime!.id != null && _draftTime!.id != _draftLocation!.id) {
          alarmIdToDelete = _draftTime!.id;
        }

        _draftTime = null;
      }

      Future<void> saveSetting(NotificationSetting setting) async {
        final payload = _alarmPayload(setting);

        Map<String, dynamic> result;
        if (setting.id != null && setting.id!.isNotEmpty) {
          result = await _diariesApi.updateAlarm(
            resolvedDiaryId,
            setting.id!,
            payload,
          );
        } else {
          result = await _diariesApi.createAlarm(resolvedDiaryId, payload);
        }

        final updated = _settingFromAlarm({
          ...result,
          'diaryId': resolvedDiaryId,
        });
        if (identical(setting, _draftTime)) {
          _draftTime = updated;
        }
        if (identical(setting, _draftLocation)) {
          _draftLocation = updated;
        }
      }

      final draftTimeLocal = _draftTime;
      if (draftTimeLocal != null) await saveSetting(draftTimeLocal);
      final draftLocationLocal = _draftLocation;
      if (draftLocationLocal != null) await saveSetting(draftLocationLocal);
      if (alarmIdToDelete != null && alarmIdToDelete.isNotEmpty) {
        await _diariesApi.deleteAlarm(resolvedDiaryId, alarmIdToDelete);
      }

      if (!mounted) return;

      debugPrint('🟢 그룹 선택 팝업 호출 (알림 설정 완료)');
      // 그룹 선택 팝업 표시
      _showGroupSelectionPopup(resolvedDiaryId);
    } on DioException catch (e, st) {
      debugPrint('알림 저장 중 오류: $e\n$st');
      final message =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message ?? '알림을 저장하는 중 오류가 발생했습니다. 다시 시도해주세요.'),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('알림 저장 중 오류: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알림을 저장하는 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      } else {
        _isSaving = false;
      }
    }
  }

  // ====== 그룹 선택 팝업 ======
  void _showGroupSelectionPopup(String diaryId) {
    debugPrint('💜 _showGroupSelectionPopup 호출됨: diaryId=$diaryId');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => CustomPopupDesign(
            title: "걱정그룹에 추가하시겠습니까?",
            message: "작성한 걱정일기를 다른 그룹으로 변경하시겠습니까?",
            positiveText: "예",
            negativeText: "아니요",
            iconAsset: "assets/image/popup1.png",
            backgroundAsset: "assets/image/sea_bg_3d.png",
            onPositivePressed: () {
              Navigator.pop(dialogCtx);
              // abc_group_add.dart로 이동
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AbcGroupAddScreen(
                        origin: widget.origin ?? 'etc',
                        abcId: diaryId,
                        label: widget.label,
                      ),
                ),
              );
            },
            onNegativePressed: () {
              Navigator.pop(dialogCtx);
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/home', (_) => false);
            },
          ),
    );
  }

  // ====== 빌드: 배경/레이아웃은 제공한 형식으로, 본문은 NotificationSelectionUI 사용 ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: '2주차 - ABC 모델'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌊 배경
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.65),
              filterQuality: FilterQuality.high,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : NotificationSelectionUI(
                        label: widget.label,
                        draftTime: _draftTime,
                        draftLocation: _draftLocation,
                        noNotification: _noNotification,
                        repeatOption: _repeatOption,
                        selectedWeekdays: _selectedWeekdays,
                        reminderDuration: _reminderDuration,
                        onTapTime: _showTimeSheet,
                        onTapLocation: _showLocationSheet,
                        onTapRepeat: _showRepeatSheet,
                        onTapReminder: _showReminderSheet,
                        onToggleNone: (v) {
                          setState(() {
                            _noNotification = v;
                            if (_noNotification) {
                              _draftTime = null;
                              _draftLocation = null;
                            }
                          });
                        },
                        onSave: _isSaving ? () {} : _onSavePressed,
                        onHelp: _showHelpDialog,
                        onToggleEnter:
                            (v) => setState(() {
                              if (_draftLocation != null) {
                                _draftLocation = _draftLocation!.copyWith(
                                  notifyEnter: v,
                                );
                              }
                            }),
                        onToggleExit:
                            (v) => setState(() {
                              if (_draftLocation != null) {
                                _draftLocation = _draftLocation!.copyWith(
                                  notifyExit: v,
                                );
                              }
                            }),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}
