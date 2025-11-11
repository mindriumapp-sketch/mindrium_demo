import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class RelaxYesOrNo extends StatelessWidget {
  const RelaxYesOrNo({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId   = args['abcId'] as String?;
    final diary = args['diary'];
    
    return Scaffold(
      appBar: const CustomAppBar(title: '이완 활동 진행'),
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '이완 활동을 진행하시겠어요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // ─── 예 버튼 ────────────────────────────────────────────────
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: 이완 페이지 이동
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
                  textStyle: const TextStyle(fontSize: 24),
                  backgroundColor: Colors.indigo,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('예', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            // ─── 아니오 버튼 ────────────────────────────────────────────
            SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false,);
                },
                style: ElevatedButton.styleFrom(
                  textStyle: const TextStyle(fontSize: 24),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('아니오', style: TextStyle(color: Colors.black)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
