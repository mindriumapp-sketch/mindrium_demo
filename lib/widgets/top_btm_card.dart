import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/jellyfish_notice.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

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
  final double height;
  final double topPadding;

  final String? middleBannerText;

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
    this.panelsGap = 26,
    this.panelPadding = const EdgeInsets.fromLTRB(24, 24, 24, 24),
    this.panelRadius = 20,
    this.maxWidth = 0,
    this.middleNoticeText,
    this.middleNoticeColor,
    this.middleNoticeMargin = const EdgeInsets.symmetric(vertical: 12),
    this.height = 160,
    this.topPadding = 20,
    this.middleBannerText,
    this.topcardColor,
    this.btmcardColor,
    this.topPanelShadows,
    this.bottomPanelShadows,
  });

  bool get _showJellyfish =>
      middleNoticeText != null && middleNoticeText!.trim().isNotEmpty;

  bool get _showBanner =>
      middleBannerText != null && middleBannerText!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final double computedMaxWidth =
        (maxWidth == 0) ? MediaQuery.of(context).size.width - 48 : maxWidth;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: appBarTitle,
        confirmOnHome: true,
        showHome: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경
          Container(
            color: Colors.white,
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/image/eduhome.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          /// ⭐ 여기부터 레이아웃 수정: 위는 스크롤, 아래는 고정
          SafeArea(
            child: Column(
              children: [
                // 위쪽: 스크롤 가능한 컨텐츠
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: pagePadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── 상단 패널 ──
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: computedMaxWidth,
                            ),
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
                          if (_showJellyfish) ...[
                            Container(
                              color: Colors.transparent,
                              height: height,
                              child: Padding(
                                padding: EdgeInsetsGeometry.fromLTRB(
                                  0,
                                  topPadding,
                                  0,
                                  0,
                                ),
                                child: JellyfishNotice(
                                  feedback: middleNoticeText!.trim(),
                                  feedbackColor: middleNoticeColor,
                                ),
                              ),
                            ),
                          ],
                          if (_showBanner) ...[
                            Container(
                              color: Colors.transparent,
                              height: height,
                              child: Padding(
                                padding: EdgeInsetsGeometry.fromLTRB(
                                  0,
                                  topPadding,
                                  0,
                                  0,
                                ),
                                child: JellyfishBanner(
                                  message: middleBannerText!.trim(),
                                ),
                              ),
                            ),
                          ],

                          // ── 하단 패널 ──
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: computedMaxWidth,
                            ),
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
                        ],
                      ),
                    ),
                  ),
                ),

                // 아래: 항상 바닥에 붙는 네비게이션
                if (onBack != null || onNext != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: NavigationButtons(onBack: onBack, onNext: onNext),
                  ),
              ],
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
      width: 400,
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
      width: 300,
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
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.black87,
                wordSpacing: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
