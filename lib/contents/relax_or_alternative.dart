// 🔹 Mindrium: 다음 단계 선택 화면 (RelaxOrAlternativePage)
// 사용자가 불안 평가(SUD) 이후, 다음으로 ‘이완 활동’을 할지 ‘대체 생각 작성’을 할지 선택하는 분기 화면
// 연결 흐름:
//   BeforeSudRatingScreen → RelaxOrAlternativePage
//     ├─ “이완 활동” → /relaxation_noti (이완 오디오 재생 화면)
//     └─ “대체 생각 작성” → /apply_alt_thought (대체 사고 적용 화면)
// import 목록:
//   dart:math                        → 이미지 크기 제한용 math.min()
//   flutter/material.dart            → 기본 Flutter 위젯
//   gad_app_team/widgets/custom_appbar.dart → 상단 공용 CustomAppBar (AppBar용)
//   gad_app_team/widgets/inner_btn_card.dart → 카드형 2버튼 UI(InnerBtnCardScreen) 사용

import 'dart:math' as math;
import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';
import 'package:gad_app_team/data/apply_solve_provider.dart';
import 'package:provider/provider.dart';

class RelaxOrAlternativePage extends StatelessWidget {
  const RelaxOrAlternativePage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final flow = context.read<ApplyOrSolveFlow>()..syncFromArgs(args, notify: false);
    final String? abcId = flow.diaryId ?? args['abcId'] as String?;
    final String? sudId = flow.sudId ?? args['sudId'] as String?;
    final int? beforeSud = flow.beforeSud ?? args['beforeSud'] as int?;
    final dynamic diary = args['diary'] ?? flow.diary;
    final dynamic rawOrigin = args['origin'];
    final String origin = rawOrigin is String ? rawOrigin : flow.origin;

    return InnerBtnCardScreen(
      appBarTitle: '다음 단계 선택',
      title: '어떤 활동을 진행하시겠어요?',
      backgroundAsset: 'assets/image/eduhome.png',
      primaryText: '이완 활동',
      onPrimary: () {
        Navigator.pushNamed(
          context,
          '/relaxation_noti',
          arguments: {
            ...flow.toArgs(),
            'taskId': abcId,
            'mp3Asset': 'noti.mp3',
            'riveAsset': 'noti.riv',
            'nextPage': '/relaxation_score',
            'diary': diary,
            'origin': origin,
            'beforeSud': beforeSud,
            'sudId': sudId,
          },
        );
      },
      secondaryText: '대체 생각 작성',
      onSecondary: () {
        debugPrint(
          '[relax_or_alternative] abcId=$abcId, sud=$beforeSud, diary=$diary',
        );
        Navigator.pushNamed(
          context,
          '/apply_alt_thought',
          arguments: {
            ...flow.toArgs(),
            'abcId': abcId,
            'beforeSud': beforeSud,
            'sudId': sudId,
            'origin': origin,
            if (diary != null) 'diary': diary,
          },
        );
      },
      // 카드 안 본문
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Image.asset(
            'assets/image/pink3.png',
            height: math.min(180, MediaQuery.of(context).size.width * 0.38),
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
