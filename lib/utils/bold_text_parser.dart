import 'package:flutter/material.dart';

/// 문자열 내의 **텍스트** 부분을 형광펜 스타일(형광 밑줄 느낌)로 표시
List<TextSpan> parseBoldText(String text) {
  final spans = <TextSpan>[];
  final regex = RegExp(r'\*\*(.*?)\*\*'); // **이 사이의 텍스트 탐색
  int lastMatchEnd = 0;

  for (final match in regex.allMatches(text)) {
    // 앞부분 (일반 텍스트)
    if (match.start > lastMatchEnd) {
      spans.add(
        const TextSpan(
          text: '',
          style: TextStyle(
            fontFamily: 'Noto Sans KR',
            fontWeight: FontWeight.w400,
          ),
        ),
      );
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: const TextStyle(
            fontFamily: 'Noto Sans KR',
            fontWeight: FontWeight.w400,
          ),
        ),
      );
    }

    // 형광펜 강조 부분
    final highlightedText = match.group(1);
    spans.add(
      TextSpan(
        text: highlightedText,
        style: TextStyle(
          fontFamily: 'Noto Sans KR',
          fontWeight: FontWeight.w500, // Medium
          background:
              Paint()
                ..color = const Color(0xFFA1CFFF)
                ..strokeWidth =
                    10 // 살짝 얇게 조정
                ..style = PaintingStyle.stroke, // 네모 형태
        ),
      ),
    );

    lastMatchEnd = match.end;
  }

  // 마지막 남은 텍스트
  if (lastMatchEnd < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(lastMatchEnd),
        style: const TextStyle(
          fontFamily: 'Noto Sans KR',
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  return spans;
}
