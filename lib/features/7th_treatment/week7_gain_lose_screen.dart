// File: features/7th_treatment/week7_gain_lose_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/7th_treatment/week7_add_display_screen.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/behavior_confirm_dialog.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';

class Week7GainLoseScreen extends StatefulWidget {
  final String behavior;

  const Week7GainLoseScreen({super.key, required this.behavior});

  @override
  State<Week7GainLoseScreen> createState() => _Week7GainLoseScreenState();
}

class _Week7GainLoseScreenState extends State<Week7GainLoseScreen> {
  final TextEditingController _executionGainController =
      TextEditingController();
  final TextEditingController _executionLoseController =
      TextEditingController();
  final TextEditingController _nonExecutionGainController =
      TextEditingController();
  final TextEditingController _nonExecutionLoseController =
      TextEditingController();

  // 0: 단기적 이익, 1: 장기적 이익(예/아니오), 2: 하지 않았을 때 이익, 3: 단기적 불이익, 4: 장기적 불이익(예/아니오)
  int _currentStep = 0;
  bool _isNextEnabled = false;
  bool? _hasLongTermBenefit; // 장기적 이익 여부
  bool? _hasLongTermDisadvantage; // 장기적 불이익 여부

  static const double _sidePad = 34.0;
  static const Color _bluePrimary = Color(0xFF339DF1);

  @override
  void initState() {
    super.initState();
    _executionGainController.addListener(_onTextChanged);
    _executionLoseController.addListener(_onTextChanged);
    _nonExecutionGainController.addListener(_onTextChanged);
    _nonExecutionLoseController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _executionGainController.dispose();
    _executionLoseController.dispose();
    _nonExecutionGainController.dispose();
    _nonExecutionLoseController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      switch (_currentStep) {
        case 0:
          _isNextEnabled = _executionGainController.text.trim().isNotEmpty;
          break;
        case 1:
          _isNextEnabled = _hasLongTermBenefit != null;
          break;
        case 2:
          _isNextEnabled = _nonExecutionGainController.text.trim().isNotEmpty;
          break;
        case 3:
          _isNextEnabled = _executionLoseController.text.trim().isNotEmpty;
          break;
        case 4:
          _isNextEnabled = _hasLongTermDisadvantage != null;
          break;
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
        _isNextEnabled = false;
      });
    }
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return '회피 행동을 했을 때 단기적 이익';
      case 1:
        return '회피 행동을 했을 때 장기적 이익';
      case 2:
        return '회피 행동을 하지 않았을 때의 이익';
      case 3:
        return '회피 행동을 하지 않았을 때의 단기적 불이익';
      case 4:
        return '회피 행동을 하지 않았을 때의 장기적 불이익';
      default:
        return '';
    }
  }

  String _getStepDescription() {
    switch (_currentStep) {
      case 0:
        return '이 회피 행동을 했을 때\n즉시 얻을 수 있는 좋은 점은 무엇인가요?';
      case 1:
        return '이 회피 행동을 했을 때\n장기적으로 얻을 수 있는 이익이 있나요?';
      case 2:
        return '이 회피 행동을 하지 않았을 때\n얻을 수 있는 이익은 무엇인가요?';
      case 3:
        return '이 회피 행동을 하지 않았을 때\n즉시 겪을 수 있는 어려운 점은 무엇인가요?';
      case 4:
        return '이 회피 행동을 하지 않았을 때\n장기적으로 겪을 수 있는 어려운 점이 있나요?';
      default:
        return '';
    }
  }

  IconData _getStepIcon() {
    switch (_currentStep) {
      case 0:
        return Icons.flash_on;
      case 1:
        return Icons.timeline;
      case 2:
        return Icons.trending_up;
      case 3:
        return Icons.warning;
      case 4:
        return Icons.trending_down;
      default:
        return Icons.help;
    }
  }

  Color _getStepColor() => const Color.fromARGB(255, 104, 201, 253);

  TextEditingController _getCurrentController() {
    switch (_currentStep) {
      case 0:
        return _executionGainController;
      case 1:
        return _executionGainController; // (예/아니오 스텝에서는 사용 안함)
      case 2:
        return _nonExecutionGainController;
      case 3:
        return _executionLoseController;
      case 4:
        return _nonExecutionLoseController;
      default:
        return _executionGainController;
    }
  }

  Widget _buildYesNoSelector() {
    final isStep1 = _currentStep == 1;
    final question = isStep1 ? '장기적으로 이익이 있나요?' : '장기적으로 불이익이 있나요?';
    final currentValue =
        isStep1 ? _hasLongTermBenefit : _hasLongTermDisadvantage;

    const matrixBlue = Color(0xFF8ED7FF);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 예 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isStep1) {
                    _hasLongTermBenefit = true;
                  } else {
                    _hasLongTermDisadvantage = true;
                  }
                  _isNextEnabled = true;
                });
              },
              child: Container(
                width: 120,
                height: 60,
                decoration: BoxDecoration(
                  color: currentValue == true ? matrixBlue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        currentValue == true
                            ? matrixBlue
                            : const Color(0xFFBEE7FF),
                    width: 2,
                  ),
                  boxShadow:
                      currentValue == true
                          ? [
                            BoxShadow(
                              color: matrixBlue.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    '예',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: currentValue == true ? Colors.white : matrixBlue,
                    ),
                  ),
                ),
              ),
            ),

            // 아니오 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isStep1) {
                    _hasLongTermBenefit = false;
                  } else {
                    _hasLongTermDisadvantage = false;
                  }
                  _isNextEnabled = true;
                });
              },
              child: Container(
                width: 120,
                height: 60,
                decoration: BoxDecoration(
                  color: currentValue == false ? matrixBlue : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        currentValue == false
                            ? matrixBlue
                            : const Color(0xFFBEE7FF),
                    width: 2,
                  ),
                  boxShadow:
                      currentValue == false
                          ? [
                            BoxShadow(
                              color: matrixBlue.withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : [],
                ),
                child: Center(
                  child: Text(
                    '아니오',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: currentValue == false ? Colors.white : matrixBlue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return TextField(
      controller: _getCurrentController(),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: '여기에 입력해주세요...',
        hintStyle: TextStyle(
          fontSize: 16,
          color: Color.fromARGB(255, 108, 119, 139).withOpacity(0.5),
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF2D3748),
        height: 1.5,
      ),
    );
  }

  void _showAddToHealthyHabitsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (BuildContext context) {
        return BehaviorConfirmDialog(
          titleText: '건강한 생활 습관 추가',
          highlightText: '[${widget.behavior}]',
          messageText: '이 행동을 건강한 생활 습관에 추가하시겠습니까?',
          onNegativePressed: () {
            Navigator.of(context).pop();
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const Week7AddDisplayScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          onPositivePressed: () {
            // 1) 팝업 닫기
            Navigator.of(context).pop();

            // 2) 전역 상태에 즉시 반영 -> 목록에서 바로 "추가됨 + 제거하기"로 보이게
            final updated = Set<String>.from(
              Week7AddDisplayScreen.globalAddedBehaviors,
            )..add(widget.behavior);
            Week7AddDisplayScreen.updateGlobalAddedBehaviors(updated);

            // 3) 목록으로 돌아가기 (초기 자동표시는 건너뛰도록 deferInitialMarkAsAdded=false)
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder:
                    (_, __, ___) => Week7AddDisplayScreen(
                      initialBehavior: widget.behavior,
                      deferInitialMarkAsAdded: false, // <- 바로 표시용
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
          badgeBgAsset: 'assets/image/popup1.png',
          memoBgAsset: '',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '7주차 - 생활 습관 개선'),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_sidePad, 16, _sidePad, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),

                Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 4 ? 8 : 0),
                        decoration: BoxDecoration(
                          color:
                              index <= _currentStep
                                  ? _getStepColor()
                                  : Colors.white.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 20),

                // 메인 카드
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x338AD7FF),
                        blurRadius: 38,
                        offset: Offset(0, 16),
                      ),
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 26,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/image/jellyfish_pink.png',
                        width: 76,
                        height: 76,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 14),

                      Text(
                        _getStepTitle(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2D3748),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        _getStepDescription(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF718096),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),

                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF).withOpacity(0.6),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child:
                            (_currentStep == 1 || _currentStep == 4)
                                ? _buildYesNoSelector()
                                : _buildTextInput(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),

        bottomNavigationBar: Material(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_sidePad, 8, _sidePad, 16),
              child: NavigationButtons(
                leftLabel: '이전',
                rightLabel: '다음',
                onBack: () {
                  if (_currentStep > 0) {
                    setState(() {
                      _currentStep--;
                      _onTextChanged();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                onNext:
                    _isNextEnabled
                        ? () {
                          if (_currentStep < 4) {
                            _nextStep();
                          } else {
                            _showAddToHealthyHabitsDialog();
                          }
                        }
                        : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
