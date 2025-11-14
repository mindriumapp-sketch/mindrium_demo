import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/blue_white_card.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

class InnerBtnCardScreen extends StatelessWidget {
  const InnerBtnCardScreen({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.child,
    required this.primaryText,
    required this.onPrimary,
    this.buttonHeight = 56,
    this.secondaryText,
    this.onSecondary,
    this.backgroundAsset = 'assets/image/eduhome.png',
    this.maxCardHorizontalMargin = 34.0,
    this.contentMaxWidth = 560.0,
    this.primaryColor = const Color(0xFF33A4F0),
    this.secondaryColor = const Color(0xFF33A4F0),
    this.titleStyle = const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: Color(0xFF263C69),
      fontFamily: 'Noto Sans KR',
    ),
    this.bodyTextStyle = const TextStyle(
      fontSize: 14,
      height: 1.45,
      color: Colors.black87,
      fontFamily: 'Noto Sans KR',
    ),
    this.feedback = ''
  });

  final String appBarTitle;
  final String title;
  final Widget child;
  final String primaryText;
  final VoidCallback onPrimary;
  final double buttonHeight;
  final String? secondaryText;
  final VoidCallback? onSecondary;
  final String backgroundAsset;
  final double maxCardHorizontalMargin;
  final double contentMaxWidth;
  final Color primaryColor;
  final Color secondaryColor;
  final TextStyle titleStyle;
  final TextStyle bodyTextStyle;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final maxCardWidth = screenW - (maxCardHorizontalMargin * 2);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: appBarTitle),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경
          Opacity(
            opacity: 0.35,
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
                child: Column(
                  children: [
                    BlueWhiteCard(
                      maxWidth: maxCardWidth,
                      title: title,
                      titleStyle: titleStyle,
                      outerColor: Colors.transparent,
                      outerRadius: 22,
                      outerExpand: EdgeInsets.zero,
                      innerColor: Colors.white,
                      innerRadius: 20,
                      innerPadding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
                      dividerColor: const Color(0xFFE8EDF4),
                      dividerWidth: 260, // 원래 너가 쓰던 얇은 구분선 너비
                      titleTopGap: 10,
                      child: DefaultTextStyle.merge(
                        style: bodyTextStyle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 본문(가로 최대폭 제한)
                            Align(
                              alignment: Alignment.center,
                              child: ConstrainedBox(
                                constraints:
                                BoxConstraints(maxWidth: contentMaxWidth),
                                child: child,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Primary Button
                            SizedBox(
                              height: buttonHeight,
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
                                ),
                              ),
                            ),

                            // Secondary Button
                            if (secondaryText != null && onSecondary != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                height: buttonHeight,
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
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20,),

                    if(feedback != '') ... [
                      JellyfishBanner(message: feedback)
                    ]
                  ],
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
}
