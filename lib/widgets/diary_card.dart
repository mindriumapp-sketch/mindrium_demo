import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/features/menu/diary/diary_directory_screen.dart';
// import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';

// 공통 본문 텍스트 스타일
const _kBodyTextStyle = TextStyle(fontSize: 16);

class DiaryCard extends StatefulWidget {
  final AbcModel model;
  final String uid;
  final bool showDiary;
  final bool showAlarm;
  final VoidCallback? onEdit;
  final VoidCallback? onAdd;

  const DiaryCard({
    super.key,
    required this.model,
    required this.uid,
    this.showDiary = false,
    this.showAlarm = false,
    this.onEdit,
    this.onAdd,
  });

  @override
  State<DiaryCard> createState() => _DiaryCardState();
}

class _DiaryCardState extends State<DiaryCard> {
  List<String>? _alarmPreviews; // location + time previews (multiple)

  // ───────────────────────────────────────── Formatter Helpers ─────────────────────────────────────────
  // String _fmtDate(dynamic v) {
  //   if (v == null) return '';
  //   DateTime? dt;
  //   if (v is Timestamp) dt = v.toDate();
  //   if (v is String)     dt = DateTime.tryParse(v);
  //   return dt == null ? '' : DateFormat('yyyy-MM-dd').format(dt);
  // }

  String _weekdayLabel(List<int> weekdayInts) {
    if (weekdayInts.isEmpty) return '';
    const names = ['일', '월', '화', '수', '목', '금', '토'];
    weekdayInts
      ..removeWhere((e) => e < 1 || e > 7)
      ..sort();
    return weekdayInts.map((d) => names[d - 1]).join(', ');
  }

  /// Format a notification document into human‑readable multiline summary.
  String _formatAlarm(Map<String, dynamic> d) {
    try {
      // 1) 위치 / 트리거 / 시간 / 반복
      final location = (d['location'] ?? '').toString().trim();
      final inout = <String>[
        if (d['notifyEnter'] == true) '들어갈 때',
        if (d['notifyExit'] == true) '나올 때',
      ].join('/');
      final timeVal = (d['time'] ?? '').toString().trim();
      final repeatOpt = (d['repeatOption'] ?? '').toString();

      // 2) 요일 라벨
      final rawWd = d['weekdays'];
      final weekdayInts =
          rawWd is List
              ? rawWd.cast<int>()
              : (rawWd is String && rawWd.isNotEmpty)
              ? rawWd
                  .replaceAll(RegExp(r'[\[\]\s]'), '')
                  .split(',')
                  .where((e) => e.isNotEmpty)
                  .map<int>((e) => int.parse(e))
                  .toList()
              : <int>[];
      final wdLabel = _weekdayLabel(weekdayInts);

      // 3) 기타
      // final startDate = _fmtDate(d['startDate']);
      final remind = (d['reminderMinutes'] ?? '').toString();

      // 4) 조립
      final parts = <String>[
        if (location.isNotEmpty) '위치: $location',
        if (timeVal.isNotEmpty) '시간: $timeVal' else '조건: $inout',
        if (repeatOpt == 'daily')
          '반복: 매일'
        else if (repeatOpt == 'weekly' && wdLabel.isNotEmpty)
          '반복: 매주 ($wdLabel)',
        // if (startDate.isNotEmpty) '시작 날짜: $startDate',
        if (remind == '0') '다시 알림: 안함' else '다시 알림: $remind분 후',
      ];

      return parts.join('\n');
    } catch (e, st) {
      debugPrint('⚠️ DiaryCard: format error - $e');
      debugPrintStack(stackTrace: st);
      return '알림 없음';
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.showAlarm) {}
    _loadAlarmPreviews();
  }

  @override
  void didUpdateWidget(covariant DiaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 알림 펼치기로 바뀐 순간에만 쿼리
    if (widget.showAlarm && !oldWidget.showAlarm) {
      setState(() {});
      _loadAlarmPreviews();
    }
  }

  Future<void> _loadAlarmPreviews() async {
    final qs =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.uid)
            .collection('abc_models')
            .doc(widget.model.id)
            .collection('notification_settings')
            .get();

    if (qs.docs.isEmpty) return;

    final previews = <String>[];

    for (final doc in qs.docs) {
      final d = doc.data();
      final loc = (d['location'] ?? '').toString().trim();
      final timeVal = (d['time'] ?? '').toString().trim();
      final parts = <String>[
        if (loc.isNotEmpty) loc,
        if (timeVal.isNotEmpty) timeVal,
      ];
      if (parts.isNotEmpty) previews.add(parts.join('\n'));
    }

    if (!mounted) return; // 위젯이 이미 dispose 된 경우 보호
    if (previews.isNotEmpty) {
      setState(() => _alarmPreviews = previews);
    }
  }

  // ───────────────────────────────────────── UI Builders ─────────────────────────────────────────
  Widget _buildTitle() {
    return Text(
      widget.model.activatingEvent,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPreview() {
    if (widget.showDiary || widget.showAlarm || _alarmPreviews == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        ..._alarmPreviews!.asMap().entries.expand((e) {
          final idx = e.key;
          final txt = e.value;
          return [
            if (idx > 0) Divider(height: 12),
            Text(txt, style: _kBodyTextStyle),
          ];
        }),
      ],
    );
  }

  Widget _buildDiaryDetail() {
    if (!widget.showDiary) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('생각: ${widget.model.belief}', style: _kBodyTextStyle),
        const SizedBox(height: 4),
        Text('결과: ${widget.model.consequence}', style: _kBodyTextStyle),
      ],
    );
  }

  Widget _buildAlarmList(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(widget.model.id)
        .collection('notification_settings');

    return StreamBuilder<QuerySnapshot>(
      stream: col.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final items = snap.data!.docs;
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final doc = items[i];
            final data = doc.data() as Map<String, dynamic>;
            final detail = _formatAlarm(data);

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(detail),
              trailing: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => NotificationSelectionScreen(
                            origin: 'edit',
                            abcId: widget.model.id,
                            notificationId: doc.id,
                            label: widget.model.activatingEvent,
                          ),
                    ),
                  );
                },
                child: const Text('수정'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: Colors.black12),
      ),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTitle(),
              SizedBox(height: 8),
              _buildPreview(),
              _buildDiaryDetail(),
              if (widget.showAlarm && widget.showDiary) ...[
                SizedBox(height: 8),
                Divider(height: 1),
              ],
              if (widget.showAlarm) ...[_buildAlarmList(context)],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(40, 24),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: widget.onAdd ?? () {},
              child: const Text('알림 추가'),
            ),
          ),
        ],
      ),
    );
  }
}
