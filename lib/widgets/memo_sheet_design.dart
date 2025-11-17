import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

/// 🪸 Mindrium “메모지 화면” (리뉴얼)
/// - 배경: eduhome.png
/// - 중앙: memo.png (화면 대부분 차지)
/// - child 안에서 이미지+텍스트 조합 가능
/// - 강조 텍스트는 HighlightText 위젯 사용
class MemoFullDesign extends StatelessWidget {
  final String appBarTitle;
  final Widget child;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String rightLabel;
  final EdgeInsetsGeometry contentPadding;
  final double? memoHeight;

  const MemoFullDesign({
    super.key,
    required this.appBarTitle,
    required this.child,
    required this.onBack,
    required this.onNext,
    this.rightLabel = '다음',
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 24,
      vertical: 32,
    ),
    this.memoHeight,
  });

  @override
  Widget build(BuildContext context) {
    final memoHeights = MediaQuery.of(context).size.height * 0.67;
    final check = (memoHeight != null) ? true : false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: appBarTitle),
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌊 배경
          Positioned.fill(
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/image/eduhome.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 👆 위쪽: 중앙에 메모장
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 24,
                      ),
                      child: Container(
                        height: check ? memoHeight : memoHeights,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: const DecorationImage(
                            image: AssetImage('assets/image/memo.png'),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: contentPadding,
                          child: SingleChildScrollView(child: child),
                        ),
                      ),
                    ),
                  ),
                ),

                // 👇 아래: 항상 바닥에 붙어 있는 네비게이션
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: NavigationButtons(
                    onBack: onBack,
                    onNext: onNext,
                    rightLabel: rightLabel,
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

/// 🌼 형광펜 강조 텍스트
class HighlightText extends StatelessWidget {
  final String text;
  final Color color;
  final TextStyle? style;

  const HighlightText({
    super.key,
    required this.text,
    this.color = const Color(0xFFFFF59D), // 노란색 형광펜 느낌
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle =
        style ??
        const TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 14, // ✅ 글자 크기 +1
          height: 1.4, // ✅ 줄 간격 약간 늘림
          color: Colors.black87,
        );

    return Stack(
      children: [
        Positioned.fill(
          top: 3, // ✅ 형광펜을 텍스트에 더 밀착
          child: Container(color: color.withOpacity(0.6)),
        ),
        Text(text, style: textStyle),
      ],
    );
  }
}

/// 🖼️ 이미지 + 텍스트 조합용 위젯
class MemoImageWithText extends StatelessWidget {
  final String imagePath;
  final Widget text;

  const MemoImageWithText({
    super.key,
    required this.imagePath,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// 🖼️ 이미지
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(imagePath, fit: BoxFit.cover),
        ),
        const SizedBox(height: 16),

        /// 구분선
        Container(
          height: 1,
          width: double.infinity,
          color: Colors.black.withOpacity(0.1),
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),

        /// 텍스트
        text,
      ],
    );
  }
}

/// 번호가 붙은 문장들을 촘촘히 보여주는 위젯
class NumberedTextList extends StatelessWidget {
  final List<String> items;

  const NumberedTextList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3), // ✅ 항목 간격 살짝 조정
          child: Text(
            '${index + 1}. ${items[index]}',
            style: const TextStyle(
              fontSize: 14, // ✅ 글자 크기 +1
              height: 1.4, // ✅ 줄 간격 약간 늘림
              color: Colors.black87,
              fontFamily: 'Noto Sans KR',
            ),
          ),
        );
      }),
    );
  }
}
