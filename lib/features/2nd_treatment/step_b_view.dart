import 'package:flutter/material.dart';
import '../../common/constants.dart';

/// 💭 B단계 (생각 입력 화면)
class StepBView extends StatefulWidget {
  final Set<int> selectedBGrid;

  const StepBView({super.key, required this.selectedBGrid});

  @override
  State<StepBView> createState() => _StepBViewState();
}

class _StepBViewState extends State<StepBView> {
  final List<Map<String, dynamic>> _bGridChips = [
    {'icon': Icons.psychology, 'label': '실수할까 걱정'},
    {'icon': Icons.warning, 'label': '비난받을까 두려움'},
    {'icon': Icons.question_mark, 'label': '다른 사람이 날 싫어할지도'},
    {'icon': Icons.add, 'label': '추가', 'isAdd': true},
  ];

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
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
                  const Text(
                    '그 상황에서 어떤 생각이 들었나요?',
                    style: TextStyle(
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
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: '예: 비난받을까 걱정',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          _bGridChips.insert(_bGridChips.length - 1, {
                            'icon': Icons.circle,
                            'label': text,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '그 상황에서 어떤 생각이 들었나요?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_bGridChips.length, (i) {
            final item = _bGridChips[i];
            final isSelected = widget.selectedBGrid.contains(i);
            final bool isAdd = item['isAdd'] == true;

            if (isAdd) {
              return ActionChip(
                avatar: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.indigo,
                ),
                label: const Text(
                  '추가',
                  style: TextStyle(color: AppColors.indigo, fontSize: 13.5),
                ),
                backgroundColor: AppColors.indigo50,
                side: const BorderSide(color: AppColors.indigo, width: 1.2),
                onPressed: _showAddDialog,
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
                    widget.selectedBGrid.remove(i);
                  } else {
                    widget.selectedBGrid
                      ..clear()
                      ..add(i);
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
        ),
      ],
    );
  }
}
