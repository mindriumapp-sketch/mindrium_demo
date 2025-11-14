import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/map_picker.dart';
import 'package:gad_app_team/data/notification_provider.dart';

// ✅ UI 위젯 (업로드한 파일 경로에 맞게 import 경로 조정)
import 'package:gad_app_team/widgets/notification_selection_ui.dart';
// (필요시) 디자인 래퍼/배너도 사용할 수 있음
import 'package:gad_app_team/widgets/notification_selection_design.dart';
import 'package:gad_app_team/widgets/notification_alert_design.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

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
  NotificationSetting? _draftTime;
  NotificationSetting? _draftLocation;
  String? _abcId; // 연결된 ABC 문서 ID

  RepeatOption _repeatOption = RepeatOption.daily;
  final Set<int> _selectedWeekdays = {};
  Duration _reminderDuration = const Duration(hours: 0, minutes: 0);
  bool _noNotification = false;
  bool _isSaving = false; // 저장 중 상태

  String get _origin => widget.origin ?? 'etc';

  @override
  void initState() {
    super.initState();
    _abcId = widget.abcId;
    _loadExisting();
    debugPrint('[NOTI] _origin=$_origin');
  }

  /// 기존 알림 설정을 불러와 초깃값으로 반영
  Future<void> _loadExisting() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    DocumentSnapshot<Map<String, dynamic>>? abcDoc;

    if (widget.abcId?.isNotEmpty ?? false) {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('abc_models')
              .doc(widget.abcId!)
              .get();
      if (doc.exists) abcDoc = doc;
    } else if (widget.label?.isNotEmpty ?? false) {
      final qs =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('abc_models')
              .where('activatingEvent', isEqualTo: widget.label)
              .limit(1)
              .get();
      if (qs.docs.isNotEmpty) abcDoc = qs.docs.first;
    }
    if (abcDoc == null) return;

    _abcId ??= abcDoc.id;

    List<DocumentSnapshot<Map<String, dynamic>>> notifDocs = [];

    if (widget.notificationId != null && widget.notificationId!.isNotEmpty) {
      final single =
          await abcDoc.reference
              .collection('notification_settings')
              .doc(widget.notificationId!)
              .get();
      if (single.exists) notifDocs = [single];
    } else {
      final qs =
          await abcDoc.reference.collection('notification_settings').get();
      notifDocs = qs.docs;
    }

    _draftTime = null;
    _draftLocation = null;
    _selectedWeekdays.clear();

    for (final d in notifDocs) {
      final setting = NotificationSetting.fromDoc(d);

      final bool hasLocation =
          setting.latitude != null && setting.longitude != null;
      final bool hasTime = setting.time != null;

      if (hasLocation) {
        _draftLocation = setting;

        if (hasTime) {
          _repeatOption = setting.repeatOption;
          _selectedWeekdays.addAll(setting.weekdays);
        }
      } else if (hasTime) {
        _draftTime = setting;
        _repeatOption = setting.repeatOption;
        _selectedWeekdays.addAll(setting.weekdays);
      }

      if (setting.reminderMinutes != null) {
        _reminderDuration = Duration(minutes: setting.reminderMinutes!);
      }
    }

    if (_draftTime == null &&
        _draftLocation != null &&
        _draftLocation!.time != null) {
      _draftTime = _draftLocation!.copyWith(
        latitude: null,
        longitude: null,
        location: null,
        notifyEnter: false,
        notifyExit: false,
      );
    }

    if (mounted) setState(() {});
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
                                if (opt != null)
                                  setLocal(() => _repeatOption = opt);
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
                              id:
                                  _origin == 'edit'
                                      ? (_draftTime?.id ??
                                          widget.notificationId)
                                      : null,
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
      final withId =
          (_draftTime?.id != null && _origin == 'edit')
              ? setting.copyWith(id: _draftTime!.id)
              : setting;
      setState(() => _draftTime = withId);
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
        id:
            _origin == 'edit'
                ? (_draftLocation?.id ?? widget.notificationId)
                : null,
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
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
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

    final navigator = Navigator.of(context);
    final provider = NotificationProvider();

    _syncRepeatIntoDrafts();

    setState(() => _isSaving = true);

    try {
      // 1) “알림을 설정하지 않을래요”
      if (_noNotification) {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        if (_abcId == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('ABC 모델을 찾을 수 없습니다.')));
          return;
        }

        final abcRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('abc_models')
            .doc(_abcId!);

        if (widget.notificationId != null &&
            widget.notificationId!.isNotEmpty) {
          final notifRef = abcRef
              .collection('notification_settings')
              .doc(widget.notificationId);
          await notifRef.delete();
          await provider.cancelSchedule(
            id: widget.notificationId!,
            abcId: _abcId!,
          );
        } else {
          final batch = FirebaseFirestore.instance.batch();
          final snapshot =
              await abcRef.collection('notification_settings').get();
          for (final d in snapshot.docs) {
            batch.delete(d.reference);
          }
          await batch.commit();
          await provider.cancelAllSchedules(abcId: _abcId!);
        }

        if (!mounted) return;
        navigator.pushNamedAndRemoveUntil('/home', (_) => false);
        return;
      }

      // 2) reminderMinutes 최신화
      _syncReminderMinutes();

      // 현재 위치 가져오기 (가능한 경우)
      Position? currentPos;
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          currentPos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
            ),
          );
        }
      } catch (_) {}

      // 3) 선택된 알림 저장 & 스케줄
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (_abcId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ABC 모델을 찾을 수 없습니다.')));
        return;
      }

      // 위치 + 시간 → 하나의 문서로 합치기
      DocumentReference<Map<String, dynamic>>? timeDocToDelete;
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
          timeDocToDelete = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('abc_models')
              .doc(_abcId!)
              .collection('notification_settings')
              .doc(_draftTime!.id);
        }

        _draftTime = null;
      }

      final batch = FirebaseFirestore.instance.batch();
      final List<Future<void> Function()> afterCommit = [];

      Future<void> upsert(NotificationSetting s) async {
        final col = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('abc_models')
            .doc(_abcId!)
            .collection('notification_settings');

        String? docId = s.id;
        if (_origin == 'edit' && (docId == null || docId.isEmpty)) {
          docId = widget.notificationId;
        }

        final ref =
            (_origin == 'edit' && docId != null && docId.isNotEmpty)
                ? col.doc(docId)
                : col.doc();

        final Map<String, dynamic> data = s.toMap();

        if (currentPos != null) {
          data['latitude'] = currentPos.latitude;
          data['longitude'] = currentPos.longitude;
        }

        if (data['time'] != null) {
          data['notifyEnter'] = null;
          data['notifyExit'] = null;
        }

        if (_origin == 'edit' && docId != null && docId.isNotEmpty) {
          batch.update(ref, data);
          afterCommit.add(
            () async =>
                provider.updateSchedule(s.copyWith(id: ref.id), abcId: _abcId!),
          );
        } else {
          batch.set(ref, data);
          afterCommit.add(
            () async =>
                provider.createSchedule(s.copyWith(id: ref.id), abcId: _abcId!),
          );
        }

        if (s.id == null) {
          if (identical(s, _draftTime)) {
            _draftTime = s.copyWith(id: ref.id);
          }
          if (identical(s, _draftLocation)) {
            _draftLocation = s.copyWith(id: ref.id);
          }
        }
      }

      if (_draftTime != null) await upsert(_draftTime!);
      if (_draftLocation != null) await upsert(_draftLocation!);
      if (timeDocToDelete != null) {
        batch.delete(timeDocToDelete);
      }
      await batch.commit();
      for (final f in afterCommit) {
        await f();
      }

      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil('/home', (_) => false);
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
              child: NotificationSelectionUI(
                // 데이터 ...
                label: widget.label,
                draftTime: _draftTime,
                draftLocation: _draftLocation,
                noNotification: _noNotification,
                repeatOption: _repeatOption,
                selectedWeekdays: _selectedWeekdays,
                reminderDuration: _reminderDuration,

                // 액션 ...
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

                // ✅ 여기!
                // 새로 추가된 콜백들도 함께 ↓
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
