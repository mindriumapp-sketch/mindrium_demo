import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import '../../common/constants.dart';
import 'abc_visualization_screen.dart';
import 'step_a_view.dart';
import 'step_b_view.dart';
import 'step_c_view.dart';
import 'abc_dialogs.dart';
import 'abc_tutorial_message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'abc_guide_screen.dart';
import 'abc_real_start_screen.dart';

class GridItem {
  final IconData icon;
  final String label;
  final bool isAdd;
  const GridItem({required this.icon, required this.label, this.isAdd = false});
}

class AbcInputScreen extends StatefulWidget {
  final bool isExampleMode;
  final Map<String, String>? exampleData;
  final bool showGuide;
  final String? abcId;
  final String? origin;

  const AbcInputScreen({
    super.key,
    this.isExampleMode = false,
    this.exampleData,
    this.showGuide = true,
    this.abcId,
    this.origin,
  });

  @override
  State<AbcInputScreen> createState() => _AbcInputScreenState();
}

class _AbcInputScreenState extends State<AbcInputScreen> {
  int _currentStep = 0;
  int _currentCSubStep = 0;

  // 선택 상태
  final Set<int> _selectedAGrid = {};
  final Set<int> _selectedBGrid = {};
  final Set<int> _selectedPhysical = {};
  final Set<int> _selectedEmotion = {};
  final Set<int> _selectedBehavior = {};

  late bool _showGuide;

  @override
  void initState() {
    super.initState();
    _showGuide = widget.showGuide;
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
        if (_currentStep == 2) _currentCSubStep = 0;
      } else if (_currentCSubStep < 2) {
        _currentCSubStep++;
      } else {
        // 시각화 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AbcVisualizationScreen(
                  activatingEventChips: [],
                  beliefChips: [],
                  resultChips: [],
                  feedbackEmotionChips: [],
                  isExampleMode: widget.isExampleMode,
                  selectedPhysicalChips: [],
                  selectedEmotionChips: [],
                  selectedBehaviorChips: [],
                ),
          ),
        );
      }
    });
  }

  void _previousStep() {
    setState(() {
      if (_currentStep == 2 && _currentCSubStep > 0) {
        _currentCSubStep--;
      } else if (_currentStep > 0) {
        _currentStep--;
      } else {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showGuide) return const AbcGuideScreen();

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.isExampleMode ? '예시 연습하기' : '2주차 - ABC 모델',
        // ✅ 뒤로가기 동작
        onBack: () {
          if (_currentStep == 0 && _currentCSubStep == 0) {
            Navigator.pop(context);
          } else {
            _previousStep();
          }
        },
        // ✅ 홈 버튼 동작
        onHomePressed: () {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        },
      ),
      backgroundColor: const Color(0xFFFBF8FF),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildStepContent(),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          leftLabel: '이전',
          rightLabel:
              _currentStep < 2 ? '다음' : (_currentCSubStep < 2 ? '다음' : '확인'),
          onBack: _previousStep,
          onNext: _nextStep,
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return StepAView(
          selectedAGrid: _selectedAGrid,
          onChipTap: (index, selected) {
            setState(() {
              if (selected) {
                _selectedAGrid.add(index);
              } else {
                _selectedAGrid.remove(index);
              }
            });
          },
        );
      case 1:
        return StepBView(selectedBGrid: _selectedBGrid);
      case 2:
        return StepCView(
          selectedPhysical: _selectedPhysical,
          selectedEmotion: _selectedEmotion,
          selectedBehavior: _selectedBehavior,
          subStep: _currentCSubStep,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
