import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

/// 단일 화면 레이아웃:
/// - 상단 AppBar
/// - 전체 배경: assets/image/eduhome.png
/// - 중앙 흰 카드(라운드+그림자)
///   ├ Title(중앙, 진한 보라블루)
///   ├ Divider(폭 240, height 1)
///   ├ 본문 [child] (가로 폭 제한으로 너무 퍼지지 않게)
///   ├ Primary Button (가득 너비)
///   └ Secondary Button (가득 너비, 선택)
class InnerBtnCardScreen extends StatelessWidget {
  const InnerBtnCardScreen({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.child,
    required this.primaryText,
    required this.onPrimary,
    this.button_height = 56,
    this.secondaryText,
    this.onSecondary,
    this.backgroundAsset = 'assets/image/eduhome.png',
    // ===== 레이아웃/스타일 옵션 =====
    this.maxCardHorizontalMargin = 34.0,      // 화면 좌우 여백 (ApplyDesign과 동일)
    this.cardInnerPadding = const EdgeInsets.fromLTRB(28, 26, 28, 26),
    this.cardRadius = 20,
    this.showShadow = true,
    this.contentMaxWidth = 560.0,             // 카드 내부 본문 최대 폭(너무 퍼지지 않도록)
    this.primaryColor = const Color(0xFF33A4F0),
    this.secondaryColor = const Color(0xFF33A4F0),
    this.titleStyle = const TextStyle(        // 타이틀 기본값: ApplyDesign 계열 느낌
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xFF5B3EFF),
      fontFamily: 'Noto Sans KR',
    ),
    this.bodyTextStyle = const TextStyle(     // 본문 기본 라인간격 살짝 좁게
      fontSize: 14,
      height: 1.45,
      color: Colors.black87,
      fontFamily: 'Noto Sans KR',
    ),
  });

  /// 앱바 타이틀
  final String appBarTitle;

  /// 카드 타이틀
  final String title;

  /// 카드 본문 위젯(텍스트/컴포넌트 포함)
  final Widget child;

  /// 기본 버튼(채움)
  final String primaryText;
  final VoidCallback onPrimary;

  // 버튼 높이
  final double button_height;

  /// 보조 버튼(테두리) — 선택
  final String? secondaryText;
  final VoidCallback? onSecondary;

  /// 배경 이미지
  final String backgroundAsset;

  /// 레이아웃/스타일
  final double maxCardHorizontalMargin; // 화면 좌우 마진 → 카드 최대폭 = screenWidth - 2*margin
  final EdgeInsets cardInnerPadding;
  final double cardRadius;
  final bool showShadow;
  final double contentMaxWidth; // 카드 내부 본문 최대 가로폭
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle titleStyle;
  final TextStyle bodyTextStyle;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final maxCardWidth = screenW - (maxCardHorizontalMargin * 2);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(title: appBarTitle),
      body: Stack(
        children: [
          // 배경
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),

          // 본문
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: maxCardHorizontalMargin,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardWidth),
                  child: Container(
                    width: double.infinity,
                    padding: cardInnerPadding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(cardRadius),
                      boxShadow: showShadow
                          ? const [
                        BoxShadow(
                          color: Color(0x29000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                          : null,
                    ),
                    child: DefaultTextStyle.merge(
                      style: bodyTextStyle,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            title,
                            style: titleStyle,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),

                          // Divider (폭 240, 높이 1)
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 130,
                              height: 3,
                              color: const Color(0xFFE8EDF4),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 본문(가로 제한으로 과도 확장 방지)
                          Align(
                            alignment: Alignment.center,
                            child: ConstrainedBox(
                              constraints:
                              BoxConstraints(maxWidth: contentMaxWidth),
                              child: child,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Primary Button (Filled)
                          SizedBox(
                            height: button_height,
                            child: ElevatedButton(
                              onPressed: onPrimary,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                primaryText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Noto Sans KR',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                          // Secondary Button (Outlined) — 선택적
                          if (secondaryText != null && onSecondary != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              height: button_height,
                              child: OutlinedButton(
                                onPressed: onSecondary,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: secondaryColor,
                                    width: 3,
                                  ),
                                  foregroundColor: secondaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                                child: Text(
                                  secondaryText!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Noto Sans KR',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
