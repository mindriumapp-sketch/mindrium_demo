import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';

// ✅ 튜토리얼 공용 디자인: 배경/카드/네비게이션 포함
import 'package:gad_app_team/widgets/tutorial_design.dart';

// ✅ 커스텀 팝업 디자인
import 'package:gad_app_team/widgets/custom_popup_design.dart';

class Week4FinishScreen extends StatelessWidget {
  final int? beforeSud;
  final int? afterSud;
  final List<String>? alternativeThoughts;
  final bool? isFromAfterSud;
  final int? loopCount;

  const Week4FinishScreen({
    super.key,
    this.beforeSud,
    this.afterSud,
    this.alternativeThoughts,
    this.isFromAfterSud,
    this.loopCount,
  });

  bool get _reduced =>
      (isFromAfterSud == true) &&
          (beforeSud != null) &&
          (afterSud != null) &&
          (beforeSud! > afterSud!);

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 기존 문구 그대로 유지
    final String successText =
        '축하합니다! 불안의 정도가 $beforeSud에서 $afterSud로 낮아졌네요.\n'
        '도움이 되는 생각을 찾아보는 과정을 통해 불안을 줄이는데 성공하셨습니다.';

    final String encourageText =
        '아직 불안의 정도가 충분히 낮아지지 않았네요.\n'
        '하지만 여기까지 잘 따라와 주신 것만으로도 정말 대단하세요.';

    final String footerText =
        '도움이 되는 생각을 찾는 과정이 처음에는 쉽지 않을 수 있어요.\n'
        '조금 더 연습하고, 내 마음을 들여다보는 시간을 가져보면 분명 불안이 줄어들 수 있습니다.\n\n'
        '고생하셨습니다.';

    return ApplyDesign(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      cardTitle: '불안 완화 결과',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        // ⛳ 팝업을 커스텀 디자인으로 교체 (로직 동일: 닫히면 다음 화면으로 이동)
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => CustomPopupDesign(
            title: '이완 음성 안내 시작',
            message: '잠시 후, 이완을 위한 음성 안내가 시작됩니다.\n주변 소리와 음량을 조절해보세요.',
            positiveText: '확인',
            onPositivePressed: () => Navigator.of(ctx).pop(),
            negativeText: null,           // ✅ 취소 숨김
            onNegativePressed: null,      // ✅ 필요 없음
            // backgroundAsset: 'assets/image/popup_bg.png',
            // iconAsset: 'assets/image/jellyfish_smart.png',
          ),
        );

        Navigator.pushReplacementNamed(
          context,
          '/relaxation_education',
          arguments: {
            'taskId': 'edu_0004',
            'weekNumber': 4,
            'mp3Asset': 'week4.mp3',
            'riveAsset': 'week4.riv',
          },
        );
      },

      // 💠 카드 내부 UI (이름/구분선/결과문구 유지)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/image/congrats.png',
            height: 160,
            filterQuality: FilterQuality.high,
          ),

          // 결과 메시지 (조건 동일)
          Text(
            _reduced ? successText : encourageText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.5,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 32),

          // 추가 안내
          Text(
            footerText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.5,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
