import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/features/7th_treatment/week7_gain_lose_screen.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';

const Color _navy = Color(0xFF263C69);
const Color _blue = Color(0xFF339DF1);
const double _sidePad = 34.0;
const Color _matrixLineBlue = Color(0xFF8ED7FF); // 라인/보더 톤
const Color _matrixGlowBlue = Color(0x338ED7FF); // 글로우(투명도 포함)

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
    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const CustomAppBar(title: '7주차 - 생활 습관 개선'),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_sidePad, 24, _sidePad, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목 카드
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _matrixLineBlue, width: 1.6),
                    boxShadow: const [
                      BoxShadow(
                        color: _matrixGlowBlue,
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '왜 불안 회피 행동이',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '건강한 생활 습관이라고',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '생각하세요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 설명 배너
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 3 / 4,
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.80),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '자유롭게 설명을 적어보세요!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                /// 입력 카드
                Stack(
                  clipBehavior: Clip.none, // 카드 밖으로 자연스럽게 튀어나오게
                  children: [
                    Container(
                      height: 200,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
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

                    const Positioned(
                      left: 10,
                      top: -60,
                      child: IgnorePointer(
                        child: Image(
                          image: AssetImage('assets/image/jellyfish.png'),
                          width: 85,
                          height: 85,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 100),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(_sidePad, 8, _sidePad, 16),
          child: NavigationButtons(
            leftLabel: '이전',
            rightLabel: '다음',
            onBack: () => Navigator.pop(context),
            onNext:
                _isNextEnabled
                    ? () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (_, __, ___) => Week7GainLoseScreen(
                                behavior: widget.behavior,
                              ),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                    : null,
          ),
        ),
      ),
    );
  }
}
