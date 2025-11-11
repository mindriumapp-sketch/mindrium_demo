import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';
import 'package:gad_app_team/features/8th_treatment/week8_maintenance_suggestions_screen.dart';

class Week8UserJourneyScreen extends StatefulWidget {
  const Week8UserJourneyScreen({super.key});

  @override
  State<Week8UserJourneyScreen> createState() => _Week8UserJourneyScreenState();
}

class _Week8UserJourneyScreenState extends State<Week8UserJourneyScreen> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (index) => TextEditingController(),
  );

  int _currentStep = 0; // 0-4: 5개 질문
  bool _isNextEnabled = false;

  final List<String> _questions = const [
    '나는 무엇을 배웠나?',
    '내가 소중히 여기는 삶의 가치를 떠올려보며, 이 교육이 어떤 도움을 주는가?',
    '이런 교육들이 왜 가치 있는 실천인가?',
    '배운 것들을 활용하며, 앞으로 불안이 느껴진다면 어떻게 대처할 것인가?',
    '이러한 건강한 생활 습관 계획들이 불안 완화에 어떻게 영향을 미칠것인 생각해보기',
  ];

  // 스타일(배경/패딩/색상)
  static const double _sidePad = 34.0;
  static const Color _bluePrimary = Color(0xFF339DF1);
  static const Color _matrixLineBlue = Color(0xFF8ED7FF);

  @override
  void initState() {
    super.initState();
    for (var c in _controllers) {
      c.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isNextEnabled = _controllers[_currentStep].text.trim().isNotEmpty;
    });
  }

  void _nextStep() {
    if (_currentStep < _questions.length - 1) {
      setState(() {
        _currentStep++;
        _isNextEnabled = _controllers[_currentStep].text.trim().isNotEmpty;
      });
    } else {
      _showCompletionDialog();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _isNextEnabled = _controllers[_currentStep].text.trim().isNotEmpty;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.35),
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: _bluePrimary.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/image/jellyfish_blue_congrats.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),

                  /// 타이틀
                  const Text(
                    '여정 회고 완료!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// 안내문 (연한 블루 박스)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF8FF).withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFB9EAFD),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          '8주간의 여정을',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '성공적으로 되돌아보셨습니다!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF339DF1), // BluePrimary
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          '앞으로도 건강한 생활 습관을 꾸준히 실천하여\n더 나은 나를 만들어가세요 💪',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Color(0xFF356D91),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    const Week8MaintenanceSuggestionsScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _bluePrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '다음으로',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '8주차 - 여정 회고'),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_sidePad, 20, _sidePad, 24),
            child: Column(
              children: [
                // 상단 인디케이터
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '질문 ${_currentStep + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF718096),
                      ),
                    ),
                    Text(
                      '${_currentStep + 1}/${_questions.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 질문 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x338AD7FF),
                        blurRadius: 42,
                        spreadRadius: 2,
                        offset: Offset(0, 18),
                      ),
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 28,
                        offset: Offset(0, 12),
                      ),
                      BoxShadow(
                        color: Color(0x1A339DF1),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/image/jellyfish_blue.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _questions[_currentStep],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3748),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '답변을 작성해주세요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _matrixLineBlue,
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: _controllers[_currentStep],
                          maxLines: 8,
                          onChanged: (_) => _onTextChanged(),
                          decoration: InputDecoration(
                            hintText: '여기에 답변을 작성해주세요...',
                            hintStyle: TextStyle(
                              color: const Color(0xFF718096).withOpacity(0.6),
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Color(0xFF8ED7FF),
                                width: 1.8,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // 하단 네비 버튼
        bottomNavigationBar: SafeArea(
          child: Material(
            type: MaterialType.transparency,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_sidePad, 8, _sidePad, 24),
              child: NavigationButtons(
                onBack: _previousStep,
                onNext: _isNextEnabled ? _nextStep : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
