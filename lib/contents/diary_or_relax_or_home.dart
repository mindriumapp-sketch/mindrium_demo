import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class DiaryOrRelaxOrHome extends StatelessWidget {
  const DiaryOrRelaxOrHome({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    // final String? abcId   = args?['abcId']   as String?;
    final String? groupId = args?['groupId'] as String?;
    final int? sud = args?['sud'] as int?;

    return Scaffold(
      appBar: const CustomAppBar(title: '다음 단계 선택'),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '어떤 활동을 진행하시겠어요??',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/diary_select',
                    arguments: {
                      'groupId': groupId,
                      'sud': sud,
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 24),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '다른 걱정에 집중해보기',
                  style: TextStyle(
                    color: Colors.white
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: ()  {
                  // TODO: 세현님 도움 필요.....일단 4주차 고정..
                  Navigator.pushNamed(
                    context, 
                    '/relaxation_noti',
                    arguments: {
                      'taskId': groupId, // 임시..
                      'weekNumber': 4, // 임시..
                      'mp3Asset': 'noti.mp3',
                      'riveAsset': 'noti.riv',
                      'nextPage': '/relaxation_score',
                      'origin': 'apply'
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 24),
                  backgroundColor: Colors.indigo.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '이완 활동 하기',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 300,
              height: 60,
              child: ElevatedButton(
                onPressed: ()  {
                  Navigator.pushNamedAndRemoveUntil(context, '/home',  (_) => false);
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 24),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '홈',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}