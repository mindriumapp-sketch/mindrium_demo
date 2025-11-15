import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/menu/menu_screen.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';

class DiaryEntry {
  final String id;
  final int? groupId;
  final String activatingEvents;
  final List<String> belief;
  final List<String> consequenceEmotion;
  final List<String> consequencePhysical;
  final List<String> consequenceBehavior;
  final List<Map<String, dynamic>> sudScores;
  final List<Map<String, dynamic>> alarms;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? addressName;

  DiaryEntry({
    required this.id,
    required this.groupId,
    required this.activatingEvents,
    required this.belief,
    required this.consequenceEmotion,
    required this.consequencePhysical,
    required this.consequenceBehavior,
    required this.sudScores,
    required this.alarms,
    required this.createdAt,
    required this.updatedAt,
    required this.addressName,
  });

  factory DiaryEntry.fromMap(Map<String, dynamic> raw) {
    final createdRaw = raw['createdAt'];
    final updatedRaw = raw['updatedAt'];

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value.toUtc();
      if (value is String) {
        try {
          return DateTime.parse(value).toUtc();
        } catch (_) {}
      }
      return DateTime.now().toUtc();
    }

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
      }
      return const [];
    }

    List<Map<String, dynamic>> sudScoreList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((e) => e.map((key, val) => MapEntry(key.toString(), val)))
            .toList();
      }
      return const [];
    }

    List<Map<String, dynamic>> alarmList(dynamic value) {
      Iterable<Map> source;
      if (value is Map) {
        source = value.values.whereType<Map>();
      } else if (value is List) {
        source = value.whereType<Map>();
      } else {
        return const [];
      }

      return source
          .map((alarm) {
            final sanitized = alarm.map((k, v) => MapEntry(k.toString(), v));
            sanitized.remove('latitude');
            sanitized.remove('longitude');
            return sanitized;
          })
          .toList()
          .cast<Map<String, dynamic>>();
    }

    return DiaryEntry(
      id: raw['diaryId']?.toString() ?? 'unknown',
      groupId: raw['group_Id'] is num
          ? (raw['group_Id'] as num).toInt()
          : int.tryParse('${raw['group_Id']}'),
      activatingEvents: raw['activating_events']?.toString() ?? '-',
      belief: stringList(raw['belief']),
      consequenceEmotion: stringList(raw['consequence_e']),
      consequencePhysical: stringList(raw['consequence_p']),
      consequenceBehavior: stringList(raw['consequence_b']),
      sudScores: sudScoreList(raw['sudScores']),
      alarms: alarmList(raw['alarms']),
      createdAt: parseDate(createdRaw),
      updatedAt: updatedRaw == null ? null : parseDate(updatedRaw),
      addressName: raw['addressName']?.toString(),
    );
  }
}

class NotificationDirectoryScreen extends StatefulWidget {
  const NotificationDirectoryScreen({super.key});

  @override
  State<NotificationDirectoryScreen> createState() => _NotificationDirectoryScreenState();
}

class _NotificationDirectoryScreenState extends State<NotificationDirectoryScreen> {
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  List<DiaryEntry> _diaries = [];
  int? _selectedGroupId;
  bool _loading = true;
  String? _error;

  Future<void> _loadDiaries() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _diariesApi.listDiaries();
      final entries = list.map((item) => DiaryEntry.fromMap(item)).toList();
      if (!mounted) return;
      setState(() {
        _diaries = entries;
        if (_diaries.every((d) => d.groupId != _selectedGroupId)) {
          _selectedGroupId = null;
        }
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data is Map
            ? e.response?.data['detail']?.toString()
            : e.message ?? '알 수 없는 오류가 발생했습니다.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '일기를 불러오지 못했습니다: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadDiaries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '일기 목록',
        showHome: true,
        confirmOnHome: false,
        confirmOnBack: false,
        onBack: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ContentScreen()),
            (route) => false,
          );
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/image/eduhome.png', fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xAAFFFFFF), Color(0x66FFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadDiaries,
            child: const Text('다시 시도'),
          ),
        ],
      );
    }
    if (_diaries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadDiaries,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Center(
              child: Text(
                '작성된 일기가 없습니다.',
                style: TextStyle(color: Color(0xFF1B405C), fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _selectedGroupId == null
        ? _diaries
        : _diaries.where((d) => d.groupId == _selectedGroupId).toList();

    return RefreshIndicator(
      onRefresh: _loadDiaries,
      child: Column(
        children: [
          _GroupFilter(
            selectedGroupId: _selectedGroupId,
            groupIds: _extractGroupIds(),
            onSelected: (value) {
              setState(() => _selectedGroupId = value);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                return _DiaryCard(
                  entry: filtered[index],
                  onAlarmUpdated: _loadDiaries,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<int?> _extractGroupIds() {
    final set = {
      for (final diary in _diaries) diary.groupId,
    };
    final sorted = set.where((id) => id != null).toList()..sort();
    return [null, ...sorted];
  }
}

class _GroupFilter extends StatelessWidget {
  final List<int?> groupIds;
  final int? selectedGroupId;
  final ValueChanged<int?> onSelected;

  const _GroupFilter({
    required this.groupIds,
    required this.selectedGroupId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.group_outlined, color: Color(0xFF5B9FD3)),
              SizedBox(width: 8),
              Text(
                '그룹 필터',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0E2C48),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: groupIds.map((id) {
              final bool selected = id == selectedGroupId;
              final label = id == null ? '전체 그룹' : '그룹 #$id';
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onSelected(id),
                selectedColor: const Color(0xFF5B9FD3),
                labelStyle: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1B405C),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final DiaryEntry entry;
  final Future<void> Function()? onAlarmUpdated;
  const _DiaryCard({required this.entry, this.onAlarmUpdated});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy.MM.dd HH:mm');
    final created = formatter.format(entry.createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3F2FD), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFB8DAF5),
            child: Text(
              entry.groupId?.toString() ?? '?',
              style: const TextStyle(
                color: Color(0xFF0E2C48),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            entry.activatingEvents,
            style: const TextStyle(
              color: Color(0xFF0E2C48),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              created,
              style: const TextStyle(
                color: Color(0xFF1B405C),
                fontSize: 14,
              ),
            ),
          ),
          children: [
            _SudScoreBar(scores: entry.sudScores),
            const SizedBox(height: 12),
            _buildSection(
              context: context,
              icon: Icons.psychology_outlined,
              title: '생각 (Belief)',
              child: Text(
                entry.belief.isEmpty ? '-' : entry.belief.join(', '),
                style: const TextStyle(color: Color(0xFF1B405C)),
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              context: context,
              icon: Icons.local_hospital_outlined,
              title: '신체 반응',
              child: Text(
                entry.consequencePhysical.isEmpty
                    ? '-'
                    : entry.consequencePhysical.join(', '),
                style: const TextStyle(color: Color(0xFF1B405C)),
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              context: context,
              icon: Icons.mood_outlined,
              title: '감정 반응',
              child: Text(
                entry.consequenceEmotion.isEmpty
                    ? '-'
                    : entry.consequenceEmotion.join(', '),
                style: const TextStyle(color: Color(0xFF1B405C)),
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              context: context,
              icon: Icons.directions_walk_outlined,
              title: '행동 반응',
              child: Text(
                entry.consequenceBehavior.isEmpty
                    ? '-'
                    : entry.consequenceBehavior.join(', '),
                style: const TextStyle(color: Color(0xFF1B405C)),
              ),
            ),
            const SizedBox(height: 12),
            _AlarmSection(
              alarms: entry.alarms,
              onEdit: () async {
                await Navigator.pushNamed(
                  context,
                  '/noti_select',
                  arguments: {
                    'fromDirectory': true,
                    'abcId': entry.id,
                    'label': entry.activatingEvents,
                    'origin': 'diary_directory',
                  },
                );
                if (onAlarmUpdated != null) {
                  await onAlarmUpdated!();
                }
              },
            ),
            if (entry.addressName != null && entry.addressName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSection(
                context: context,
                icon: Icons.location_on_outlined,
                title: '기록 위치',
                child: Text(
                  entry.addressName!,
                  style: const TextStyle(color: Color(0xFF1B405C)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SudScoreBar extends StatelessWidget {
  final List<Map<String, dynamic>> scores;
  const _SudScoreBar({required this.scores});

  int _parseScore(dynamic value) {
    if (value is num) return value.clamp(0, 10).toInt();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed.clamp(0, 10).toInt();
      }
    }
    return 0;
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {}
    }
    return DateTime.now().toUtc();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? latestEntry;
    if (scores.isNotEmpty) {
      final copy = List<Map<String, dynamic>>.from(scores);
      copy.sort((a, b) => _parseDate(a['created_at']).compareTo(_parseDate(b['created_at'])));
      latestEntry = copy.last;
    }
    final latest = _parseScore(latestEntry?['before_sud']);
    final ratio = latest / 10.0;
    final color = Color.lerp(const Color(0xFF4CAF50), const Color(0xFFF44336), ratio)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3F2FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '주관적 불안점수',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0E2C48),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$latest / 10',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmSection extends StatelessWidget {
  final List<Map<String, dynamic>> alarms;
  final VoidCallback? onEdit;
  const _AlarmSection({required this.alarms, this.onEdit});

  static const List<String> _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

  String _weekdayLabel(int dayNumber) {
    if (dayNumber < 1 || dayNumber > 7) return '$dayNumber';
    return _weekdayNames[dayNumber - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (alarms.isEmpty) {
      return _buildSection(
        context: context,
        icon: Icons.notifications_none,
        title: '알림 정보',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '설정된 알림이 없습니다.',
              style: TextStyle(color: Color(0xFF1B405C)),
            ),
            const SizedBox(height: 8),
            _AlarmActionButton(label: '알림 추가', onPressed: onEdit),
          ],
        ),
      );
    }

    return _buildSection(
      context: context,
      icon: Icons.notifications_active_outlined,
      title: '알림 정보',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...alarms.asMap().entries.map((entry) {
            final map = entry.value as Map? ?? {};
          final location = map['location_desc'] ??
              map['location'] ??
              map['addressName'] ??
              '-';
          final notifyEnter = map['notifyEnter'] == true || map['enter'] == true;
          final notifyExit = map['notifyExit'] == true || map['exit'] == true;
          final condition = notifyEnter && notifyExit
              ? '입장/퇴장'
              : notifyEnter
                  ? '입장 시'
                  : notifyExit
                      ? '퇴장 시'
                      : '';
          final time = map['time'] ?? map['scheduledTime'] ?? '-';
          final repeatOption = (map['repeat_option'] ?? '').toString();
          final weekDays = (map['weekDays'] as List?)
                  ?.map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
                  .where((d) => d > 0 && d <= 7)
                  .toList() ??
              const [];
          final reminderMinutes = map['reminder_minutes'];
          final repeatText = repeatOption == 'weekly'
              ? (weekDays.isNotEmpty
                  ? '매주 (${weekDays.map(_weekdayLabel).join(', ')})'
                  : '매주')
              : '매일';
          final reminderText = reminderMinutes is num && reminderMinutes > 0
              ? '알림 $reminderMinutes분 전'
              : null;
          final locationDisplay = condition.isNotEmpty && location != '-'
              ? '$location ($condition)'
              : condition.isNotEmpty
                  ? condition
                  : location.toString();

            return Container(
              margin: EdgeInsets.only(top: entry.key > 0 ? 10 : 0),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4A8CCB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(Icons.location_on_outlined, '위치', locationDisplay),
                  const SizedBox(height: 6),
                  _infoRow(Icons.access_time_outlined, '시간', time.toString()),
                  const SizedBox(height: 6),
                  _infoRow(Icons.repeat, '반복', repeatText),
                  if (reminderText != null) ...[
                    const SizedBox(height: 6),
                    _infoRow(Icons.alarm, '다시 알림', reminderText),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _AlarmActionButton(label: '알림 수정', onPressed: onEdit),
        ],
      ),
    );
  }
}

class _AlarmActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _AlarmActionButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF5B9FD3);
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

Widget _buildSection({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Widget child,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF90CAF9), width: 1.2),
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(icon, color: const Color(0xFF5B9FD3), size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0E2C48),
            fontSize: 14,
          ),
        ),
        children: [child],
      ),
    ),
  );
}

Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF5B9FD3)),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0E2C48),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1B405C),
          ),
        ),
      ),
    ],
  );
}
