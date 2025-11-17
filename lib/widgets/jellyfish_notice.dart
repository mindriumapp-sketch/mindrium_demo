import 'package:flutter/material.dart';

class JellyfishNotice extends StatelessWidget {
  final String? feedback;
  final Color? feedbackColor;

  const JellyfishNotice({
    super.key,
    this.feedback,
    this.feedbackColor,
  });

  @override
  Widget build(BuildContext context) {
    const double tailTop = 30;
    const double jellySize = 80.0;

    return Padding(padding: EdgeInsetsGeometry.fromLTRB(0, 12, 0, 12),
      child: Padding(
        // ← 여기로 전체를 살짝 오른쪽으로 민다 (수치는 화면 보면서 조절)
        padding: const EdgeInsets.only(left: 40),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 💬 말풍선
            Container(
              constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      feedback ??
                          '지금은 위 생각에 대해 얼마나 강하게 \n믿고 계시나요?\n아래 슬라이더를 조절하고 [다음]을 \n눌러주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: feedback != null
                            ? feedbackColor
                            : const Color(0xFF666666),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ⬅️ 꼬리
            Positioned(
              left: -10,
              top: tailTop,
              child: CustomPaint(
                size: const Size(16, 16),
                painter: _LeftTailPainter(color: Colors.white),
              ),
            ),

            // 🪼 해파리 (이제 좀 더 오른쪽에 붙여도 잘리지 않음)
            Positioned(
              left: -80, // 여기 값만 다시 조절해서 딱 붙이기
              top: tailTop - (jellySize / 2) + 8,
              child: SizedBox(
                width: jellySize,
                height: jellySize,
                child: Image.asset(
                  'assets/image/jellyfish.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftTailPainter extends CustomPainter {
  final Color color;
  _LeftTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.08), 2.0, false);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
