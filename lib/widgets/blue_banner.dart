import 'dart:async';
import 'package:flutter/material.dart';

class BlueBanner {
  static OverlayEntry? _entry;

  static void show(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 3),
        EdgeInsets padding = const EdgeInsets.fromLTRB(16, 0, 16, 50),
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
