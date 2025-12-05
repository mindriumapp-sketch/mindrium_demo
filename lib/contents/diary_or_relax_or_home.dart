// 🔹 Mindrium: SUD 이후 단계 선택 화면 (DiaryOrRelaxOrHome)
// 사용자가 SUD 평가를 마친 뒤 다음 활동을 선택하는 화면
// 연결 흐름:
//   BeforeSudRatingScreen  →  DiaryOrRelaxOrHome
//     ├─ “다른 걱정에 집중해보기” → /diary_select (새 일기 작성)
//     ├─ “이완 활동 하기” → /relaxation_noti (이완 오디오 재생 화면)
//     └─ “홈” → /home (메인 화면으로 복귀)
// import 목록:
//   flutter/material.dart               → 기본 Flutter 위젯
//   gad_app_team/widgets/custom_appbar.dart → 상단 공용 CustomAppBar 사용

import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';
import 'package:gad_app_team/data/apply_solve_provider.dart';
import 'package:provider/provider.dart';

class DiaryOrRelaxOrHome extends StatelessWidget {
  const DiaryOrRelaxOrHome({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final flow = context.read<ApplyOrSolveFlow>()..syncFromArgs(args, notify: false);
    final String? groupId = flow.groupId ?? args?['groupId'] as String?;
    final int? beforeSud = flow.beforeSud ?? args?['beforeSud'] as int?;
    final String? sudId = flow.sudId ?? args?['sudId'] as String?;

    return InnerBtnCardScreen(
      appBarTitle: '다음 단계 선택',
      title: '어떤 활동을 진행하시겠어요?',
      primaryText: '이완 활동 하기',
      secondaryText: '홈으로 돌아가기',
      feedback: '필요하다면 다른 걱정에도 다시 집중해볼 수 있어요.',
      onPrimary: () {
        // relaxation 화면 이동
        Navigator.pushNamed(
          context,
          '/relaxation_noti',
          arguments: {
            ...flow.toArgs(),
            'taskId': groupId,
            'mp3Asset': 'noti.mp3',
            'riveAsset': 'noti.riv',
            'nextPage': '/relaxation_score',
            'origin': 'apply',
            'beforeSud': beforeSud,
            'sudId': sudId,
          },
        );
      },
      onSecondary: () {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      },
      child: Column(
        children: [
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/diary_select',
                  arguments: {'groupId': groupId, 'beforeSud': beforeSud},
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF47A6FF), width: 2.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                '다른 걱정에 집중해보기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Noto Sans KR',
                  color: Color(0xFF47A6FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
