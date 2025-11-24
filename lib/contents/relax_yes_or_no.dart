// 🔹 Mindrium: 이완 활동 진행 여부 확인 화면 (RelaxYesOrNo)
// DiaryYesOrNo와 동일한 InnerBtnCardScreen 기반 디자인 적용
// 사용자가 ‘이완 활동’을 지금 진행할지 여부를 선택하는 간단한 분기 화면
// 연결 흐름:
//   RelaxOrAlternativePage → RelaxYesOrNo
//     ├─ “예” → /relaxation_noti (이완 오디오 재생 화면)
//     └─ “아니오” → /home (메인 홈 화면)
// import 목록:
//   dart:math                        → 이미지 크기 제한용 math.min()
//   flutter/material.dart            → 기본 Flutter 위젯
//   gad_app_team/widgets/inner_btn_card.dart → 카드형 2버튼 UI 위젯

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';

class RelaxYesOrNo extends StatelessWidget {
  const RelaxYesOrNo({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    final diary = args['diary'];
    final dynamic rawOrigin = args['origin'];
    final String origin = rawOrigin is String ? rawOrigin : 'apply';

    return InnerBtnCardScreen(
      appBarTitle: '이완 활동 진행',
      title: '이완 활동을 진행하시겠어요?',
      backgroundAsset: 'assets/image/eduhome.png',
      primaryText: '예',
      onPrimary: () {
        Navigator.pushNamed(
          context,
          '/relaxation_noti',
          arguments: {
            'taskId': abcId,
            'mp3Asset': 'noti.mp3',
            'riveAsset': 'noti.riv',
            'nextPage': '/relaxation_score',
            'diary': diary,
            'origin': origin,
          },
        );
      },
      // “아니오” 버튼 → 홈 복귀
      secondaryText: '아니오',
      onSecondary: () {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      },
      // 카드 내부 본문
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Image.asset(
            'assets/image/pink3.png',
            height: math.min(180, MediaQuery.of(context).size.width * 0.38),
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          const Text(
            '예를 누르면 이완 활동 페이지로 넘어가요!\n 아니오를 누르면 홈으로 돌아가요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w200,
              color: Color(0xFF626262),
              height: 1.8,
              wordSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
