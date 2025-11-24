import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/screen_time_api.dart';
import 'package:gad_app_team/data/models/screen_time_summary.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

class ScreenTimePage extends StatefulWidget {
  const ScreenTimePage({super.key});

  @override
  State<ScreenTimePage> createState() => _ScreenTimePageState();
}

class _ScreenTimePageState extends State<ScreenTimePage> {
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final ScreenTimeApi _screenTimeApi = ScreenTimeApi(_apiClient);

  bool _isLoading = true;
  List<ScreenTimeEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final result = await _screenTimeApi.fetchEntries(limit: 50);
      if (!mounted) return;
      setState(() {
        _entries = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      BlueBanner.show(context, '스크린타임 기록을 불러오지 못했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('스크린타임 기록'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _entries.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(
                          child: Text(
                            '최근 기록이 없습니다.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        return _SessionTile(entry: entry);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _entries.length,
                    ),
            ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.entry});

  final ScreenTimeEntry entry;

  @override
  Widget build(BuildContext context) {
    final start = entry.startTime.toLocal();
    final end = entry.endTime.toLocal();
    final dateFmt = DateFormat('yyyy.MM.dd HH:mm');
    final duration = entry.durationMinutes;
    final totalSeconds = (duration * 60).round();
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    final durationLabel = mins > 0 && secs > 0
        ? '$mins분 $secs초'
        : mins > 0
            ? '$mins분'
            : '$secs초';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${dateFmt.format(start)} ~ ${dateFmt.format(end)}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '길이: $durationLabel',
                style: const TextStyle(fontSize: 14),
              ),
              if (entry.platform != null)
                Text(
                  entry.platform!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
