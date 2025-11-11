import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class RelaxOrAlternativePage extends StatelessWidget {
  const RelaxOrAlternativePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId   = args['abcId'] as String?;
    final int? sud   = args['sud'] as int?;
    final dynamic diary = args['diary'];

    return Scaffold(
      appBar: const CustomAppBar(title: '다음 단계 선택'),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '어떤 활동을 진행하시겠어요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            // ─── 이완 활동 버튼 ───────────────────────────────────────
            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: ㅜㅜ 세현님..ㅜㅜ
                  Navigator.pushNamed(
                    context,
                    '/relaxation_noti',
                    arguments: {
                      'taskId': abcId,
                      'weekNumber': 4,
                      'mp3Asset': 'noti.mp3',
                      'riveAsset': 'noti.riv',
                      'nextPage': '/relaxation_score',
                      'diary': diary,
                      'origin': 'apply'
                    }
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 22),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('이완 활동', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            // ─── 대체 생각 작성 버튼 ─────────────────────────────────
            SizedBox(
              width: 220,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('[relax_or_alternative] abcId=$abcId, sud=$sud, diary=$diary');
                  Navigator.pushNamed(
                    context,
                    '/apply_alt_thought',
                    arguments: {
                      'abcId': abcId,
                      'sud': sud,
                      if(diary != null) 'diary': diary
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 22),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('대체 생각 작성',
                    style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
