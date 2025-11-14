import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/data/user_pretest.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';

/// 앱 사용법을 안내하는 튜토리얼 화면
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_IntroData> pages = const [
    _IntroData(
      imagePath: 'assets/image/intro1.png',
      title: '하루의 시작을 함께',
      description: '오늘의 할 일과 리포트를\n한눈에 확인하세요.',
    ),
    _IntroData(
      imagePath: 'assets/image/intro2.png',
      title: '감정과 생각을 기록해요',
      description: '감정일기, 명상, 노출치료 등\n다양한 도구를 제공합니다.',
    ),
    _IntroData(
      imagePath: 'assets/image/intro3.png',
      title: '나의 변화 추적',
      description: '통계를 통해 마음의 흐름을\n시각적으로 확인할 수 있어요.',
    ),
  ];

  Future<void> _goNext() async {
    if (_currentIndex < pages.length - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
      return;
    }
    final hasSurvey = await UserDatabase.hasCompletedSurvey();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      hasSurvey ? '/home' : '/before_survey',
    );
  }

  Future<void> _skipTutorial() async {
    final hasSurvey = await UserDatabase.hasCompletedSurvey();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      hasSurvey ? '/home' : '/before_survey',
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDotColor = const Color(0xFF32A4EF);
    final inactiveDotColor = const Color(0xFFDBDBDB);

    return Scaffold(
      backgroundColor: AppColors.grey100,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 우측 '건너뛰기'
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _skipTutorial,
                  child: const Text(
                    '건너뛰기',
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // 본문
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemBuilder: (context, index) {
                  final data = pages[index];
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.padding,
                      ),
                      child: IntroSlide(
                        imagePath: data.imagePath,
                        title: data.title,
                        description: data.description,
                      ),
                    ),
                  );
                },
              ),
            ),

            // ✅ 아래쪽 한 줄짜리 도트 인디케이터만 남김
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final active = i == _currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? activeDotColor : inactiveDotColor,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),

            // 버튼
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  onPressed: _goNext,
                  text: _currentIndex == pages.length - 1 ? '시작하기' : '다음',
                ),
              ),
            ),
            const SizedBox(height: AppSizes.space),
          ],
        ),
      ),
    );
  }
}

/// 단일 인트로 슬라이드
class IntroSlide extends StatelessWidget {
  final String imagePath;
  final String title;
  final String description;

  const IntroSlide({
    super.key,
    required this.imagePath,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final contentWidth = width * 0.86;

    return SizedBox(
      width: contentWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),

          // 이미지
          SizedBox(
            width: 160,
            height: 160,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 16),

          // 타이틀
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.1,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),

          // 설명
          SizedBox(
            width: 260,
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF868889),
                fontSize: 15,
                height: 1.4,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroData {
  final String imagePath;
  final String title;
  final String description;
  const _IntroData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
