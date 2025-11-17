import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:gad_app_team/utils/edu_progress.dart';

/// (선택) 리스트 화면 복귀 시 자동 새로고침하려면
/// MaterialApp.navigatorObservers 에 등록해 주세요.
///   navigatorObservers: [educationRouteObserver],
final RouteObserver<PageRoute<dynamic>> educationRouteObserver =
RouteObserver<PageRoute<dynamic>>();

class BookItem {
  final String title;
  final String route;
  final String imgPath;
  const BookItem(this.title, this.route, this.imgPath);
}

/// “진행 중인 주제” 전체 섹션 (상태+계산 포함)
class EducationProgressSection extends StatefulWidget {
  const EducationProgressSection({
    super.key,
    required this.items,           // 카드 목록 (title/route/imgPath)
    required this.routeToKey,      // '/education1' -> 'week1_part1'
    required this.routeToPrefix,   // '/education1' -> 'assets/education_data/week1_part1_'
    this.emptyText = '아직 진행 중인 주제가 없습니다!',
  });

  final List<BookItem> items;
  final Map<String, String> routeToKey;
  final Map<String, String> routeToPrefix;
  final String emptyText;

  @override
  State<EducationProgressSection> createState() => _EducationProgressSectionState();
}

class _EducationProgressSectionState extends State<EducationProgressSection>
    with RouteAware {
  final Map<String, int> _totalByRoute = {};
  String? _lastRoute;
  int _read = 0;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      educationRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    educationRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// 상세에서 뒤로 돌아왔을 때 최신 진행도 반영
  @override
  void didPopNext() {
    _refreshRead();
  }

  Future<void> _init() async {
    await _loadTotalsFromManifest();
    _lastRoute = await EduProgress.getLastRoute(); // '/educationN'
    if (_lastRoute != null) {
      _read = await _getReadForRoute(_lastRoute!);
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _refreshRead() async {
    if (_lastRoute == null) return;
    final latest = await _getReadForRoute(_lastRoute!);
    if (mounted) setState(() => _read = latest);
  }

  Future<int> _getReadForRoute(String route) async {
    final key = widget.routeToKey[route];
    if (key == null) return 0;
    return (await EduProgress.getRead(key));
  }

  Future<void> _loadTotalsFromManifest() async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifest = json.decode(manifestJson);

    for (final entry in widget.routeToPrefix.entries) {
      final route = entry.key;
      final prefix = entry.value; // e.g. assets/education_data/week1_part1_
      final files = manifest.keys
          .where((k) => k.startsWith(prefix) && k.endsWith('.json'))
          .toList();
      _totalByRoute[route] = files.length;
    }
  }

  BookItem? get _selectedItem {
    if (_lastRoute == null) return null;
    try {
      return widget.items.firstWhere((e) => e.route == _lastRoute);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    }

    final it = _selectedItem;
    if (it == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            widget.emptyText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
      );
    }

    final total = _totalByRoute[it.route] ?? 0;
    final read = _read.clamp(0, total);

    return ProgressCard(
      title: it.title,
      read: read,
      total: total,
      thumbPath: it.imgPath,
    );
  }
}

/// 실제 카드 UI (재사용 가능)
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.read,
    required this.total,
    this.thumbPath,
  });

  final String title;
  final int read;
  final int total;
  final String? thumbPath;

  @override
  Widget build(BuildContext context) {
    final progress = (total > 0) ? (read / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 82,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              image: (thumbPath != null)
                  ? DecorationImage(image: AssetImage(thumbPath!), fit: BoxFit.cover)
                  : null,
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(2, 4))],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF32A4EF)),
                  ),
                ),
                const SizedBox(height: 6),
                Text('읽은 페이지 $read / 전체 페이지 $total',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF636363))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
