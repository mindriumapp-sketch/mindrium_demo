// 🌊 Mindrium TreatmentScreen — 단일 오픈 + 자동 unlock 반영
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  // ────────────────────────────────
  // Firestore에서 유저 진행도 불러오기
  // ────────────────────────────────
  Future<Map<String, dynamic>> _loadUserProgress(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return {
        'completed': 0,
        'weekByDays': 0,
        'completedWeekSet': <int>{},
        'unlockedWeekSet': <int>{},
      };
    }

    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();

    // 안전한 int 변환
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    final completed = _asInt(data?['completed_education']);
    final userDayCounter = context.read<UserDayCounter>();
    final weekByDays = userDayCounter.daysSinceJoin ~/ 7;

    debugPrint("📥 [TreatmentScreen] Firestore user data: $data");

    // ✅ completed_weeks
    final rawCW = data?['completed_weeks'];
    final Map<String, dynamic> cw = rawCW is Map
        ? rawCW.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    final completedWeekSet = cw.entries
        .where((e) => e.value == true)
        .map((e) => int.tryParse(e.key) ?? 0)
        .where((n) => n > 0 && n <= 8)
        .toSet();

    // ✅ unlocked_weeks
    final rawUW = data?['unlocked_weeks'];
    final Map<String, dynamic> uw = rawUW is Map
        ? rawUW.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    final unlockedWeekSet = uw.entries
        .where((e) => e.value == true)
        .map((e) => int.tryParse(e.key) ?? 0)
        .where((n) => n > 0 && n <= 8)
        .toSet();

    debugPrint("✅ [TreatmentScreen] Completed weeks = $completedWeekSet");
    debugPrint("✅ [TreatmentScreen] Unlocked weeks = $unlockedWeekSet");

    return {
      'completed': completed,
      'weekByDays': weekByDays,
      'completedWeekSet': completedWeekSet,
      'unlockedWeekSet': unlockedWeekSet,
    };
  }

  // ────────────────────────────────
  // 빌드
  // ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final userDayCounter = context.watch<UserDayCounter>();

    final List<Map<String, String>> weekContents = [
      {'title': '1주차', 'subtitle': 'Progressive Relaxation / 불안에 대한 교육'},
      {'title': '2주차', 'subtitle': 'Progressive Relaxation / ABC 모델'},
      {'title': '3주차', 'subtitle': 'Release-only Relaxation / Self Talk'},
      {'title': '4주차', 'subtitle': 'Cue-Controlled Relaxation / 인지 왜곡 찾기'},
      {'title': '5주차', 'subtitle': 'Differential Relaxation / 불안 직면 vs 회피'},
      {'title': '6주차', 'subtitle': 'Differential Relaxation / 불안 직면 vs 회피'},
      {'title': '7주차', 'subtitle': 'Rapid Relaxation / 생활 습관 개선'},
      {'title': '8주차', 'subtitle': 'Rapid Relaxation / 인지 재구성'},
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

        /*
        final List<bool> enabledList = List<bool>.generate(8, (i) {
          final weekNo = i + 1;
          if (completedWeeks.contains(weekNo)) return false;
          if (unlockedWeeks.contains(weekNo)) return true;
          if (weekNo == (lastCompleted + 1)) return true;
          return weekNo == 1; // 첫 주차 기본 오픈
        });
        */
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
