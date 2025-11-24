// lib/features/3rd_treatment/week3_classification_detail_screen.dart

import 'package:flutter/material.dart';

class Week3ClassificationDetailScreen extends StatelessWidget {
  final List<Map<String, dynamic>> quizResults;
  const Week3ClassificationDetailScreen({super.key, required this.quizResults});

  /// 내부 키('healthy'/'anxious')를 한국어 라벨로 변환
  String _labelKR(String t) => t == 'healthy' ? '도움이 되는 생각' : '도움이 되지 않는 생각';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        title: const Text('정답 상세 보기'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF224C78),
        elevation: 0,
      ),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌊 화면 전체 배경 (원본 밝기로 표시)
          Image.asset(
            'assets/image/eduhome.png',
            fit: BoxFit.cover,
          ),

          // 💡 밝은 오버레이 (파스텔 톤 효과)
          Container(
            color: Colors.white.withValues(alpha: 0.35),
          ),


          // 💬 본문 (ListView)
          SafeArea(
            // 💡 ListView를 Container로 감싸고 배경을 명시적으로 투명하게 설정
            child: Container(
              color: Colors.transparent,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                itemCount: quizResults.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final item = quizResults[index];
                  final isCorrect = item['isCorrect'] as bool;
                  final text = item['text'] as String;
                  final userChoice = _labelKR(item['userChoice'] as String);
                  final correctType = _labelKR(item['correctType'] as String);

                  final barColor =
                  isCorrect ? const Color(0xFF40C79A) : const Color(0xFFEB6A67);
                  final barIcon = isCorrect ? Icons.check : Icons.close;
                  final barLabel = isCorrect ? '정답' : '오답';

                  return Container(
                    decoration: BoxDecoration(
                      // 💡 카드 배경색은 흰색으로 유지하여 내용 가독성을 높임
                      color: Colors.white.withValues(alpha: 0.99),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 4,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 상단 색 띠 (현재 스타일 유지)
                        Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(barIcon, color: Colors.white, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                barLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 본문 문장
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                          child: Text(
                            '${index + 1}. $text',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF232323),
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Noto Sans KR',
                            ),
                          ),
                        ),

                        // 내 답 / 정답 영역 (요청 포맷)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (!isCorrect) ...[
                                _AnswerRow(
                                  label: '내 답',
                                  value: userChoice,
                                  color: const Color(0xFFEB6A67), // 원래 빨강: 0xFFDA4543
                                  icon: Icons.close,
                                ),
                                const SizedBox(height: 6),
                              ],
                              _AnswerRow(
                                label: '정답',
                                value: correctType,
                                color: const Color(0xFF40C79A), // 원래 초록: 0xFF18AE79
                                icon: Icons.check,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// '내 답: …' / '정답: …' 한 줄 표시 위젯
class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label; // '내 답' or '정답'
  final String value; // '도움이 되는 생각' 등
  final Color color; // 빨강/초록
  final IconData icon; // close/check

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: color,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            fontFamily: 'Noto Sans KR',
          ),
        ),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              fontFamily: 'Noto Sans KR',
            ),
          ),
        ),
      ],
    );
  }
}
