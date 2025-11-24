import 'package:flutter/material.dart';
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

  int _currentStep = 0; // 0-4
  bool _isNextEnabled = false;

  final List<String> _questions = const [
    '나는 무엇을 배웠나?',
    '내가 소중히 여기는 삶의 가치를 \n떠올려보며, 이 교육이 어떤 도움을 주는가?',
    '이런 교육들이 왜 가치 있는 \n실천인가?',
    '배운 것들을 활용하며, \n앞으로 불안이 느껴진다면 어떻게 \n대처할 것인가?',
    '이러한 건강한 생활 습관 계획들이 불안 완화에 어떻게 영향을 \n미칠 것인가?',
  ];

  // 스타일
  static const double _sidePad = 34.0;
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
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => Week8MaintenanceSuggestionsScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
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

  // ✅ 여기 추가: 네가 준 진행바 버전
  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '질문 ${_currentStep + 1}',
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                color: Color(0xFF356D91),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_currentStep + 1}/${_questions.length}',
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                color: Color(0xFF356D91),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _questions.length,
            backgroundColor: const Color(0xFFFFFFFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF74D2FF)),
            minHeight: 8,
          ),
        ),
      ],
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
          child: Column(
            children: [
              // 위쪽: 스크롤 가능한 영역
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(_sidePad, 20, _sidePad, 24),
                  child: Column(
                    children: [
                      // ✅ 프로그레스 바
                      _buildProgressBar(),
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
                                    color:
                                    const Color(0xFF718096).withValues(alpha: 0.6),
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

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),

              // 아래: 항상 바닥에 붙는 네비게이션
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: NavigationButtons(
                  onBack: _previousStep,
                  onNext: _isNextEnabled ? _nextStep : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
