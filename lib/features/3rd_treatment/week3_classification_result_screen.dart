import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/blue_white_card.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_classification_detail_screen.dart';
import 'package:gad_app_team/features/3rd_treatment/week3_imagination.dart';

class Week3ClassificationResultScreen extends StatelessWidget {
  final int correctCount;
  final List<Map<String, dynamic>> quizResults;

  const Week3ClassificationResultScreen({
    super.key,
    required this.correctCount,
    required this.quizResults,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '3주차 - Self Talk'),

      /// 🌊 Mindrium 바다 배경
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/image/eduhome.png', fit: BoxFit.cover),

          /// 💙 메인 콘텐츠
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// 🩵 상단 BlueWhiteCard — 결과 개념 카드
                    BlueWhiteCard(
                      maxWidth: screenWidth * 0.92,
                      title: '도움이 되는 생각과\n도움이 되지 않는 생각',
                      outerColor: const Color(0xFFD6E7FF),
                      innerColor: Colors.white,
                      minHeight: 240,
                      titleTopGap: 12,
                      innerPadding: const EdgeInsets.all(16),
                      outerExpand: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/image/nice.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    /// 💭 하단 BlueWhiteCard — 점수/버튼 영역
                    BlueWhiteCard(
                      maxWidth: screenWidth * 0.92,
                      title: '결과 요약',
                      outerColor: const Color(0xFFD6E7FF),
                      innerColor: Colors.white,
                      minHeight: 320,
                      innerPadding: const EdgeInsets.all(24),
                      outerExpand: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            '20개의 문항 중\n$correctCount개나 맞았어요!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Noto Sans KR',
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            Week3ClassificationDetailScreen(
                                              quizResults: quizResults,
                                            ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2962F6),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                '자세히 살펴보기',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Noto Sans KR',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    /// ⛵ 네비게이션 버튼
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: NavigationButtons(
                        onBack: () => Navigator.pop(context),
                        onNext: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const Week3ImaginationScreen(),
                              transitionDuration: Duration.zero,
                              reverseTransitionDuration: Duration.zero,
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 💡 안내문 (ValueStart 스타일)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Color(0xFF3F51B5),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '잘하셨어요 👏 이번 결과를 바탕으로\n도움이 되는 생각을 계속 연습해볼까요?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3F51B5),
                                height: 1.5,
                                fontFamily: 'Noto Sans KR',
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
        ],
      ),
    );
  }
}
