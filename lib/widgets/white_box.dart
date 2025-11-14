import 'dart:ui';
import 'package:flutter/material.dart';

class WhiteBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final bool blur; // 블러 사용 여부
  final VoidCallback? onTap;

  // 색상 정의 (기존 값 유지)
  static const Color _fillColor = Color(0xFFFFFFFF); // 완전 불투명 흰색dm으로 변경햇둠
  static const Color _borderColor = Color(0xE6FFFFFF); // ≈ 90% 불투명 흰색

  const WhiteBox({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Pixel 7 (1080px) 기준으로 스케일 계산
    final double scale = MediaQuery.of(context).size.width / 1080;

    final EdgeInsetsGeometry effectivePadding =
        (padding ?? const EdgeInsets.all(20)).scale(scale);
    final EdgeInsetsGeometry effectiveMargin =
        (margin ?? const EdgeInsets.symmetric(horizontal: 20)).scale(scale);
    final double effectiveRadius = (borderRadius ?? 16) * scale;

    final container = Container(
      margin: effectiveMargin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: _fillColor,
        borderRadius: BorderRadius.circular(effectiveRadius),
        border: Border.all(color: _borderColor, width: 1 * scale),
      ),
      child: child,
    );

    final blurredBox =
        blur
            ? ClipRRect(
              borderRadius: BorderRadius.circular(effectiveRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * scale, sigmaY: 8 * scale),
                child: container,
              ),
            )
            : container;

    return onTap == null
        ? blurredBox
        : GestureDetector(onTap: onTap, child: blurredBox);
  }
}

extension on EdgeInsetsGeometry {
  EdgeInsetsGeometry scale(double factor) {
    if (this is EdgeInsets) {
      final e = this as EdgeInsets;
      return EdgeInsets.only(
        left: e.left * factor,
        right: e.right * factor,
        top: e.top * factor,
        bottom: e.bottom * factor,
      );
    }
    return this;
  }
}
