import 'package:flutter/material.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_input_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_activate_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';

class AbcGuideScreen extends StatefulWidget {
  const AbcGuideScreen({super.key});

  @override
  State<AbcGuideScreen> createState() => _AbcGuideScreenState();
}

class _AbcGuideScreenState extends State<AbcGuideScreen> {
  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '2주차 - ABC 모델',
      cardTitle: 'ABC 모델이란?',
      onBack: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AbcInputScreen(showGuide: false),
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

      /// 💠 카드 내부 콘텐츠
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology, size: 68, color: Color(0xFF3F51B5)),
          const SizedBox(height: 24),
          const Text(
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

          const SizedBox(height: 36),

          /// 🪸 하단 안내문 (요청하신 스타일)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF5DADEC).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'ABC 모델은 감정의 원인을 이해하고 사고를 바꾸는 연습의 기초가 됩니다!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263C69),
                        fontFamily: 'Noto Sans KR',
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    bottom: -25,
                    child: Image.asset(
                      'assets/image/jellyfish_smart.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          ),
        ],
      ),
    );
  }
}
