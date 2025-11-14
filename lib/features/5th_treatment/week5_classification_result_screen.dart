import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/round_card.dart';
import 'package:gad_app_team/features/5th_treatment/week5_classification_detail_screen.dart';
import 'week5_imagination.dart';

class Week5ClassificationResultScreen extends StatelessWidget {
  final int correctCount;
  final List<Map<String, dynamic>> quizResults;

  const Week5ClassificationResultScreen({
    super.key,
    required this.correctCount,
    required this.quizResults,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 💡 배경색 제거 (body Stack으로 처리)
      // backgroundColor: const Color(0xFFFBF8FF),
      extendBodyBehindAppBar: true, // AppBar 뒤까지 배경 확장

      body: Stack( // 💡 Stack 추가
        fit: StackFit.expand,
        children: [
          // 🌊 화면 전체 배경 (ApplyDesign 동일)
          Container(
            color: Colors.white, // 흰색 베이스 추가
            child: Opacity(
              opacity: 0.35, // 동일한 투명도
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
                Expanded(
                  // 💡 SingleChildScrollView를 Center로 감싸고 padding 조정
                  child: Center(
                    child: SingleChildScrollView(
                      // 💡 수직 패딩 추가하여 중앙보다 약간 아래로 내릴 수 있는 여지 확보
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, // Center 위젯이 있으므로 불필요하지만 유지
                        children: [
                          // ───────── 결과 카드
                          RoundCard( // NotebookPage였을 경우 NotebookPage로 변경
                            margin: EdgeInsets.zero, // Center 위젯 사용 시 마진 제거
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 36, // 상하 패딩을 늘려 카드 크기를 키웁니다.
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 💡 축하 이미지 크기 조정
                                Image.asset(
                                  'assets/image/congrats.png',
                                  width: 140, // 이미지 크기를 줄여 중앙으로 모이게 합니다.
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 22),
                                Text(
                                  // ** 굵게 표시를 위해 \n 제거 후 TextSpan 사용 (더 깔끔한 방식)
                                  '20개의 문항 중\n$correctCount개 맞았어요!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    height: 1.4,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Week3ClassificationDetailScreen(
                                            quizResults: quizResults,
                                          ),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      foregroundColor: const Color(0x7F263C69),
                                    ),
                                    child: const Text(
                                      '클릭하여 선택한 내용을 확인해보세요.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.39,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ⛵ 하단 네비게이션 버튼 (기존 위치 유지)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: NavigationButtons(
                    onBack: () => Navigator.pop(context),
                    onNext: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const Week5ImaginationScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    },
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