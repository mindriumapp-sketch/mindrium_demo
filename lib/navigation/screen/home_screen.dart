import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/features/menu/archive/sea_archive_page.dart';
import 'package:gad_app_team/navigation/navigation.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'treatment_screen.dart';
import 'myinfo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});
  final int initialIndex; 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ProgressSnapshot {
  final int completedWeeks;
  final int totalWeeks;
  final int totalDiaries;
  final int totalRelaxations;

  const _ProgressSnapshot({
    required this.completedWeeks,
    required this.totalWeeks,
    required this.totalDiaries,
    required this.totalRelaxations,
  });

  double get percent => totalWeeks == 0 ? 0 : completedWeeks / totalWeeks;
  String get percentLabel => '${(percent * 100).round()}%';
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const int _kTotalWeeks = 8;
  Future<_ProgressSnapshot>? _progressFuture;
  bool _permissionsChecked = false;
  Future<void>? _permissionFuture;
  final TokenStorage _tokenStorage = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokenStorage);
  late final UserDataApi _userDataApi = UserDataApi(_apiClient);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    Future.microtask(() async {
      await _ensureCorePermissions();
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
      await userProvider.loadUserData(dayCounter: dayCounter);
      _progressFuture ??= _loadProgress();
      if (mounted) setState(() {});
    });
  }

  Future<_ProgressSnapshot> _loadProgress() async {
    try {
      final progress = await _userDataApi.getProgress();
      var completed = 0;
      final weekProgress = progress['week_progress'];
      if (weekProgress is List) {
        for (final week in weekProgress) {
          if (week is Map && week['completed'] == true) {
            completed++;
          }
        }
        completed = completed.clamp(0, _kTotalWeeks);
      }

      final currentWeek = progress['current_week'];
      if (currentWeek is int && currentWeek > 1) {
        completed = (currentWeek - 1).clamp(0, _kTotalWeeks);
      }

      final totalDiaries = (progress['total_diaries'] as int?) ?? 0;
      final totalRelaxations = (progress['total_relaxations'] as int?) ?? 0;

      return _ProgressSnapshot(
        completedWeeks: completed,
        totalWeeks: _kTotalWeeks,
        totalDiaries: totalDiaries,
        totalRelaxations: totalRelaxations,
      );
    } catch (e) {
      debugPrint('진행도 데이터를 불러오지 못했습니다: $e');
      return const _ProgressSnapshot(
        completedWeeks: 0,
        totalWeeks: _kTotalWeeks,
        totalDiaries: 0,
        totalRelaxations: 0,
      );
    }
  }

  String joinDaysText(UserDayCounter counter, DateTime? fallbackCreatedAt) {
    if (counter.isUserLoaded) {
      return '가입한 지 ${counter.daysSinceJoin}일째';
    }
    final created = fallbackCreatedAt;
    if (created == null) {
      return '가입 정보 없음';
    }
    final days = DateTime.now().difference(created).inDays + 1;
    return '가입한 지 ${days > 0 ? days : 1}일째';
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

  Future<void> _ensureCorePermissions() {
    return _permissionFuture ??= _requestPermissions();
  }

  Future<void> _requestPermissions() async {
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
    final progressFuture = _progressFuture ??= _loadProgress();

    return FutureBuilder<_ProgressSnapshot>(
      future: progressFuture,
      builder: (context, snapshot) {
        final progressData = snapshot.data ??
            const _ProgressSnapshot(
              completedWeeks: 0,
              totalWeeks: _kTotalWeeks,
              totalDiaries: 0,
              totalRelaxations: 0,
            );
        debugPrint(
          'doneCount: ${progressData.completedWeeks}, progress: ${progressData.percent}',
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildProgressCard(progressData),
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
                    joinDaysText(dayCounter, user.createdAt),
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

  Widget _buildProgressCard(_ProgressSnapshot progressData) {
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
                progressData.percentLabel,
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
              value: progressData.percent,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF00AEEF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ProgressChip(
                label: '다이어리',
                value: progressData.totalDiaries.toString(),
              ),
              const SizedBox(width: 8),
              _ProgressChip(
                label: '이완 훈련',
                value: progressData.totalRelaxations.toString(),
              ),
            ],
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
          onTap: () => Navigator.pushNamed(
            context,
            '/before_sud',
            arguments: const {'origin': 'solve', 'diary': 'new'},
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

class _ProgressChip extends StatelessWidget {
  final String label;
  final String value;
  const _ProgressChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTask {
  final String title;
  final bool isDone;
  const _DailyTask({required this.title, required this.isDone});
}
