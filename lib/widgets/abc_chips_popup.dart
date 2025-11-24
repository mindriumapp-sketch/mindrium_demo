import 'package:flutter/material.dart';

/// AbcChipsDesign 스타일 기반의 팝업 칩 리스트
/// 클릭 시 색상 즉시 변하고 부드러운 애니메이션 포함
class AbcChipsPopup extends StatefulWidget {
  final List<String> chips;
  final Set<int> selectedIndexes;
  final void Function(int index, bool selected)? onChipToggle;

  const AbcChipsPopup({
    super.key,
    required this.chips,
    required this.selectedIndexes,
    this.onChipToggle,
  });

  @override
  State<AbcChipsPopup> createState() => _AbcChipsPopupState();
}

class _AbcChipsPopupState extends State<AbcChipsPopup> {
  late Set<int> _localSelected;

  @override
  void initState() {
    super.initState();
    _localSelected = Set<int>.from(widget.selectedIndexes);
  }

  void _handleTap(int index) {
    setState(() {
      if (_localSelected.contains(index)) {
        _localSelected.remove(index);
      } else {
        _localSelected.add(index);
      }
    });

    // 부모에도 동기화
    final nowSelected = _localSelected.contains(index);
    widget.onChipToggle?.call(index, nowSelected);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 상단 인디케이터
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFB0C4DE),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),

              // 칩 리스트
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: List.generate(widget.chips.length, (index) {
                      final label = widget.chips[index];
                      final isSelected = _localSelected.contains(index);
                      return _AnimatedSelectableChip(
                        label: label,
                        selected: isSelected,
                        onTap: () => _handleTap(index),
                      );
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF47A6FF),
                  textStyle: const TextStyle(
                    fontFamily: 'Noto Sans KR',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('닫기'),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 클릭 시 부드럽게 색상 변경 + 눌림 효과
class _AnimatedSelectableChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AnimatedSelectableChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_AnimatedSelectableChip> createState() =>
      _AnimatedSelectableChipState();
}

class _AnimatedSelectableChipState extends State<_AnimatedSelectableChip>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) => setState(() => _scale = 0.95);
  void _onTapUp(TapUpDetails details) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: (d) {
        _onTapUp(d);
        widget.onTap();
      },
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF47A6FF) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border:
                selected
                    ? null
                    : Border.all(color: const Color(0xFF47A6FF), width: 1.1),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: const Color(0xFF47A6FF).withValues(alpha: .35),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: .05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Noto Sans KR',
                fontSize: 15.5,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF344B60),
              ),
              child: Text(widget.label),
            ),
          ),
        ),
      ),
    );
  }
}
