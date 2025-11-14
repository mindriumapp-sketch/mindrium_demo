import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class Week3ClassificationDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> quizResults;

  const Week3ClassificationDetailScreen({
    super.key,
    required this.quizResults,
  });

  /// 내부 키('healthy'/'anxious')를 한국어 라벨로 변환 (⚠️ 로직/텍스트 변경 금지)
  String _labelKR(String t) =>
      t == 'healthy' ? '불안을 직면하는 행동' : '불안을 회피하는 행동';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,

      appBar: const CustomAppBar(
        title: '정답 상세 보기',
        confirmOnBack: false,
        showHome: true,
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 공통 배경 (eduhome, opacity 0.35)
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),

          // 🔹 내용
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: quizResults.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = quizResults[index];

                // ⚠️ 로직 그대로 유지
                final bool isCorrect = item['isCorrect'] as bool;
                final String text = item['text'] as String;
                final String userChoice =
                _labelKR(item['userChoice'] as String);
                final String correctType =
                _labelKR(item['correctType'] as String);

                // ✅ 디자인: 정답 파랑 / 오답 레드 테두리
                final Color borderColor =
                isCorrect ? const Color(0xFF66D0F9) : Colors.red;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 문항 텍스트 (왼쪽 정렬, 동일 스타일)
                      Text(
                        '${index + 1}. $text',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 🔹 내 답 (항상 노출 / 텍스트만 다름)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '내 답: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              userChoice,
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 🔹 정답 (항상 노출)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '정답: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              correctType,
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Icon(
                            isCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isCorrect
                                ? const Color(0xFF66D0F9)
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCorrect ? '정답' : '오답',
                            style: TextStyle(
                              color: isCorrect
                                  ? const Color(0xFF66D0F9)
                                  : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
