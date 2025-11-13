import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:gad_app_team/features/menu/archive/sea_archive_page.dart';
import 'package:gad_app_team/navigation/navigation.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'treatment_screen.dart';
import 'myinfo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  static const int _kTotalWeeks = 8;
  Future<int>? _completedWeeksFuture;
  bool _permissionsChecked = false;
  Position? _currentPosition;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final UserDataApi _userDataApi = UserDataApi(_apiClient);

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _ensureCorePermissions();
      if (!mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final dayCounter = Provider.of<UserDayCounter>(context, listen: false);
      userProvider.loadUserData(dayCounter: dayCounter);
      _completedWeeksFuture ??= _loadCompletedWeeks();
      await _fetchCurrentPosition();
    });
  }

  void _onDestinationSelected(int index) =>
      setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // ✅ 배경: eduhome.png + 반투명 오버레이 (터치 방해 없음)
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

          // ✅ 실제 내용
          SafeArea(child: _buildBody()),

          // ✅ 네비게이션 바
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

  Future<int> _loadCompletedWeeks() async {
    // 2025-11-13 MongoDB 진행도 API로 교체
    final access = await _tokens.access;
    if (access == null) return 0;
    try {
      final progress = await _userDataApi.getProgress();
      final weekProgress = progress['week_progress'];
      if (weekProgress is List) {
        return weekProgress
            .where(
              (w) =>
                  w is Map<String, dynamic> && (w['completed'] as bool? ?? false),
            )
            .length;
      }
      return 0;
    } catch (e) {
      debugPrint('교육 주차 로드 실패: $e');
      return 0;
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

  Future<void> _fetchCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() => _currentPosition = pos);
    } catch (e) {
      debugPrint("위치 정보 가져오기 실패: $e");
    }
  }

  Widget _homePage() {
    final completedWeeksFuture =
        _completedWeeksFuture ??= _loadCompletedWeeks();

    return FutureBuilder<int>(
      future: completedWeeksFuture,
      builder: (context, snapshot) {
        final completed = snapshot.data ?? 0;
        final progress = completed / _kTotalWeeks;
        final percentLabel = '${(progress * 100).round()}%';

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

                /// 📍 위치 표시
                if (_currentPosition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '📍 ${_currentPosition!.latitude.toStringAsFixed(3)}, ${_currentPosition!.longitude.toStringAsFixed(3)}',
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
          title: '훈련하기',
          description: '프로그램에서 배운 내용을 연습해요',
          color: const Color(0xFFFFC9D3),
          imagePath: 'assets/image/pink1.png',
          onTap: () => Navigator.pushNamed(context, '/training'),
        ),
        const SizedBox(height: 12),
        _trainingCard(
          title: '적용하기',
          description: '실제 상황에 맞춘 불안 관리를 적용해요',
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
