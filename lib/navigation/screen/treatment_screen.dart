// 🌊 Mindrium TreatmentScreen — 로직 담당 (AppBar 없이 TreatmentDesign 호환)
import 'package:flutter/material.dart';

import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/features/1st_treatment/week1_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/week2_screen.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_screen.dart';
import 'package:gad_app_team/features/5th_treatment/week5_screen.dart';
import 'package:gad_app_team/features/6th_treatment/week6_screen.dart';
import 'package:gad_app_team/features/7th_treatment/week7_screen.dart';
import 'package:gad_app_team/features/8th_treatment/week8_screen.dart';

import 'package:gad_app_team/widgets/tap_design_treatment.dart'; // ✅ 새 구조의 디자인 위젯 사용

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  /// 🔹 MongoDB 진행도 프리로드 (UI에서는 결과 사용 X)
  Future<void> _loadUserProgress() async {
    final tokens = TokenStorage();
    final apiClient = ApiClient(tokens: tokens);
    final userDataApi = UserDataApi(apiClient);

    try {
      await userDataApi.getProgress();
    } catch (e) {
      debugPrint('사용자 진행도 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 🌊 주차별 텍스트와 라우팅 (한글/영어 순서로 변경)
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

    /// 🧭 각 주차별 라우팅 화면
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

    /// 🔹 로딩 처리 유지
    return FutureBuilder<void>(
      future: _loadUserProgress(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF87CEEB)),
            ),
          );
        }

        /// ✅ TreatmentDesign 적용 (AppBar 없음)
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: TreatmentDesign(
            appBarTitle: '',
            weekContents: weekContents,
            weekScreens: weekScreens,
          ),
        );
      },
    );
  }
}
