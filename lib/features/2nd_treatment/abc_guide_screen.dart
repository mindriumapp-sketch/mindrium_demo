import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:gad_app_team/features/2nd_treatment/abc_input_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/week2_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_activate_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/widgets/blue_banner.dart'; // CustomBanner 들어있다고 가정

class AbcGuideScreen extends StatefulWidget {
  const AbcGuideScreen({super.key});

  @override
  State<AbcGuideScreen> createState() => _AbcGuideScreenState();
}

class _AbcGuideScreenState extends State<AbcGuideScreen> {
  bool _showBanner = true;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CustomBanner.show(context);      // 들어올 때 배너
      _startBannerTimer();             // 5초 후 해파리 나타나게
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _showBanner = false;
      });
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 1) 카드 포함 전체 화면
        ApplyDesign(
          appBarTitle: '2주차 - ABC 모델',
          cardTitle: 'ABC 모델이란?',
          onBack: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const Week2Screen(),
              ),
            );
          },
          onNext: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => AbcActivateScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.psychology, size: 68, color: Color(0xFF3F51B5)),
              SizedBox(height: 24),
              Text(
                'ABC 모델은 인지행동치료(Cognitive Behavioral Therapy, CBT)에서 사용되는 대표적인 기법 중 하나로, '
                    '사람의 정서적 반응과 행동이 특정 사건 자체보다는 그 사건에 대한 생각(믿음)에 의해 결정된다는 개념을 바탕으로 합니다.\n\n'
                    '이 모델은 심리학자 앨버트 엘리스가 1950년대에 개발한 '
                    '합리적 정서행동치료(REBT)의 핵심 구성 요소로 소개되었습니다.\n\n'
                    '앞으로 걱정 일기를 매일 작성하면서, 인지행동치료(CBT)의 핵심 기법인 ABC 모델을 기반으로 기록할 것입니다.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                  fontFamily: 'Noto Sans KR',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 36),
            ],
          ),
        ),

        // 2) 카드 “바깥” 우상단에 해파리 올리기
        if (!_showBanner)
          Positioned(
            // 이 값들이 바로 네가 빨간색으로 칠한 자리
            // 필요하면 살짝씩 조절해
            top: 85,        // 앱바 높이 + 카드 위 여백 대략
            right: 40,       // 카드 오른쪽 여백 맞춰서
            child: GestureDetector(
              onTap: () {
                CustomBanner.show(context);
                setState(() {
                  _showBanner = true;
                });
                _startBannerTimer();
              },
              child: Image.asset(
                'assets/image/jellyfish_smart.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
            ),
          ),
      ],
    );
  }
}
