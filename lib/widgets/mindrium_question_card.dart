import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

/// Mindrium 질문 카드 — A/B/C 단계 공통 스타일
class MindriumQuestionCard extends StatelessWidget {
  final String stepLabel; // 예: 'A 상황', 'B 생각', 'C 결과'
  final String subtitle;
  final String question;
  final Widget? bottom; // 칩, 입력칸 등

  const MindriumQuestionCard({
    super.key,
    required this.stepLabel,
    required this.subtitle,
    required this.question,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const Image(
          image: AssetImage('assets/image/eduhome.png'),
          fit: BoxFit.cover,
        ),
        Container(
          color: AppColors.white.withValues(alpha: 0.1), // 살짝 밝게
        ),
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.padding * 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 단계 헤더
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.indigo100, AppColors.indigo],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppSizes.borderRadius),
                        topRight: Radius.circular(AppSizes.borderRadius),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.indigo.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      stepLabel,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 20,
                        fontFamily: 'Noto Sans KR',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.space),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.indigo,
                      fontSize: 13,
                      fontFamily: 'Noto Sans KR',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.black,
                      fontSize: 22,
                      fontFamily: 'Noto Sans KR',
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (bottom != null) ...[const SizedBox(height: 20), bottom!],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
