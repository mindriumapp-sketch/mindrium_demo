// week1_screen.dart
import 'package:flutter/material.dart';

import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/features/1st_treatment/week1_value_goal_screen.dart';
import 'package:gad_app_team/features/menu/education/education_screen.dart';


class Week1Screen extends StatelessWidget {
  const Week1Screen({super.key});

  Future<bool> _hasValueGoal() async {
    try {
      final client = ApiClient(tokens: TokenStorage());
      final userDataApi = UserDataApi(client);
      final response = await userDataApi.getValueGoal();
      final value = response?['value_goal'];
      return value is String && value.toString().trim().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasValueGoal(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 사용자 데이터가 없으면 가치/목표 입력 화면으로
        if (snapshot.data == false) {
          return const Week1ValueGoalScreen();
        }

        // 사용자 데이터가 있으면 기존 교육 페이지로
        return EducationScreen(
          isRelax: true,
        );
      },
    );
  }
}
