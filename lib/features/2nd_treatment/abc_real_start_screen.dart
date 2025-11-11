import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_input_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';

/// 🌊 Mindrium ApplyDesign 스타일로 리디자인된 실제 작성 시작 화면
class AbcRealStartScreen extends StatelessWidget {
  const AbcRealStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '2주차 - ABC 모델',
      cardTitle: '잘하셨어요!',
      onBack: () {
        Navigator.pop(context);
      },
      onNext: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AbcInputScreen(showGuide: false),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note, size: 68, color: AppColors.indigo),
          const SizedBox(height: 24),
          const Text(
            '실제로 작성해볼까요?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            '이제 실제로 나의 사례를 떠올리며\n걱정일기를 작성해보세요.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.6,
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),

          /// 🪶 작성하기 버튼
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AbcInputScreen(showGuide: false),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Sans KR',
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('작성하기'),
            ),
          ),

          const SizedBox(height: 20),

          /// 💡 안내문
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.indigo.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.indigo,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '실제 사례를 적으며 나만의 패턴을 이해해보세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.indigo,
                      height: 1.4,
                      fontFamily: 'Noto Sans KR',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
