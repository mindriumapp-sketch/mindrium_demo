// lib/features/3rd_treatment/week3_classification_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class Week3ClassificationDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> quizResults;

  const Week3ClassificationDetailScreen({
    super.key,
    required this.quizResults,
  });

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
          // 🔹 공통 배경 (eduhome)
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),

          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: quizResults.length,
              separatorBuilder: (context, index) =>
              const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final item = quizResults[index];
                final bool isCorrect = item['isCorrect'] as bool;

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
                      // 문항 텍스트
                      Text(
                        '${index + 1}. ${item['text']}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 내 답
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
                              item['userChoice'] == 'healthy'
                                  ? '도움이 되는 생각'
                                  : '도움이 되지 않는 생각',
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // 정답
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
                              item['correctType'] == 'healthy'
                                  ? '도움이 되는 생각'
                                  : '도움이 되지 않는 생각',
                              style: const TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 정오답 아이콘/라벨
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
