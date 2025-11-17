import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/models/screen_time_entry.dart';
import 'package:gad_app_team/data/models/screen_time_summary.dart';
import 'package:gad_app_team/data/screen_time_provider.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen> {
  final DateFormat _dayFormat = DateFormat('M월 d일 (E)', 'ko');
  final DateFormat _timeFormat = DateFormat('a h:mm', 'ko');

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ScreenTimeProvider>().refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스크린타임 기록'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ScreenTimeProvider>().refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEntrySheet(),
        icon: const Icon(Icons.add),
        label: const Text('기록 추가'),
      ),
      body: Consumer<ScreenTimeProvider>(
        builder: (context, provider, _) {
          final summary = provider.summary;
          final entries = provider.entries;

          return RefreshIndicator(
            onRefresh: provider.refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                _buildSummaryCard(summary, provider.isLoading),
                if (provider.isLimitedView)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '최근 ${provider.maxEntries}개의 기록만 표시됩니다. 전체 통계는 요약 카드에서 확인하세요.',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                const SizedBox(height: 12),
                if (provider.isLoading && entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (entries.isEmpty)
                  _buildEmptyState()
                else ...entries.map(_buildEntryTile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(ScreenTimeSummary? summary, bool isLoading) {
    final total = summary?.totalLabel ?? '--';
    final today = summary != null ? '${summary.todayMinutes}분' : '--';
    final week = summary != null ? '${summary.weekMinutes}분' : '--';
    final sessions = summary != null ? '${summary.sessions}회' : '--';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이번 주 사용 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          if (isLoading && summary == null)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(
              children: [
                _SummaryStat(label: '총 사용 시간', value: total),
                _SummaryStat(label: '오늘', value: today),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _SummaryStat(label: '최근 7일', value: week),
                _SummaryStat(label: '기록 횟수', value: sessions),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryTile(ScreenTimeEntry entry) {
    final start = entry.startTime.toLocal();
    final end = entry.endTime?.toLocal();
    final dateLabel = '${_dayFormat.format(start)} · ${_timeFormat.format(start)}';
    final duration = entry.prettyDuration;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () => _showEntrySheet(entry: entry),
        title: Text(
          entry.label ?? '기록 ${entry.id.substring(entry.id.length - 4)}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              end != null ? '$dateLabel ~ ${_timeFormat.format(end)}' : dateLabel,
              style: const TextStyle(color: Colors.black54),
            ),
            if (entry.note != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  entry.note!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              duration,
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF004C73)),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEntrySheet(entry: entry);
                } else if (value == 'delete') {
                  _confirmDelete(entry.id);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('수정하기')),
                PopupMenuItem(value: 'delete', child: Text('삭제하기')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.hourglass_empty, size: 48, color: Colors.black26),
          SizedBox(height: 12),
          Text('아직 기록된 스크린타임이 없어요.'),
        ],
      ),
    );
  }

  Future<void> _showEntrySheet({ScreenTimeEntry? entry}) async {
    final provider = context.read<ScreenTimeProvider>();
    final isEditing = entry != null;
    DateTime startTime = (entry?.startTime ?? DateTime.now()).toLocal();
    DateTime endTime = entry?.endTime?.toLocal() ??
        (entry != null
            ? entry.startTime.toLocal().add(Duration(minutes: entry.durationMinutes))
            : startTime.add(const Duration(minutes: 30)));
    if (!endTime.isAfter(startTime)) {
      endTime = startTime.add(const Duration(minutes: 1));
    }
    final labelController = TextEditingController(text: entry?.label ?? '');
    final noteController = TextEditingController(text: entry?.note ?? '');
    bool submitting = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDateTime({required bool isStart}) async {
              final initial = isStart ? startTime : endTime;
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (pickedDate == null) return;
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(initial),
              );
              if (pickedTime == null) return;
              setSheetState(() {
                final newValue = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
                if (isStart) {
                  startTime = newValue;
                  if (!endTime.isAfter(startTime)) {
                    endTime = startTime.add(const Duration(minutes: 1));
                  }
                } else {
                  endTime = newValue.isAfter(startTime)
                      ? newValue
                      : startTime.add(const Duration(minutes: 1));
                }
              });
            }

            Future<void> submit() async {
              final minutes = endTime.difference(startTime).inMinutes;
              if (minutes <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('종료 시각이 시작 시각 이후가 되도록 설정해주세요.')),
                );
                return;
              }
              setSheetState(() => submitting = true);
              try {
                final label = labelController.text.trim().isEmpty
                    ? null
                    : labelController.text.trim();
                final note = noteController.text.trim().isEmpty
                    ? null
                    : noteController.text.trim();
                if (isEditing) {
                  await provider.updateEntry(
                    entry!.id,
                    startTime: startTime,
                    endTime: endTime,
                    durationMinutes: minutes,
                    label: label,
                    note: note,
                  );
                } else {
                  await provider.addEntry(
                    startTime: startTime,
                    endTime: endTime,
                    durationMinutes: minutes,
                    label: label,
                    note: note,
                  );
                }
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('기록을 저장하지 못했어요: $e')),
                );
              } finally {
                setSheetState(() => submitting = false);
              }
            }

            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('시작 시각'),
                      subtitle: Text(DateFormat('yyyy.MM.dd HH:mm').format(startTime)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        onPressed: submitting ? null : () => pickDateTime(isStart: true),
                      ),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('종료 시각'),
                      subtitle: Text(DateFormat('yyyy.MM.dd HH:mm').format(endTime)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_calendar_outlined),
                        onPressed: submitting ? null : () => pickDateTime(isStart: false),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          '총 사용 시간: ${endTime.difference(startTime).inMinutes}분',
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ),
                    ),
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: '라벨 (선택)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: '메모 (선택)'),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '앱을 백그라운드에 두는 시간까지 포함하려면 시작/종료 시각을 그대로 사용해 주세요.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submitting ? null : submit,
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(isEditing ? '수정하기' : '저장'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEditing ? '스크린타임을 수정했어요.' : '스크린타임이 기록되었어요.')),
      );
    }
  }

  Future<void> _confirmDelete(String entryId) async {
    final provider = context.read<ScreenTimeProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('선택한 스크린타임 기록을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')), 
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await provider.deleteEntry(entryId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('삭제되었습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('삭제하지 못했어요: $e')),
          );
        }
      }
    }
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF004C73)),
          ),
        ],
      ),
    );
  }
}
