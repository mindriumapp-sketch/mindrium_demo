import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/jellyfish_notice.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ApplyDoubleCard extends StatelessWidget {
  final String appBarTitle;
  final Widget topChild;
  final Widget bottomChild;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  // 스타일 옵션
  final EdgeInsets pagePadding;
  final double panelsGap;
  final EdgeInsets panelPadding;
  final double panelRadius;
  final double maxWidth;

  // Jellyfish (옵션)
  final String? middleNoticeText;
  final Color? middleNoticeColor;
  final EdgeInsets middleNoticeMargin;

  // ✅ 추가: 상/하 패널 색/그림자 제어
  final Color? topcardColor;
  final Color? btmcardColor;
  final List<BoxShadow>? topPanelShadows;
  final List<BoxShadow>? bottomPanelShadows;

  const ApplyDoubleCard({
    super.key,
    required this.appBarTitle,
    required this.topChild,
    required this.bottomChild,
    this.onBack,
    this.onNext,
    this.pagePadding = const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
    this.panelsGap = 24,
    this.panelPadding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
    this.panelRadius = 20,
    this.maxWidth = 0,
    this.middleNoticeText,
    this.middleNoticeColor,
    this.middleNoticeMargin = const EdgeInsets.symmetric(vertical: 12),
    this.topcardColor,
    this.btmcardColor,
    this.topPanelShadows,
    this.bottomPanelShadows,
  });

  bool get _showJellyfish =>
      middleNoticeText != null && middleNoticeText!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final double computedMaxWidth =
        (maxWidth == 0) ? MediaQuery.of(context).size.width - 48 : maxWidth;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: appBarTitle,
        confirmOnBack: false,
        showHome: true,
        onBack: () async {
          // ✅ “종료하시겠습니까?” 다이얼로그
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.white.withOpacity(0.95),
                  title: const Text('종료하시겠습니까?'),
                  content: const Text('이 화면을 종료하고 이전 화면으로 돌아갑니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('나가기'),
                    ),
                  ],
                ),
          );

          if (shouldExit == true) {
            // ✅ 검은화면 방지용 임시 오버레이 생성
            final overlayContext = navigatorKey.currentState?.overlay?.context;
            if (overlayContext != null) {
              showGeneralDialog(
                context: overlayContext,
                barrierColor: Colors.transparent,
                barrierDismissible: false,
                transitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => const SizedBox.shrink(),
              );
            }

            // ✅ 실제 뒤로가기 실행
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/menu');
            }

            // ✅ 오버레이 제거 (한 프레임 뒤 자동 해제)
            await Future.delayed(const Duration(milliseconds: 100));
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.65,
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: pagePadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── 상단 패널 ──
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: computedMaxWidth),
                      child: WhitePanel(
                        padding: panelPadding,
                        radius: panelRadius,
                        color: topcardColor ?? Colors.white,
                        shadows: topPanelShadows,
                        child: topChild,
                      ),
                    ),
                    SizedBox(height: panelsGap),

                    // 🪼 Jellyfish (옵션)
                    if (_showJellyfish)
                      JellyfishNotice(feedback: middleNoticeText!.trim()),

                    // ── 하단 패널 ──
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: computedMaxWidth),
                      child: WhitePanel(
                        padding: panelPadding,
                        radius: panelRadius,
                        color: btmcardColor ?? Colors.white,
                        shadows:
                            bottomPanelShadows ??
                            (btmcardColor != null ? <BoxShadow>[] : null),
                        child: bottomChild,
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (onBack != null || onNext != null)
                      NavigationButtons(onBack: onBack, onNext: onNext),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WhitePanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final List<BoxShadow>? shadows;
  final Color color;

  const WhitePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 20,
    this.shadows,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow:
            shadows ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class PanelHeader extends StatelessWidget {
  final TextStyle? titleStyle;
  final bool showDivider;
  final String? chipText;
  final Widget? icon;
  final String? subtitle;
  final EdgeInsets margin;

  const PanelHeader({
    super.key,
    this.titleStyle,
    this.showDivider = true,
    this.chipText,
    this.icon,
    this.subtitle,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final titleStyles =
        titleStyle ??
        const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF263C69),
        );

    return Container(
      margin: margin,
      child: Column(
        children: [
          if (chipText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                chipText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF777777),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (icon != null) ...[const SizedBox(height: 16), icon!],
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              style: titleStyles.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
