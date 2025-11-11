import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

/// 🌊 Mindrium ABC Activate Design (리뉴얼 버전)
/// - MemoFullDesign 스타일 기반
/// - 상단: CustomAppBar
/// - 중앙: memo.png 안에 이미지 + 텍스트
/// - 배경: eduhome.png (풀 화면)
class AbcActivateDesign extends StatelessWidget {
  final String appBarTitle;           // ✅ 주차별 제목을 주입받게 변경
  final String descriptionText;
  final String scenarioImage;         // 주입받은 상황 이미지
  final VoidCallback onBack;
  final VoidCallback onNext;

  /// 메모 높이 비율(화면 높이 대비). 기본 0.75
  final double memoHeightFactor;

  const AbcActivateDesign({
    super.key,
    required this.appBarTitle,
    required this.descriptionText,
    required this.scenarioImage,
    required this.onBack,
    required this.onNext,
    this.memoHeightFactor = 0.75,
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
          /// 🌊 배경
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.65),
              filterQuality: FilterQuality.high,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 📝 메모지 영역
                    Container(
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
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              /// 📷 상단 시나리오 이미지
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  scenarioImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 160,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Text('이미지를 불러올 수 없습니다'),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              /// 📖 설명 텍스트
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

                    const SizedBox(height: 40),

                    /// ⬇️ 하단 네비게이션 버튼
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
