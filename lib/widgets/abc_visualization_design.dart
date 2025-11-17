import 'package:flutter/material.dart';
import '../widgets/memo_sheet_design.dart'; // ✅ 기존 유지

class DesignPalette {
  static const Color blue = Color(0xFF87CEEB);
  static const Color pink = Color(0xFFFFB5A7);
  static const Color mint = Color(0xFF7FD8B3);
  static const Color textBlack = Color(0xFF232323);

  static const TextStyle contentText = TextStyle(
    color: textBlack,
    fontSize: 14.5,
    fontFamily: 'Noto Sans KR',
    height: 1.5,
    letterSpacing: 0.3,
  );
}

class AbcVisualizationDesign extends StatelessWidget {
  final bool showFeedback;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Widget feedbackWidget;
  final Widget visualizationWidget;

  const AbcVisualizationDesign({
    super.key,
    required this.showFeedback,
    required this.isSaving,
    required this.onBack,
    required this.onNext,
    required this.feedbackWidget,
    required this.visualizationWidget,
  });

  @override
  Widget build(BuildContext context) {
    final titleText = '2주차 - ABC 모델';
    final content = showFeedback ? feedbackWidget : visualizationWidget;

    // ✅ 배경은 그대로 메모시트 유지
    return MemoFullDesign(
      appBarTitle: titleText,
      onBack: onBack,
      onNext: onNext,
      contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      memoHeight: 600,
      child: content,
    );
  }

  /// 🌈 걱정일기 그려보기
  static Widget buildVisualizationLayout({
    required String situationLabel,
    required String beliefLabel,
    required String resultLabel,
    required String situationText,
    required String beliefText,
    required String resultText,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final memoWidth = width * 0.65;
        final baseMemoMinHeight = memoWidth * 0.45;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            const Text(
              '걱정일기 그려보기',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: DesignPalette.textBlack,
                fontFamily: 'Noto Sans KR',
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 200,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.black26.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 48),

            // ✅ 시각화 구성
            IntrinsicHeight(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildGradientColumn(
                        labels: [situationLabel, beliefLabel, resultLabel],
                      ),
                      const SizedBox(width: 24),
                      _buildMemoColumn(
                        texts: [situationText, beliefText, resultText],
                        memoWidth: memoWidth,
                        minMemoHeight: baseMemoMinHeight,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🩵 왼쪽 컬럼 (그라데이션 물방울)
  static Widget _buildGradientColumn({required List<String> labels}) {
    return Container(
      width: 75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignPalette.blue,
                DesignPalette.pink,
                DesignPalette.mint,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < labels.length; i++) ...[
                _labelText(labels[i]),
                if (i < labels.length - 1)
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white70,
                    size: 22,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Widget _labelText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15.5,
          fontFamily: 'Noto Sans KR',
        ),
      ),
    );
  }

  /// 📝 오른쪽 메모 세트 — 흰색 박스 버전 (memo.png 제거)
  static Widget _buildMemoColumn({
    required List<String> texts,
    required double memoWidth,
    required double minMemoHeight,
  }) {
    final accentColors = [
      DesignPalette.blue,
      DesignPalette.pink,
      DesignPalette.mint,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: memoWidth,
                    maxWidth: memoWidth,
                    minHeight: minMemoHeight,
                  ),
                  child: Container(
                    // ✅ memo.png → 흰색 카드로 변경
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: Colors.black12, width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      texts[i].isEmpty
                          ? '입력된 ${["상황", "생각", "결과"][i]} 없음'
                          : texts[i],
                      textAlign: TextAlign.center,
                      style: DesignPalette.contentText,
                      softWrap: true,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -13,
                  child: Container(
                    width: memoWidth,
                    height: 22,
                    decoration: BoxDecoration(
                      color: accentColors[i],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColors[i].withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (i < 2)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.grey,
                  size: 22,
                ),
              ),
          ],
        );
      }),
    );
  }
}
