import 'package:flutter/material.dart';
import '../../common/constants.dart';

/// 🌊 C단계 (결과 입력 화면)
/// subStep = 0 → 신체증상 / 1 → 감정 / 2 → 행동
class StepCView extends StatefulWidget {
  final Set<int> selectedPhysical;
  final Set<int> selectedEmotion;
  final Set<int> selectedBehavior;
  final int subStep;

  const StepCView({
    super.key,
    required this.selectedPhysical,
    required this.selectedEmotion,
    required this.selectedBehavior,
    required this.subStep,
  });

  @override
  State<StepCView> createState() => _StepCViewState();
}

class _StepCViewState extends State<StepCView> {
  // 각 항목별 GridItem 리스트
  final List<Map<String, dynamic>> _physicalChips = [
    {'icon': Icons.bed, 'label': '불면'},
    {'icon': Icons.favorite, 'label': '두근거림'},
    {'icon': Icons.sick, 'label': '메스꺼움'},
    {'icon': Icons.spa, 'label': '식은땀'},
    {'icon': Icons.add, 'label': '추가', 'isAdd': true},
  ];
  final List<Map<String, dynamic>> _emotionChips = [
    {'icon': Icons.sentiment_dissatisfied, 'label': '불안'},
    {'icon': Icons.flash_on, 'label': '분노'},
    {'icon': Icons.sentiment_dissatisfied, 'label': '슬픔'},
    {'icon': Icons.visibility_off, 'label': '두려움'},
    {'icon': Icons.add, 'label': '추가', 'isAdd': true},
  ];
  final List<Map<String, dynamic>> _behaviorChips = [
    {'icon': Icons.event_busy, 'label': '결석'},
    {'icon': Icons.phone_disabled, 'label': '전화 안 받기'},
    {'icon': Icons.event_note, 'label': '약속 피하기'},
    {'icon': Icons.visibility_off, 'label': '시선 피하기'},
    {'icon': Icons.add, 'label': '추가', 'isAdd': true},
  ];

  final TextEditingController _controller = TextEditingController();

  // 공통 다이얼로그 (신체 / 감정 / 행동 추가)
  void _showAddDialog(String title, List<Map<String, dynamic>> targetList) {
    _controller.clear();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: AppColors.indigo50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.indigo,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '예: 가슴 두근거림',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final val = _controller.text.trim();
                      if (val.isNotEmpty) {
                        setState(() {
                          targetList.insert(targetList.length - 1, {
                            'icon': Icons.circle,
                            'label': val,
                          });
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // 공통 Chip 렌더러
  Widget _buildChipGroup({
    required String type,
    required List<Map<String, dynamic>> list,
    required Set<int> selectedSet,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(list.length, (i) {
        final item = list[i];
        final bool isAdd = item['isAdd'] == true;
        final bool isSelected = selectedSet.contains(i);

        if (isAdd) {
          return ActionChip(
            avatar: const Icon(Icons.add, size: 18, color: AppColors.indigo),
            label: const Text(
              '추가',
              style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
            ),
            backgroundColor: AppColors.indigo50,
            side: const BorderSide(color: AppColors.indigo, width: 1.2),
            onPressed: () {
              _showAddDialog('새로운 $type을(를) 입력하세요', list);
            },
          );
        }

        return FilterChip(
          avatar: Icon(
            item['icon'],
            size: 18,
            color: isSelected ? AppColors.indigo : Colors.grey.shade800,
          ),
          label: Text(
            item['label'],
            style: TextStyle(
              color: isSelected ? AppColors.indigo : Colors.grey.shade800,
              fontSize: 13.5,
            ),
          ),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              if (isSelected) {
                selectedSet.remove(i);
              } else {
                selectedSet.add(i);
              }
            });
          },
          showCheckmark: false,
          selectedColor: AppColors.indigo50,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: isSelected ? AppColors.indigo : Colors.grey.shade800,
            width: 1.2,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.subStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'C-1. 어떤 신체 증상이 나타났나요?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildChipGroup(
              type: '신체 증상',
              list: _physicalChips,
              selectedSet: widget.selectedPhysical,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'C-2. 어떤 감정이 들었나요?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildChipGroup(
              type: '감정',
              list: _emotionChips,
              selectedSet: widget.selectedEmotion,
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'C-3. 어떤 행동을 했나요?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildChipGroup(
              type: '행동',
              list: _behaviorChips,
              selectedSet: widget.selectedBehavior,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
