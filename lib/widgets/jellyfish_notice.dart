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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 말풍선 + 꼬리
        Stack(
          clipBehavior: Clip.none,
          children: [
            // 말풍선 본체
            Container(
              constraints: const BoxConstraints(
                maxWidth: 280,
              ),
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      feedback ??
                          '화면에 보이는 생각이 어떠한 행동인지 선택한 후 다음 버튼을 누르세요.',
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

            // 말풍선 꼬리
            Positioned(
              left: 20,
              bottom: -20,
              child: CustomPaint(
                size: const Size(24, 24),
                painter: _AngularTailPainter(color: Colors.white),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 해파리
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Image.asset(
              'assets/image/jellyfish.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

// 말풍선 꼬리
class _AngularTailPainter extends CustomPainter {
  final Color color;
  _AngularTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0) // 왼쪽 위
      ..lineTo(size.width, 0) // 오른쪽 위
      ..lineTo(size.width * 0.4, size.height) // 아래 꼭짓점 (약간 왼쪽)
      ..close();

    // 그림자 효과
    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.08),
      2.0,
      false,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}