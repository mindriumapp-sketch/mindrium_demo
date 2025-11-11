import 'package:flutter/material.dart';

class QuizCard extends StatelessWidget {
  final String quizText;
  final int currentIndex;
  final int? totalCount; // ← nullable로 변경

  const QuizCard({
    super.key,
    required this.quizText,
    required this.currentIndex,
    this.totalCount, // ← 선택 인자
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 중앙 흰색 카드
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 64),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Text(
            quizText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF333333),
              height: 1.7,
            ),
          ),
        ),

        // 진행 상태: totalCount가 있을 때만 표시
        if (totalCount != null) ...[
          const SizedBox(height: 18),
          Text(
            '$currentIndex/$totalCount',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFAAAAAA),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
