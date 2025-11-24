import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/4th_treatment/week4_before_sud_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/widgets/ruled_paragraph.dart';

class Week4ImaginationScreen extends StatefulWidget {
  final int loopCount;
  const Week4ImaginationScreen({super.key, this.loopCount = 1});

  @override
  State<Week4ImaginationScreen> createState() => _Week4ImaginationScreenState();
}

class _Week4ImaginationScreenState extends State<Week4ImaginationScreen> {
  bool _isNextEnabled = false;
  int _secondsLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_secondsLeft <= 1) {
        setState(() {
          _secondsLeft = 0;
          _isNextEnabled = true;
        });
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final userName = provider.userName.isNotEmpty ? provider.userName : 'USER';
    // BlueWhiteCard에서 쓰던 밑줄 길이를 그대로 사용
    const double kRuleWidth = 220;

    return ApplyDesign(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      cardTitle: '상황 떠올리기',
      onBack: () => Navigator.pop(context),
      onNext: () {
        // ApplyDesign은 onNext null 비허용—탭 가드로 동작만 막아줌
        if (!_isNextEnabled) {
          BlueBanner.show(context, '$_secondsLeft초 후에 다음 버튼이 활성화됩니다');
          return;
        }
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const Week4BeforeSudScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      // ===== 카드 내부 본문 =====
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Image.asset(
            'assets/image/think_blue.png',
            height: 160,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 20),

          RuledParagraph(
            text: '$userName님, 이때의 상황을 \n자세히 생각해 보세요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3C55),
              height: 1.6,
            ),
            lineColor: Color(0xFFE1E8F0),
            lineThickness: 1.2,
            lineGapBelow: 8,
            padding: EdgeInsets.symmetric(horizontal: 4),
            lineWidth: kRuleWidth,
          ),

          const SizedBox(height: 16),
          if (!_isNextEnabled)
            Text(
              '$_secondsLeft초 후에 다음 버튼이 활성화됩니다',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9BA7B4),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
