import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gad_app_team/utils/text_line_utils.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:provider/provider.dart';
import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/today_task_provider.dart';

import 'package:gad_app_team/navigation/navigation.dart';
import 'package:gad_app_team/features/menu/archive/sea_archive_page.dart';
import 'package:gad_app_team/navigation/screen/myinfo_screen.dart';
import 'package:gad_app_team/navigation/screen/treatment_screen.dart';
import 'package:gad_app_team/features/1st_treatment/week1_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/week2_screen.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_screen.dart';
import 'package:gad_app_team/features/5th_treatment/week5_screen.dart';
import 'package:gad_app_team/features/6th_treatment/week6_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_screen.dart';
import 'package:gad_app_team/features/8th_treatment/week8_screen.dart';
import 'package:gad_app_team/data/apply_solve_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _ProgressSnapshot {
  final int currentWeek;
  final int completedWeeks;
  final int totalWeeks;
  final int totalDiaries;
  final int totalRelaxations;

  const _ProgressSnapshot({
    required this.currentWeek,
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

  bool _permissionsChecked = false;
  Future<void>? _permissionFuture;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    // ✅ HomeScreen에서는 Provider 데이터 로딩/refresh 안 함
    //    - Splash/Login에서 이미 다 해줬다고 가정
    Future.microtask(() async {
      await _ensureCorePermissions();
    });
  }

  // ===================== 진행도: UserProvider에서만 읽기 =====================

  _ProgressSnapshot _buildProgressFromUser(UserProvider user) {
    // last_completed_week → 0~_kTotalWeeks 로 정규화
    var completedWeeks = user.lastCompletedWeek;
    if (completedWeeks < 0) completedWeeks = 0;
    if (completedWeeks > _kTotalWeeks) completedWeeks = _kTotalWeeks;

    final totalDiaries = user.totalDiaries;
    final totalRelaxations = user.totalRelaxations;
    final currentWeek = user.currentWeek; // 서버 계산 값 그대로 사용

    return _ProgressSnapshot(
      currentWeek: currentWeek,
      completedWeeks: completedWeeks,
      totalWeeks: _kTotalWeeks,
      totalDiaries: totalDiaries,
      totalRelaxations: totalRelaxations,
    );
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

  // ===================== build =====================

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

  // ===================== 권한 처리 =====================

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
      if (!await perm.isGranted) {
        await perm.request();
      }
    }

    _permissionsChecked = true;
  }

  // ===================== 홈 탭 =====================

  Widget _homePage() {
    final user = context.watch<UserProvider>();
    final todayTask = context.watch<TodayTaskProvider>();

    // 1️⃣ 홈에 필요한 최소 데이터가 아직 로딩 중일 때 → 로딩 스피너
    if ((user.isLoadingUser && !user.isUserLoaded) ||
        (todayTask.isLoading && !todayTask.isLoaded)) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2️⃣ 로딩은 끝났는데, 아직 한 번도 제대로 못 불러온 상태에서 에러 → 에러 메시지
    if ((user.hasError && !user.isUserLoaded) ||
        (todayTask.hasError && !todayTask.isLoaded)) {
      return const Center(child: Text('홈 정보를 불러오지 못했어요.'));
    }

    // 3️⃣ 여기까지 왔으면 최소 한 번은 유저 + todayTask가 로딩된 상태
    final progressData = _buildProgressFromUser(user);

    debugPrint(
      'currentWeek: ${progressData.currentWeek}, '
          'doneCount: ${progressData.completedWeeks}, '
          'progress: ${progressData.percent}',
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
  }

  // ===================== 헤더 =====================

  Widget _buildHeader() {
    final user = context.watch<UserProvider>();
    final dayCounter = context.watch<UserDayCounter>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// 👤 왼쪽: 사용자 인사 + 가입일
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 💬 “안녕하세요,\nOOO님 환영합니다!”
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
                  softWrap: false,
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
                color: Colors.black.withValues(alpha: 0.1),
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

  // ===================== 진행도 카드 =====================

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

  // ===================== 오늘의 할 일 =====================

  Widget _buildTaskSection() {
    final todayTask = context.watch<TodayTaskProvider>();
    final navigator = Navigator.of(context);

    final user = context.read<UserProvider>();
    final weekNumber = user.currentWeek;

    final List<Widget> weekScreens = const [
      Week1Screen(),
      Week2Screen(),
      Week3Screen(),
      Week4Screen(),
      Week5Screen(),
      Week6Screen(),
      Week7Screen(),
      Week8Screen(),
    ];

    final List<_DailyTask> todayTasks = [
      _DailyTask(
        title: '일기 작성',
        isDone: todayTask.diaryDone,
        onTap: () {
          Navigator.pushNamed(
            context,
            '/abc',
            arguments: {
              'origin': 'daily',
              'abcId': null,
            },
          );
        },
      ),
      _DailyTask(
        title: '이완',
        isDone: todayTask.relaxationDone,
        onTap: () {
          // weekNumber 기반으로 taskId / asset 이름들 구성
          final taskId = 'week${weekNumber}_daily';
          final mp3Asset = 'week$weekNumber.mp3';
          final riveAsset = 'week$weekNumber.riv';

          navigator.pushNamed(
            '/relaxation_noti',
            arguments: {
              'taskId': taskId,
              'weekNumber': weekNumber,
              'mp3Asset': mp3Asset,
              'riveAsset': riveAsset,
              'nextPage': '/home',
            },
          );
        },
      ),
      _DailyTask(
        title: '교육',
        isDone: todayTask.educationDoneWeek,
        onTap: () {
          final user = context.read<UserProvider>();
          var weekNumber = user.currentWeek; // 1~8이라고 가정

          // 안전하게 인덱스 계산
          var index = weekNumber - 1;
          if (index < 0) index = 0;
          if (index >= weekScreens.length) {
            index = weekScreens.length - 1;
          }

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => weekScreens[index],
            ),
          );
        },
      ),
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

    return InkWell(
      onTap: task.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
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
      ),
    );
  }

  // ===================== 교육/훈련 섹션 =====================

  Widget _buildTrainingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _trainingCard(
          title: '불안 해결하기',
          description: '오늘 불안하신 상황이 있으셨나요? 지금 오늘의 활동을 시작해보세요.',
          color: const Color(0xFFFFE2E8),
          imagePath: 'assets/image/pink2.png',
          onTap: () {
            final flow = context.read<ApplyOrSolveFlow>();
            // 기존 상태 초기화 후 solve 흐름 세팅
            flow.clear();
            flow.setOrigin('solve');
            Navigator.pushNamed(
              context,
              '/before_sud',
              arguments: {
                ...flow.toArgs(),
                'origin': 'solve',
              },
            );
          },
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
                    protectKoreanWords(description),
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

// ===================== 서브 위젯 =====================

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
            color: Colors.black.withValues(alpha: 0.07),
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
  final VoidCallback? onTap;

  const _DailyTask({
    required this.title,
    required this.isDone,
    this.onTap,
  });
}
