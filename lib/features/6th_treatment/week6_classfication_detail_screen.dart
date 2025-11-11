import 'package:flutter/material.dart';

class Week6ClassificationDetailScreen extends StatelessWidget {
  final List<double>? bScores;
  final List<String>? bList;

  const Week6ClassificationDetailScreen({super.key, this.bScores, this.bList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자세히 살펴보기'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: const Color(0xFFFBF8FF),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child:
            (bScores != null && bList != null)
                ? ListView.builder(
                  itemCount: bList!.length,
                  itemBuilder: (context, idx) {
                    final score = bScores![idx];
                    final color = Color.lerp(
                      const Color(0xFF4CAF50), // 초록
                      const Color(0xFFFF5252), // 붉은
                      (score / 10).clamp(0.0, 1.0),
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: color?.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    bList![idx],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${score.round()}점',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
                : const Center(child: Text('확인할 데이터가 없습니다.')),
      ),
    );
  }
}
