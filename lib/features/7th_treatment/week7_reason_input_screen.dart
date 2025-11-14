import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/7th_treatment/week7_gain_lose_screen.dart';

// ✅ 방금 네가 준 더블카드 UI
import 'package:gad_app_team/widgets/top_btm_card.dart';

const Color _navy = Color(0xFF263C69);
const Color _blue = Color(0xFF339DF1);
const Color _matrixLineBlue = Color(0xFF8ED7FF);
const Color _matrixGlowBlue = Color(0x338ED7FF);

class Week7ReasonInputScreen extends StatefulWidget {
  final String behavior;

  const Week7ReasonInputScreen({super.key, required this.behavior});

  @override
  State<Week7ReasonInputScreen> createState() => _Week7ReasonInputScreenState();
}

class _Week7ReasonInputScreenState extends State<Week7ReasonInputScreen> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isNextEnabled = false;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() {
      setState(() => _isNextEnabled = _reasonController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // 빈 공간 탭도 잡게
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ApplyDoubleCard(
        appBarTitle: '7주차 - 생활 습관 개선',
        // 위쪽 패널
        topChild: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SizedBox(height: 12),
            Text(
              '왜 불안 회피 행동이\n건강한 생활 습관이라고\n생각하세요?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _navy,
                height: 1.6,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
        middleNoticeText: '자유롭게 설명을 적어보세요!',
        topPadding: 10,
        height: 100,

        // 아래쪽 패널
        bottomChild: SizedBox(
          height: 200,
          child: TextField(
            controller: _reasonController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: '여기에 입력해주세요...',
              hintStyle: TextStyle(
                fontSize: 16,
                color: Color(0xFFA0AEC0),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
              height: 1.5,
            ),
          ),
        ),

        // 네비게이션
        onBack: () => Navigator.pop(context),
        onNext: _isNextEnabled
            ? () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => Week7GainLoseScreen(
                behavior: widget.behavior,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
            : null,

        pagePadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 20),
        panelsGap: 26,
      ),
    );
  }
}
