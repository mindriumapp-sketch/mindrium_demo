import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

class AbcActivateDesign extends StatelessWidget {
  final String appBarTitle;
  final String descriptionText;
  final String scenarioImage;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final double memoHeightFactor;

  const AbcActivateDesign({
    super.key,
    required this.appBarTitle,
    required this.descriptionText,
    required this.scenarioImage,
    required this.onBack,
    required this.onNext,
    this.memoHeightFactor = 0.67,
  });

  @override
  Widget build(BuildContext context) {
    final double memoHeight =
        MediaQuery.of(context).size.height * memoHeightFactor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: appBarTitle),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
              filterQuality: FilterQuality.high,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 위쪽: 중앙에 메모지
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 34,
                        vertical: 24,
                      ),
                      child: Container(
                        height: memoHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: const DecorationImage(
                            image: AssetImage('assets/image/memo.png'),
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AspectRatio(
                                    aspectRatio: 4 / 5,
                                    child: Image.asset(
                                      scenarioImage,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Text('이미지를 불러올 수 없습니다'),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  descriptionText,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: Color(0xFF232323),
                                    fontSize: 15.5,
                                    fontFamily: 'Noto Sans KR',
                                    height: 1.6,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // 아래: 항상 고정되는 네비게이션
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
