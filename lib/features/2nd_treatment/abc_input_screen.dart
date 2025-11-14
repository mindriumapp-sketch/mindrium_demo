import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';

import 'abc_visualization_screen.dart';
import 'step_a_view.dart';
import 'step_b_view.dart';
import 'step_c_view.dart';
import 'abc_guide_screen.dart';
import 'abc_real_start_screen.dart';

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

  final Set<int> _selectedAGrid = {};
  final Set<int> _selectedBGrid = {};
  final Set<int> _selectedPhysical = {};
  final Set<int> _selectedEmotion = {};
  final Set<int> _selectedBehavior = {};

  final List<String> _aSituations = ['회의', '수업', '모임'];
  final List<String> _bBeliefs = [
    '사람들이 나를 안 좋게 볼 거야',
    '실수하면 큰일 나',
    '비난받을까 봐 두려워',
  ];
  final List<String> _cPhysical = ['두근거림', '메스꺼움', '식은땀', '불면'];
  final List<String> _cEmotion = ['불안', '분노', '슬픔', '두려움'];
  final List<String> _cBehavior = ['결석', '전화 안 받기', '약속 피하기', '시선 피하기'];

  late bool _showGuide;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final UserDataApi _userDataApi = UserDataApi(_apiClient);
  bool _loadingCustomTags = false;

  @override
  void initState() {
    super.initState();
    _showGuide = widget.showGuide;

    if (widget.isExampleMode) {
      if (!_aSituations.contains('자전거를 타려고 함')) {
        _aSituations.insert(0, '자전거를 타려고 함');
      }
      if (!_bBeliefs.contains('넘어질까봐 두려움')) {
        _bBeliefs.insert(0, '넘어질까봐 두려움');
      }
      if (!_cBehavior.contains('자전거를 타지 않았어요')) {
        _cBehavior.insert(0, '자전거를 타지 않았어요');
      }
    }

    if (!widget.isExampleMode) {
      Future.microtask(_loadCustomTags);
    }
  }

  // ✅ 칩 선택 여부에 따라 다음 버튼 활성화
  // ✅ 다음 버튼 활성화 조건
  bool get _isNextEnabled {
    switch (_currentStep) {
      case 0:
        return _selectedAGrid.isNotEmpty;
      case 1:
        return _selectedBGrid.isNotEmpty;
      case 2:
        if (_currentCSubStep == 0) return _selectedPhysical.isNotEmpty;
        if (_currentCSubStep == 1) return _selectedEmotion.isNotEmpty;
        if (_currentCSubStep == 2) return _selectedBehavior.isNotEmpty;
        return false;
      default:
        return false;
    }
  }

  Future<void> _loadCustomTags() async {
    if (_loadingCustomTags) return;
    setState(() => _loadingCustomTags = true);
    try {
      final tags = await _userDataApi.getCustomTags();
      if (!mounted) return;
      setState(() {
        for (final tag in tags) {
          final type = (tag['type'] ?? '').toString();
          final text = (tag['text'] ?? '').toString();
          if (text.isEmpty) continue;
          _addTagToList(type, text, allowDuplicate: false);
        }
      });
    } catch (e) {
      debugPrint('커스텀 태그 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loadingCustomTags = false);
    }
  }

  void _addTagToList(String type, String text, {bool allowDuplicate = true}) {
    List<String>? target;
    switch (type) {
      case 'A':
        target = _aSituations;
        break;
      case 'B':
        target = _bBeliefs;
        break;
      case 'CP':
        target = _cPhysical;
        break;
      case 'CE':
        target = _cEmotion;
        break;
      case 'CB':
        target = _cBehavior;
        break;
    }
    if (target == null) return;
    if (!allowDuplicate && target.contains(text)) return;
    target.add(text);
  }

  Future<void> _saveCustomTag({
    required String type,
    required String text,
    required VoidCallback onSuccess,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      await _userDataApi.createCustomTag(text: trimmed, type: type);
      if (!mounted) return;
      setState(onSuccess);
    } on DioException catch (e) {
      final message =
          e.response?.data is Map
              ? e.response?.data['detail']?.toString()
              : e.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추가에 실패했습니다: ${message ?? '오류'}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('추가에 실패했습니다: $e')),
      );
    }
  }

  // ✅ 팝업을 통한 칩 추가 함수 (입력칸 포함)
  Future<void> _showAddPopup({
    required String title,
    required String highlightText,
    required Function(String text) onConfirm,
  }) async {
    final TextEditingController controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) {
        return CustomPopupDesign(
          title: title,
          highlightText: highlightText,
          message: '',
          positiveText: '추가',
          negativeText: '취소',
          onPositivePressed: () {
            final text = controller.text.trim();
            if (text.isNotEmpty) {
              onConfirm(text);
            }
            Navigator.pop(ctx);
          },
          onNegativePressed: () => Navigator.pop(ctx),
          enableInput: true, // ✅ 입력칸 활성화
          controller: controller,
          inputHint: '새로운 항목을 입력해주세요',
        );
      },
    );
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
        if (_currentStep == 2) _currentCSubStep = 0;
      } else if (_currentCSubStep < 2) {
        _currentCSubStep++;
      } else {
        if (widget.isExampleMode) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AbcRealStartScreen()),
          );
        } else {
          final activatingLabels =
              _selectedAGrid.map((i) => _aSituations[i]).toList();
          final beliefLabels = _selectedBGrid.map((i) => _bBeliefs[i]).toList();
          final resultLabels = <String>[
            ..._selectedEmotion.map((i) => _cEmotion[i]),
            ..._selectedPhysical.map((i) => _cPhysical[i]),
            ..._selectedBehavior.map((i) => _cBehavior[i]),
          ];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AbcVisualizationScreen(
                    activatingEventChips:
                        activatingLabels
                            .map((s) => GridItem(icon: Icons.circle, label: s))
                            .toList(),
                    beliefChips:
                        beliefLabels
                            .map((s) => GridItem(icon: Icons.circle, label: s))
                            .toList(),
                    resultChips:
                        resultLabels
                            .map((s) => GridItem(icon: Icons.circle, label: s))
                            .toList(),
                    feedbackEmotionChips: const [],
                    selectedPhysicalChips:
                        _selectedPhysical.map((i) => _cPhysical[i]).toList(),
                    selectedEmotionChips:
                        _selectedEmotion.map((i) => _cEmotion[i]).toList(),
                    selectedBehaviorChips:
                        _selectedBehavior.map((i) => _cBehavior[i]).toList(),
                    isExampleMode: widget.isExampleMode,
                    origin: widget.origin,
                  ),
            ),
          );
        }
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
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: widget.isExampleMode ? '예시 연습하기' : '2주차 - ABC 모델',
        onBack: () {
          if (_currentStep == 0 && _currentCSubStep == 0) {
            Navigator.pop(context);
          } else {
            _previousStep();
          }
        },
        onHomePressed: () {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 34,
                      vertical: 24,
                    ),
                    child: _buildStepContent(),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: NavigationButtons(
                    onBack: _previousStep,
                    onNext: _isNextEnabled ? _nextStep : null,
                    rightLabel:
                        widget.isExampleMode && _currentCSubStep == 2
                            ? '확인'
                            : '다음',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return StepAView(
          situations: _aSituations,
          selectedAGrid: _selectedAGrid,
          isExampleMode: widget.isExampleMode,
          onChipTap: (index, selected) {
            setState(() {
              _selectedAGrid
                ..clear()
                ..add(index);
            });
          },
          onAddSituation:
              widget.isExampleMode
                  ? null
                  : (text) => _showAddPopup(
                    title: '상황 추가',
                    highlightText: 'A - 사건 (Activating Event)',
                    onConfirm: (t) => _saveCustomTag(
                      type: 'A',
                      text: t,
                      onSuccess: () {
                        if (!_aSituations.contains(t)) _aSituations.add(t);
                      },
                    ),
                  ),
          onDeleteSituation:
              widget.isExampleMode
                  ? null
                  : (index) {
                    setState(() {
                      _aSituations.removeAt(index);
                      _selectedAGrid.remove(index);
                    });
                  },
        );

      case 1:
        return StepBView(
          beliefs: _bBeliefs,
          selectedBGrid: _selectedBGrid,
          isExampleMode: widget.isExampleMode,
          onChipTap:
              (i, s) => setState(() {
                if (s)
                  _selectedBGrid.add(i);
                else
                  _selectedBGrid.remove(i);
              }),
          onAddBelief:
              widget.isExampleMode
                  ? null
                  : (text) => _showAddPopup(
                    title: '생각 추가',
                    highlightText: 'B - 생각 (Belief)',
                    onConfirm: (t) => _saveCustomTag(
                      type: 'B',
                      text: t,
                      onSuccess: () {
                        if (!_bBeliefs.contains(t)) _bBeliefs.add(t);
                      },
                    ),
                  ),
          onDeleteBelief:
              widget.isExampleMode
                  ? null
                  : (index) {
                    setState(() {
                      _bBeliefs.removeAt(index);
                      _selectedBGrid.remove(index);
                    });
                  },
        );

      case 2:
        return StepCView(
          subStep: _currentCSubStep,
          physicalList: _cPhysical,
          emotionList: _cEmotion,
          behaviorList: _cBehavior,
          selectedPhysical: _selectedPhysical,
          selectedEmotion: _selectedEmotion,
          selectedBehavior: _selectedBehavior,
          isExampleMode: widget.isExampleMode,
          onAddPhysical:
              widget.isExampleMode
                  ? null
                  : (text) => _showAddPopup(
                    title: '신체 반응 추가',
                    highlightText: 'C1 - 신체 (Physical)',
                    onConfirm: (t) => _saveCustomTag(
                      type: 'CP',
                      text: t,
                      onSuccess: () {
                        if (!_cPhysical.contains(t)) _cPhysical.add(t);
                      },
                    ),
                  ),
          onAddEmotion:
              widget.isExampleMode
                  ? null
                  : (text) => _showAddPopup(
                    title: '감정 반응 추가',
                    highlightText: 'C2 - 감정 (Emotion)',
                    onConfirm: (t) => _saveCustomTag(
                      type: 'CE',
                      text: t,
                      onSuccess: () {
                        if (!_cEmotion.contains(t)) _cEmotion.add(t);
                      },
                    ),
                  ),
          onAddBehavior:
              widget.isExampleMode
                  ? null
                  : (text) => _showAddPopup(
                    title: '행동 반응 추가',
                    highlightText: 'C3 - 행동 (Behavior)',
                    onConfirm: (t) => _saveCustomTag(
                      type: 'CB',
                      text: t,
                      onSuccess: () {
                        if (!_cBehavior.contains(t)) _cBehavior.add(t);
                      },
                    ),
                  ),

          onSelectionChanged: () => setState(() {}),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
