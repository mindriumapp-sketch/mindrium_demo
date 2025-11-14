import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';

/// 🌊 Mindrium 완전 투명 CustomAppBar
/// - Opacity 사용 안 함
/// - 완전 투명 배경 + 그림자 제거
/// - 색상은 직접 지정 (독립형)
/// - Mindrium 감성 버튼 및 다이얼로그 포함
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onHomePressed;
  final bool showHome;
  final bool confirmOnBack;
  final bool confirmOnHome;
  final IconData? extraIcon;
  final String? extraRoute;
  final VoidCallback? onExtraPressed;
  final bool? centerTitle; // ← 추가 (null이면 AppBar 기본 동작)
  final TextStyle? titleTextStyle; // ← 추가 (null이면 기존 스타일)
  final double? toolbarHeight; // ← 추가 (null이면 kToolbarHeight)
  final PreferredSizeWidget? bottom; // ← 선택: 필요하면 하단 영역도 추가 가능

  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.onHomePressed,
    this.showHome = true,
    this.confirmOnBack = false,
    this.confirmOnHome = true,
    this.extraIcon,
    this.extraRoute,
    this.onExtraPressed,
    this.centerTitle, // ← 추가
    this.titleTextStyle, // ← 추가
    this.toolbarHeight, // ← 추가
    this.bottom, // ← 추가
  }) : assert(
         extraRoute == null || onExtraPressed == null,
         'extraRoute와 onExtraPressed는 둘 중 하나만 지정하세요.',
       );

  // 🎨 내부 색상 정의
  static const Color _indigo = Color(0xFF3F51B5);
  static const Color _black = Color(0xFF222222);
  static const Color _greyText = Color(0xFF666666);
  static const Color _white = Colors.white;

  Future<bool> _confirmExit(BuildContext context) async {
    return await showDialog<bool>(
        context: context,
        barrierColor: Colors.black.withAlpha(
          60,
        ), // ← withOpacity 대신 Alpha 직접 지정
        barrierDismissible: false,
        builder:
            (_) => CustomPopupDesign(
          title: '종료하시겠어요?',
          message: '지금 종료하면 진행 상황이 저장되지 않을 수 있습니다',
          onPositivePressed: () => Navigator.pop(context, true),
          onNegativePressed: () => Navigator.pop(context, false),
          positiveText: '나가기',
          negativeText: '취소',
        )
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // ✅ 완전 투명 (Opacity 사용 X)
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,

      centerTitle: centerTitle, // ← 추가
      toolbarHeight: toolbarHeight, // ← 추가
      bottom: bottom, // ← 추가

      titleSpacing: 4,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _indigo),
          splashRadius: 22,
          onPressed: () async {
            if (confirmOnBack) {
              final confirmed = await _confirmExit(context);
              if (!confirmed || !context.mounted) return;
            }
            if (onBack != null) {
              onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      title: Text(
        title,
        style:
            titleTextStyle ??
            const TextStyle(
              // ← 추가: 커스터마이즈 가능
              fontFamily: 'Noto Sans KR',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _black,
              letterSpacing: -0.3,
            ),
      ),

      actions: [
        if (extraIcon != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(extraIcon, color: _black),
              splashRadius: 22,
              onPressed:
                  onExtraPressed ??
                  () {
                    if (extraRoute != null) {
                      Navigator.pushNamed(context, extraRoute!);
                    }
                  },
            ),
          ),
        if (showHome)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.home_outlined, color: _black),
              splashRadius: 22,
              onPressed: () async {
                if (confirmOnHome) {
                  final confirmed = await _confirmExit(context);
                  if (!confirmed || !context.mounted) return;
                }
                if (onHomePressed != null) {
                  onHomePressed!();
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                }
              },
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight ?? kToolbarHeight); // ← 높이 반영
}
