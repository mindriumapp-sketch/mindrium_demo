import 'package:flutter/material.dart';

// 퀴즈 부분에 쓰이는 위젯입니당!

class QuizCard extends StatelessWidget {
  final String quizText;
  final int currentIndex;
  final int? totalCount;

  const QuizCard({
    super.key,
    required this.quizText,
    required this.currentIndex,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // ✅ 고정 높이 흰색 카드
        Container(
          width: double.infinity,
          height: 190,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              quizText,
              textAlign: TextAlign.center,
              softWrap: true,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                height: 1.7,
              ),
            ),
          ),
        ),

        // ✅ 진행 상태 (totalCount 있을 때만)
        if (totalCount != null) ...[
          const SizedBox(height: 12),
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