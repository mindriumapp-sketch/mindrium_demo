// 🌊 Mindrium TreatmentScreen — 단일 오픈 + 자동 unlock 반영
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/daycounter.dart';
import 'package:gad_app_team/features/1st_treatment/week1_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/week2_screen.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_screen.dart';
import 'package:gad_app_team/features/5th_treatment/week5_screen.dart';
import 'package:gad_app_team/features/6th_treatment/week6_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_screen.dart';
import 'package:gad_app_team/features/8th_treatment/week8_screen.dart';

import 'package:gad_app_team/widgets/tap_design_treatment.dart'; // ✅ 디자인 위젯
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  Future<Map<String, dynamic>> _loadUserProgress(BuildContext context) async {
    final userDayCounter = context.read<UserDayCounter>();
    final tokens = TokenStorage();
    final client = ApiClient(tokens: tokens);
    final userDataApi = UserDataApi(client);

    try {
      final data = await userDataApi.getProgress();
      final weekProgress = (data['week_progress'] as List?) ?? [];
      final completedWeeks = <int>{};
      final unlockedWeeks = <int>{};

      for (final entry in weekProgress) {
        if (entry is! Map) continue;
        final weekNumber = entry['week_number'];
        if (weekNumber is! int) continue;
        if (entry['completed'] == true) {
          completedWeeks.add(weekNumber);
        }
        if ((entry['progress_percent'] ?? 0) is num &&
            (entry['progress_percent'] as num) > 0) {
          unlockedWeeks.add(weekNumber);
        }
      }

      final currentWeek = data['current_week'] is int ? data['current_week'] as int : 1;
      for (int i = 1; i <= currentWeek; i++) {
        unlockedWeeks.add(i);
      }
      if (unlockedWeeks.isEmpty) unlockedWeeks.add(1);

      final weekByDays = userDayCounter.daysSinceJoin ~/ 7;

      return {
        'weekByDays': weekByDays,
        'completedWeekSet': completedWeeks,
        'unlockedWeekSet': unlockedWeeks,
      };
    } catch (e) {
      debugPrint('⚠️ [TreatmentScreen] 사용자 진행도 불러오기 실패: $e');
      return {
        'weekByDays': userDayCounter.daysSinceJoin ~/ 7,
        'completedWeekSet': <int>{},
        'unlockedWeekSet': <int>{1},
      };
    }
  }

  // ────────────────────────────────
  // 빌드
  // ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userDayCounter = context.watch<UserDayCounter>();

    final List<Map<String, String>> weekContents = [
      {'title': '1주차', 'subtitle': '점진적 이완 / 불안에 대한 교육'},
      {'title': '2주차', 'subtitle': '점진적 이완 / ABC 모델'},
      {'title': '3주차', 'subtitle': '이완만 하는 이완 / Self Talk'},
      {'title': '4주차', 'subtitle': '신호 조절 이완 / 인지 왜곡 찾기'},
      {'title': '5주차', 'subtitle': '차등 이완 / 불안 직면 vs 회피'},
      {'title': '6주차', 'subtitle': '차등 이완 / 불안 직면 vs 회피'},
      {'title': '7주차', 'subtitle': '신속 이완 / 생활 습관 개선'},
      {'title': '8주차', 'subtitle': '신속 이완 / 인지 재구성'},
    ];

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

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadUserProgress(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !userDayCounter.isUserLoaded) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator(color: Color(0xFF87CEEB))),
          );
        }

        final completedWeeks = (snapshot.data!['completedWeekSet'] as Set<int>) ?? <int>{};
        final unlockedWeeks = (snapshot.data!['unlockedWeekSet'] as Set<int>) ?? <int>{};
        final weekByDays = snapshot.data!['weekByDays'] as int? ?? 0;

        int lastCompleted = completedWeeks.isEmpty
            ? 0
            : completedWeeks.reduce((a, b) => a > b ? a : b);
        final candidateByDone = lastCompleted + 1;
        final candidateByDays = (weekByDays + 1).clamp(1, 8);
        final int currentOpenWeek =
            candidateByDone <= candidateByDays ? candidateByDone : candidateByDays;
        final int clampedOpenWeek = currentOpenWeek.clamp(1, 8);


        // final List<bool> enabledList = List<bool>.generate(8, (i) {
        //   final weekNo = i + 1;
        //   if (completedWeeks.contains(weekNo)) return false;
        //   if (unlockedWeeks.contains(weekNo)) return true;
        //   if (weekNo == (lastCompleted + 1)) return true;
        //   return weekNo == 1; // 첫 주차 기본 오픈
        // });

        //[잠금/해제 활성화] 위 주석 부분을 해제 & 바로 아랫줄 enableList선언부 주석처리하시면 됩니다
        final List<bool> enabledList = List<bool>.filled(weekContents.length, true);

        debugPrint("🟦 [TreatmentScreen] weekByDays=$weekByDays, "
            "lastCompleted=$lastCompleted, currentOpenWeek=$clampedOpenWeek");
        debugPrint("🟦 [TreatmentScreen] enabledList=$enabledList");
        debugPrint("✅ [TreatmentScreen] completedWeeks 전달 값 = $completedWeeks");
        debugPrint("✅ [TreatmentScreen] unlockedWeeks 전달 값 = $unlockedWeeks");

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: TreatmentDesign(
            appBarTitle: '',
            weekContents: weekContents,
            weekScreens: weekScreens,
            enabledList: enabledList,
            completedWeeks: completedWeeks,
          ),
        );
      },
    );
  }
}
