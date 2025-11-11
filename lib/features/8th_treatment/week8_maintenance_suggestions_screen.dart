// File: features/8th_treatment/week8_maintenance_suggestions_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';

class Week8MaintenanceSuggestionsScreen extends StatefulWidget {
  const Week8MaintenanceSuggestionsScreen({super.key});

  @override
  State<Week8MaintenanceSuggestionsScreen> createState() =>
      _Week8MaintenanceSuggestionsScreenState();
}

class _Week8MaintenanceSuggestionsScreenState
    extends State<Week8MaintenanceSuggestionsScreen> {
  int _currentStep = 0;
  final bool _isNextEnabled = true;

  final List<String> _suggestions = [
    '연습을 매일 하세요. 비록 짧은 시간이라도 괜찮습니다.',
    '가능하다면 매일 같은 시간, 같은 장소에서 연습하세요.',
    '연습을 해야 할 일 목록의 하나로 생각하기보다, 자신을 돌보는 방법으로 여기세요.',
    '다른 사람들과 함께 연습할 수 있는 방법을 찾아보세요.',
    '어려움이 오면 언제든 이 앱으로 돌아와 다시 시작할 수 있다는 것을 기억하세요.',
  ];

  void _nextStep() {
    if (_currentStep < _suggestions.length - 1) {
      setState(() => _currentStep++);
    } else {
      _showCompletionDialog();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.white.withOpacity(0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF74D2FF), Color(0xFF99E0FF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF74D2FF).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '8주차 완료!',
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3A57),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '8주간의 여정을 성공적으로 완주하셨습니다 🎉\n앞으로도 꾸준히 자신을 돌보세요.',
                    style: TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 14,
                      color: Color(0xFF356D91),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamedAndRemoveUntil('/home', (_) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF74D2FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      '홈으로 돌아가기',
                      style: TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
    return ApplyDesign(
      appBarTitle: '8주차 - 유지방법 제안',
      cardTitle: '건강한 습관을 지속하기 위한 다섯 가지 제안',
      onBack: _previousStep,
      onNext: _isNextEnabled ? _nextStep : () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProgressBar(),
          const SizedBox(height: 20),
          ...List.generate(_currentStep + 1, _buildSuggestionCard),
        ],
      ),
    );
  }

  /// 💧 진행 상태 바
  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '제안 ${_currentStep + 1}',
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                color: Color(0xFF356D91),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_currentStep + 1}/${_suggestions.length}',
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
            value: (_currentStep + 1) / _suggestions.length,
            backgroundColor: const Color(0xFFE6F3FA),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF74D2FF)),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// 🌿 제안 카드
  Widget _buildSuggestionCard(int index) {
    final text = _suggestions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB9EAFD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF74D2FF).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 번호 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF74D2FF), Color(0xFF99E0FF)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 내용
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 15,
                color: Color(0xFF1B3A57),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
