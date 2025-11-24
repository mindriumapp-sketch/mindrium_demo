// File: features/8th_treatment/week8_gad7_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/features/8th_treatment/week8_survey_screen.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/survey_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week8Gad7Screen extends StatefulWidget {
  const Week8Gad7Screen({super.key});

  @override
  State<Week8Gad7Screen> createState() => _Week8Gad7ScreenState();
}

class _Week8Gad7ScreenState extends State<Week8Gad7Screen> {
  final List<int> _answers = List.filled(7, -1);
  bool _isCompleted = false;
  bool _isSubmitting = false;

  // API 클라이언트
  late final ApiClient _apiClient;
  late final SurveyApi _surveyApi;

  final List<String> _questions = [
    '최근 2주간, 초조하거나 불안하거나 조마조마하게 느낀다.',
    '최근 2주간, 걱정하는 것을 멈추거나 조절할 수가 없다.',
    '최근 2주간, 여러 가지 것들에 대해 걱정을 너무 많이 한다.',
    '최근 2주간, 편하게 있기가 어렵다.',
    '최근 2주간, 쉽게 짜증이 나거나 쉽게 성을 내게 된다.',
    '최근 2주간, 너무 안절부절못해서 가만히 있기가 힘들다.',
    '최근 2주간, 마치 끔찍한 일이 생길 것처럼 두렵게 느껴진다.',
  ];

  final List<String> _options = ['없음', '2~3일 이상', '7일 이상', '거의 매일'];

  void _selectAnswer(int q, int a) {
    setState(() {
      _answers[q] = a;
      _isCompleted = _answers.every((v) => v >= 0);
    });
  }

  int _score() => _answers.reduce((a, b) => a + b);

  String _interpret(int score) {
    if (score <= 4) return '🌱 최소한의 불안';
    if (score <= 9) return '🌿 경미한 불안';
    if (score <= 14) return '🌊 중등도의 불안';
    return '💧 심한 불안';
  }

  Color _tone(int score) {
    if (score <= 4) return const Color(0xFF66D0F9);
    if (score <= 9) return const Color(0xFF4FC3F7);
    if (score <= 14) return const Color(0xFF42A5F5);
    return const Color(0xFF1976D2);
  }

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(tokens: TokenStorage());
    _surveyApi = SurveyApi(_apiClient);
  }

  Future<void> _submitAndNavigate() async {
    if (_isSubmitting || !_isCompleted) return;
    setState(() => _isSubmitting = true);

    try {
      final score = _score();
      await _surveyApi.submitSurvey(
        surveyType: 'after_survey',
        answers: {'gad7_answers': _answers, 'gad7_score': score},
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Week8SurveyScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      BlueBanner.show(context, '설문 제출에 실패했습니다: $e');
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '8주차 - 불안 평가',
      cardTitle: 'Mindrium 사용 후\n불안이 얼마나 줄었나요?',
      onBack: () => Navigator.pop(context),
      onNext:
          _isCompleted
              ? _submitAndNavigate
              : () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('모든 문항에 답해주세요.'))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          JellyfishBanner(message: '지난 2주 동안의 불안 증상을 \n아래 항목에 따라 평가해주세요.'),
          const SizedBox(height: 30),
          ...List.generate(_questions.length, _buildQuestionCard),
          const SizedBox(height: 28),
          if (_isCompleted) _buildResultCard(),
        ],
      ),
    );
  }

  /// 🌊 질문 카드
  Widget _buildQuestionCard(int i) {
    final question = _questions[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9EAFD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74D2FF).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문 헤더
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF74D2FF), Color(0xFF99E0FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B3A57),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 선택지
          ...List.generate(_options.length, (j) => _buildOption(i, j)),
        ],
      ),
    );
  }

  /// 🔘 선택지 버튼
  Widget _buildOption(int q, int opt) {
    final selected = _answers[q] == opt;
    return GestureDetector(
      onTap: () => _selectAnswer(q, opt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F3FA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF74D2FF) : const Color(0xFFE2E8F0),
            width: selected ? 1.8 : 1,
          ),
          boxShadow:
              selected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF74D2FF).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF74D2FF) : Colors.transparent,
                border: Border.all(
                  color:
                      selected
                          ? const Color(0xFF74D2FF)
                          : const Color(0xFFCBD5E0),
                  width: 2,
                ),
              ),
              child:
                  selected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
            ),
            const SizedBox(width: 14),
            Text(
              _options[opt],
              style: TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 15,
                color:
                    selected
                        ? const Color(0xFF1B3A57)
                        : const Color(0xFF4A5568),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 💧 결과 카드
  Widget _buildResultCard() {
    final score = _score();
    final color = _tone(score);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: color, size: 26),
              const SizedBox(width: 10),
              const Text(
                '평가 결과',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B3A57),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '$score점',
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _interpret(score),
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF718096),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1주차와 비교하여 불안 수준의 변화를 확인해보세요.',
                  style: TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 14,
                    color: Color(0xFF718096),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
