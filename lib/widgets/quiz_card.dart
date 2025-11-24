import 'package:flutter/material.dart';

class QuizCard extends StatelessWidget {
  final String noticeText;
  final double noticeSize;
  final String quizText;
  final double quizSize;
  final int currentIndex;
  final int? totalCount; // ← nullable로 변경

  const QuizCard({
    super.key,
    this.noticeText = '',
    this.noticeSize = 14,
    required this.quizText,
    this.quizSize = 20,
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
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 64),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                if(noticeText != '') ... [
                  Text(
                    noticeText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: noticeSize,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8796B8),
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 30,),
                ],
                Text(
                  quizText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: quizSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                    height: 1.7,
                  ),
                ),
              ],
            ),
          )
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
