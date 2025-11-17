import 'dart:async';
import 'package:flutter/material.dart';

class BlueBanner {
  static OverlayEntry? _entry;

  static void show(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        EdgeInsets padding = const EdgeInsets.fromLTRB(16, 0, 16, 135),
        Color color = const Color(0xFF33A4F0),
      }) {
    _entry?.remove();
    _entry = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: padding.left,
                right: padding.right,
                bottom: padding.bottom,
                child: _ToastBubble(message: message, color: color),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
    Timer(duration, () {
      _entry?.remove();
      _entry = null;
    });
  }
}

class _ToastBubble extends StatelessWidget {
  final String message;
  final Color color;
  const _ToastBubble({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          message,
          textAlign: TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ─────────────────────────────
/// 여기서부터 네가 쓰고 싶은 하얀 배너
/// ─────────────────────────────
class CustomBanner {
  static OverlayEntry? _entry;

  static void show(
      BuildContext context, {
        String message =
        'ABC 모델은 감정의 원인을 이해하고\n사고를 바꾸는 연습의 기초가 됩니다!',
        Duration duration = const Duration(seconds: 4),
        EdgeInsets padding = const EdgeInsets.fromLTRB(16, 0, 16, 160),
        bool showJellyfish = true,
      }) {
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (ctx) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: padding.left,
                right: padding.right,
                bottom: padding.bottom,
                child: JellyfishBanner(
                  message: message,
                  showJellyfish: showJellyfish,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);

    Timer(duration, () {
      _entry?.remove();
      _entry = null;
    });
  }
}

/// 해파리 배너 디자인
/// 🪼 해파리 배너 위젯 (그냥 어디서나 붙여서 쓸 수 있음)
class JellyfishBanner extends StatelessWidget {
  final String message;
  final bool showJellyfish;
  final double? right;
  final double? bottom;
  final String jellyfish;

  const JellyfishBanner({
    super.key,
    required this.message,
    this.showJellyfish = true,
    this.right = -45,
    this.bottom = -35,
    this.jellyfish = 'assets/image/jellyfish_smart.png',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1) 가운데 하얀 박스
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF5DADEC).withOpacity(0.5),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF626262),
                // color: Color(0xFF263C69),
                fontFamily: 'Noto Sans KR',
              ),
            ),
          ),

          // 2) 컨테이너 우하단에 살짝 걸친 해파리
          if (showJellyfish)
            Positioned(
              right: right,
              bottom: bottom,
              child: Image.asset(
                jellyfish,
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }
}
