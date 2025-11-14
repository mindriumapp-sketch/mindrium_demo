import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gad_app_team/features/menu/archive/sea_archive_page.dart';
import 'package:gad_app_team/navigation/navigation.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'treatment_screen.dart';
import 'myinfo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const int _kTotalWeeks = 8;
  Future<int>? _completedWeeksFuture;
  bool _permissionsChecked = false;

  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    Future.microtask(() async {
      await _ensureCorePermissions();
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
      userProvider.loadUserData(dayCounter: dayCounter);
      _completedWeeksFuture ??= _loadCompletedCount();
      await _ensureCreatedAt(); // ← 추가
      if (mounted) setState(() {});
    });
  }

  Future<int> _loadCompletedCount() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};

    int fromMap = 0;
    final rawCW = data['completed_weeks'];
    if (rawCW is Map) {
      fromMap =
          rawCW.entries
              .where((e) => e.value == true)
              .map((e) => int.tryParse(e.key.toString()) ?? 0)
              .where((n) => n > 0 && n <= _kTotalWeeks)
              .length;
    }

    return fromMap;
  }

  Future<void> _ensureCreatedAt() async {
    if (_createdAt != null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      final provider =
          Provider.of<UserProvider>(context, listen: false).createdAt;
      if (provider != null) {
        _createdAt = provider;
      }
      return;
    }
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final ts = doc.data()?['createdAt'];
    if (ts is Timestamp) {
      _createdAt = ts.toDate();
    } else {
      // 폴백: Auth 생성일로 D+를 계산하되, 가능하면 MyInfoScreen처럼 최초 저장도 해두는 걸 추천
      _createdAt = FirebaseAuth.instance.currentUser?.metadata.creationTime;
      if (_createdAt == null) {
        final provider =
            Provider.of<UserProvider>(context, listen: false).createdAt;
        if (provider != null) {
          _createdAt = provider;
        }
      }
    }
  }

  String joinDaysText() {
    final base =
        _createdAt ??
        Provider.of<UserProvider>(context, listen: false).createdAt;
    if (base == null) return '가입 정보 없음';
    final d = daysBetween(DateTime.now(), base);
    return '가입한 지 ${d}일째';
  }

  int daysBetween(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return da.difference(db).inDays;
  }

  void _onDestinationSelected(int index) =>
      setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // 배경: eduhome.png + 반투명 오버레이
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
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
          ),

          // 실제 내용
          SafeArea(child: _buildBody()),

          // 네비게이션 바
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomNavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _homePage();
      case 1:
        return const TreatmentScreen();
      case 2:
        return const SeaArchivePage();
      case 3:
        return const MyInfoScreen();
      default:
        return _homePage();
    }
  }

  Future<void> _ensureCorePermissions() async {
    if (_permissionsChecked) return;
    final perms = <Permission>[
      Permission.notification,
      Permission.locationWhenInUse,
    ];
    if (Platform.isAndroid) {
      perms.addAll([
        Permission.scheduleExactAlarm,
        Permission.activityRecognition,
      ]);
    }
    for (final perm in perms) {
      if (!await perm.isGranted) await perm.request();
    }
    _permissionsChecked = true;
  }

  Widget _homePage() {
    final completedWeeksFuture =
        _completedWeeksFuture ??= _loadCompletedCount();

    return FutureBuilder<int>(
      future: completedWeeksFuture,
      builder: (context, snapshot) {
        final doneCount = snapshot.data ?? 0;
        final progress = doneCount / _kTotalWeeks;
        debugPrint("doneCount: $doneCount, progress: $progress"); // 0.0 ~ 1.0
        final percentLabel = '${(progress * 100).round()}%'; // "12%", "25%" 등

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildProgressCard(progress, percentLabel),
            const SizedBox(height: 16),
            _buildTaskSection(),
            const SizedBox(height: 16),
            _buildTrainingSection(),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    final user = context.watch<UserProvider>();
    final dayCounter = context.watch<UserDayCounter>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 👤 왼쪽: 사용자 인사 + 위치
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 💬 “안녕하세요, 홍길동님 환영합니다!” 한 줄로 표시
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontFamily: 'Noto Sans KR',
                      height: 1.3,
                    ),
                    children: [
                      const TextSpan(text: '안녕하세요,\n'),
                      TextSpan(text: '${user.userName}님 환영합니다!'),
                    ],
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: false, // 🚫 자동 줄바꿈 방지
                ),

                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dayCounter.isUserLoaded
                        ? '가입한 지 ${dayCounter.daysSinceJoin}일째'
                        : joinDaysText(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: 'Noto Sans KR',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          /// 🤖 오른쪽: 아이콘 (에이전트 / 메뉴)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconCircle(
                icon: Icons.smart_toy_rounded,
                onTap: () => Navigator.pushNamed(context, '/agent_help'),
              ),
              const SizedBox(width: 10),
              _iconCircle(
                icon: Icons.menu_rounded,
                onTap: () => Navigator.pushNamed(context, '/contents'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconCircle({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.black, size: 26),
        ),
      ),
    );
  }

  Widget _buildProgressCard(double progress, String percentLabel) {
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '치료 진행 상황',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Text(
                percentLabel,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00AEEF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection() {
    final List<_DailyTask> todayTasks = const [
      _DailyTask(title: '일일 과제 1', isDone: true),
      _DailyTask(title: '일일 과제 2', isDone: false),
      _DailyTask(title: '일일 과제 3', isDone: false),
      _DailyTask(title: '일일 과제 4', isDone: true),
    ];

    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '오늘의 할 일',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...todayTasks.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildTaskCard(t),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(_DailyTask task) {
    final isDone = task.isDone;
    final imagePath =
        isDone ? 'assets/image/finish.png' : 'assets/image/progressing.png';
    final bgColor = isDone ? const Color(0xFFFFE5E9) : const Color(0xFFD9F3FF);

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, color: bgColor),
          padding: const EdgeInsets.all(10),
          child: Image.asset(imagePath, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            task.title,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _trainingCard(
          title: '불안 해결하기',
          description: '오늘 불안하신 상황이 있으셨나요? 지금 눌러서 오늘의 활동을 시작해봐요.',
          color: const Color(0xFFFFE2E8),
          imagePath: 'assets/image/pink2.png',
          onTap:
              () => Navigator.pushNamed(
                context,
                '/before_sud',
                arguments: const {'origin': 'apply', 'diary': 'new'},
              ),
        ),
      ],
    );
  }

  Widget _trainingCard({
    required String title,
    required String description,
    required Color color,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: _WhiteCard(
        color: color,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Image.asset(imagePath, width: 80, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _WhiteCard({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DailyTask {
  final String title;
  final bool isDone;
  const _DailyTask({required this.title, required this.isDone});
}
