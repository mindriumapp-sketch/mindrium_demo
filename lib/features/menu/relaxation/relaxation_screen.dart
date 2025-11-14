import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/internal_action_button.dart';

import 'dart:ui';

class CardContainer extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final bool useBlur;
  final bool showBorder; // CHANGED: 테두리 on/off 옵션 추가 (기본 false)

  const CardContainer({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.margin,
    this.showShadow = true,
    this.useBlur = true,
    this.showBorder = false, // CHANGED: 기본값 false → 네온 테두리 제거
  });

  static const _lineBlue = Color(0xFFDFFEFF);
  static const _titleNavy = Color(0xFF141F35);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title!,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Noto Sans KR',
                color: _titleNavy,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1.0,
              ),
            ),
          ),
        child,
      ],
    );

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border:
            showBorder
                ? Border.all(width: 3, color: _lineBlue)
                : null, // CHANGED
        boxShadow:
            showShadow
                ? const [
                  // 하얀 글로우
                  BoxShadow(
                    color: Color(0xE8FFFFFF),
                    blurRadius: 30,
                    offset: Offset(0, 0),
                  ),
                  // 은은한 드롭섀도
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: useBlur ? 14 : 0, // CHANGED: 블러 강도 유지
            sigmaY: useBlur ? 14 : 0,
          ),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// 심신 이완 안내 화면
class RelaxationScreen extends StatelessWidget {
  const RelaxationScreen({super.key});

  void showBreathingGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.all(AppSizes.padding),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                children: [
                  const Text(
                    '가이드',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSizes.fontSize,
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: const [
                        Text(
                          '점진적 근육 이완 안내',
                          style: TextStyle(
                            fontSize: AppSizes.fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('각 부위를 4초간 긴장 → 6초간 이완하세요.'),
                        SizedBox(height: AppSizes.space),
                        Text(
                          '1. 팔꿈치 아래 \n주먹을 꼭 쥐고 몸 쪽으로 손목을 굽혀 팔꿈치 아랫부분을 긴장시키세요.',
                        ),
                        SizedBox(height: AppSizes.space),
                        Text('2. 팔꿈치 윗부분 \n손끝을 어깨에 올려 이두 부위를 최대한 접어 긴장시키세요.'),
                        SizedBox(height: AppSizes.space),
                        Text('3. 무릎 아래 \n다리를 들어 발끝을 몸 쪽으로 당겨 종아리를 긴장시키세요.'),
                        SizedBox(height: AppSizes.space),
                        Text('4. 배 \n배를 안으로 강하게 조이며 긴장시켜 주세요.'),
                        SizedBox(height: AppSizes.space),
                        Text('5. 가슴 \n깊게 숨을 들이쉬고 숨을 참아 가슴 근육을 당기세요.'),
                        SizedBox(height: AppSizes.space),
                        Text('6. 어깨 \n어깨를 귀 쪽으로 올려 긴장시켜 주세요.'),
                        SizedBox(height: AppSizes.space),
                        Text('7. 목 \n턱을 가슴 쪽으로 당겨 목 뒤를 당기세요.'),
                        SizedBox(height: AppSizes.space),
                        Text('8. 얼굴 \n입술을 다물고 눈을 감은 채 얼굴 전체에 힘을 주세요.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  SizedBox(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color.from(
                          alpha: 1,
                          red: 0.247,
                          green: 0.318,
                          blue: 0.71,
                        ),
                        fixedSize: const Size(144, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadius,
                          ),
                        ),
                      ),
                      child: const Text(
                        '닫기',
                        style: TextStyle(color: AppColors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    debugPrint('RelaxationScreen - abcId: $abcId, diary: ${args['diary']}');
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: const CustomAppBar(title: '이완 활동'),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            CardContainer(
              title: '가이드',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      '호흡은 규칙적이고, 온몸은 이완되며 편안함을 느낍니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.grey),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  const Text(
                    '호몸의 각 부위를 차례로 긴장시켰다가 이완해봅니다.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: AppSizes.fontSize,
                    ),
                  ),
                  const Text(
                    '약 3분 소요됩니다.',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: AppSizes.fontSize,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => showBreathingGuideDialog(context),
                      child: const Text('자세히 보기'),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  Center(
                    child: InternalActionButton(
                      onPressed:
                          () => Navigator.pushNamed(
                            context,
                            '',
                            arguments: {
                              "abcId": abcId,
                              'diary': args['diary'],
                              'origin': args['origin'],
                            },
                          ),
                      text: '시작하기',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
