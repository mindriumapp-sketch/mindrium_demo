import 'package:flutter/material.dart';

/// 🌊 Mindrium 스타일 공용 배경 위젯
/// - 흰색 배경 위에 eduhome 이미지를 0.35 투명도로 덮음
/// - ApplyDesign과 완전히 동일한 색감 유지
class EduhomeBg extends StatelessWidget {
  final Widget child;
  final double opacity; // 💧 이미지 투명도 제어 (기본 0.35)
  final String imagePath;

  const EduhomeBg({
    super.key,
    required this.child,
    this.opacity = 0.35,
    this.imagePath = 'assets/image/eduhome.png',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 💠 흰색 베이스
        Container(color: Colors.white),

        // 🌊 eduhome 이미지 (ApplyDesign 동일)
        Opacity(
          opacity: opacity,
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),

        // 📄 내용
        child,
      ],
    );
  }
}
