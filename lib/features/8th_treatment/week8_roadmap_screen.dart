// File: features/8th_treatment/week8_roadmap_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/data/user_data_storage.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/features/8th_treatment/week8_planning_check_screen.dart';

class Week8RoadmapScreen extends StatefulWidget {
  const Week8RoadmapScreen({super.key});

  @override
  State<Week8RoadmapScreen> createState() => _Week8RoadmapScreenState();
}

class _Week8RoadmapScreenState extends State<Week8RoadmapScreen> {
  String _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userName = await UserDataStorage.getUserName();
      setState(() {
        _userName = userName ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ApplyDesign(
      appBarTitle: '8주차 - 여정 로드맵',
      cardTitle: '8주간의 여정 되돌아보기',
      onBack: () => Navigator.pop(context),
      onNext:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Week8PlanningCheckScreen(),
            ),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 28),

          // 주차별 카드 리스트
          ...List.generate(8, (i) {
            final week = i + 1;
            final data = _getWeekData(week);
            return _buildWeekCard(week, data['title']!, data['description']!);
          }),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  /// 상단 헤더
  Widget _buildHeaderSection() {
    return Column(
      children: [
        Text(
          _userName.isNotEmpty ? '$_userName님의 8주간 여정' : '8주간의 여정',
          style: const TextStyle(
            fontFamily: 'NotoSansKR',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B3A57),
          ),
        ),
        const SizedBox(height: 16),
        JellyfishBanner(message: '8주간의 Mindrium 훈련을 \n함께 되돌아봅시다 🌊'),
      ],
    );
  }

  /// 주차별 카드 디자인 (ApplyDesign 내부에서 쓸 수 있는 수준의 경량 디자인)
  Widget _buildWeekCard(int week, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9EAFD), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74D2FF).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekIcon(week),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B3A57),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF356D91),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 주차 번호 아이콘 (디자인 전용 로컬 위젯)
  Widget _buildWeekIcon(int week) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF74D2FF), Color(0xFF99E0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74D2FF).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '$week',
          style: const TextStyle(
            fontFamily: 'NotoSansKR',
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
    );
  }

  Map<String, String> _getWeekData(int week) {
    switch (week) {
      case 1:
        return {'title': '1주차: 불안에 대한 교육', 'description': '가치를 돌아보고 불안을 이해하기'};
      case 2:
        return {
          'title': '2주차: ABC 모델',
          'description': '걱정일기 작성, 알림 설정, 그룹 분류하기',
        };
      case 3:
        return {
          'title': '3주차: Self Talk',
          'description': '도움이 되는 생각과 그렇지 않은 생각 구분하기',
        };
      case 4:
        return {
          'title': '4주차: 인지 왜곡 찾기',
          'description': '생각을 점검하고 현실적인 관점 연습하기',
        };
      case 5:
        return {
          'title': '5주차: 불안 직면 vs 회피',
          'description': '행동이 직면인지 회피인지 구분하기',
        };
      case 6:
        return {'title': '6주차: 실전 구분 연습', 'description': '걱정일기 속 행동을 분석해보기'};
      case 7:
        return {'title': '7주차: 건강한 생활 습관', 'description': '한 주간 실천할 습관 세우기'};
      case 8:
        return {'title': '8주차: 인지 재구성', 'description': '인지 재구성 연습하기'};
      default:
        return {'title': '', 'description': ''};
    }
  }
}
