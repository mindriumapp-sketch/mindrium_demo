import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';

class AltYesOrNo extends StatelessWidget {
  const AltYesOrNo({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    final dynamic rawOrigin = args['origin'];
    final String origin = rawOrigin is String ? rawOrigin : 'apply';

    return InnerBtnCardScreen(
      appBarTitle: '대체 생각 진행',
      title: '대체 생각을 작성하시겠어요?',
      backgroundAsset: 'assets/image/eduhome.png',
      primaryText: '예',
      onPrimary: () {
        Navigator.pushNamed(
          context,
          '/apply_alt_thought',
          arguments: {
            'taskId': abcId,
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
            '예를 누르면 대체 생각 페이지로 넘어가요!\n 아니오를 누르면 홈으로 돌아가요!',
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
