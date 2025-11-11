import 'package:flutter/material.dart';

class Week3ClassificationDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> quizResults;
  const Week3ClassificationDetailScreen({super.key, required this.quizResults});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정답 상세 보기')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: quizResults.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = quizResults[index];
          final isCorrect = item['isCorrect'] as bool;
          return Card(
            color:
                isCorrect ? const Color(0xFFE3FCEC) : const Color(0xFFFFE3E3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ${item['text']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '내 답: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item['userChoice'] == 'healthy'
                            ? '도움이 되는 생각'
                            : '도움이 되지 않는 생각',
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '정답: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item['correctType'] == 'healthy'
                            ? '도움이 되는 생각'
                            : '도움이 되지 않는 생각',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect ? '정답' : '오답',
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
