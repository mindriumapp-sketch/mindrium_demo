import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class CardContainer extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final bool useBlur;
  final bool showBorder; // CHANGED: 테두리 on/off 옵션 추가 (기본 false)

  const CardContainer({
    super.key,
    this.title,
    required this.child,
    this.padding,
    this.margin,
    this.showShadow = true,
    this.useBlur = true,
    this.showBorder = false, // CHANGED: 기본값 false → 네온 테두리 제거
  });

  static const _lineBlue = Color(0xFFDFFEFF);
  static const _titleNavy = Color(0xFF141F35);

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              title!,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontFamily: 'Noto Sans KR',
                color: _titleNavy,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1.0,
              ),
            ),
          ),
        child,
      ],
    );

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        border:
            showBorder
                ? Border.all(width: 3, color: _lineBlue)
                : null, // CHANGED
        boxShadow:
            showShadow
                ? const [
                  // 하얀 글로우
                  BoxShadow(
                    color: Color(0xE8FFFFFF),
                    blurRadius: 30,
                    offset: Offset(0, 0),
                  ),
                  // 은은한 드롭섀도
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: useBlur ? 14 : 0, // CHANGED: 블러 강도 유지
            sigmaY: useBlur ? 14 : 0,
          ),
          child: Container(
            width: double.infinity,
            padding: padding ?? const EdgeInsets.all(AppSizes.padding),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
