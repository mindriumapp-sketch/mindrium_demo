import 'package:flutter/material.dart';
import '../../common/constants.dart';

class StepAView extends StatefulWidget {
  final Set<int> selectedAGrid;
  final void Function(int index, bool selected)? onChipTap;

  const StepAView({super.key, required this.selectedAGrid, this.onChipTap});

  @override
  State<StepAView> createState() => _StepAViewState();
}

class _StepAViewState extends State<StepAView> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _situations = ['회의', '수업', '모임']; // 기본 칩 목록

  void _addSituation(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _situations.add(text.trim());
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '불안감을 느꼈을 때 어떤 상황이었나요?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        /// ✅ 칩 목록
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(_situations.length, (i) {
              final isSelected = widget.selectedAGrid.contains(i);
              return FilterChip(
                label: Text(_situations[i]),
                selected: isSelected,
                onSelected: (selected) => widget.onChipTap?.call(i, selected),
                selectedColor: AppColors.indigo50,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? AppColors.indigo : Colors.grey.shade800,
                ),
              );
            }),

            /// ➕ 칩 추가 버튼
            ActionChip(
              avatar: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text('추가'),
              backgroundColor: AppColors.indigo,
              labelStyle: const TextStyle(color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: const Text('새 상황 추가'),
                        content: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: '예: 발표, 식사 자리 등',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              _addSituation(_controller.text);
                              Navigator.pop(context);
                            },
                            child: const Text('추가'),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
