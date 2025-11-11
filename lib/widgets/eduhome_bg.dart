import 'package:flutter/material.dart';

class EduhomeBg extends StatelessWidget {
  final double brightness; // 💡 밝기 제어용
  final String imagePath;
  final Widget child;

  const EduhomeBg({
    super.key,
    required this.child,
    this.brightness = 1.0,
    this.imagePath = 'assets/image/eduhome.png',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(1 - brightness),
            BlendMode.srcATop,
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
        child,
      ],
    );
  }
}
