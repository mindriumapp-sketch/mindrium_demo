import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// 🌊 ABC 칩 디자인 공용 위젯 (Mindrium 공통 스타일)
/// - 예시모드(true): 추가 칩 숨김
/// - 일반모드(false): +추가 칩 표시 (입력칸 없음, 부모에서 팝업 호출)
class AbcChipsDesign extends StatefulWidget {
  final List<String> chips;
  final int defaultCount;
  final Set<int> selectedIndexes;
  final void Function(int index, bool selected)? onChipToggle;
  final void Function(int index)? onChipDelete;
  final bool singleSelect;

  /// ✅ 상위에서 팝업 호출하도록 연결되는 콜백
  final void Function(String text)? onChipAdd;

  /// 예시 모드 여부
  final bool isExampleMode;

  const AbcChipsDesign({
    super.key,
    required this.chips,
    required this.defaultCount,
    this.selectedIndexes = const {},
    this.onChipToggle,
    this.onChipDelete,
    this.singleSelect = false,
    this.onChipAdd,
    this.isExampleMode = false,
  });

  @override
  State<AbcChipsDesign> createState() => _AbcChipsDesignState();
}

class _AbcChipsDesignState extends State<AbcChipsDesign> {
  late Set<int> _selectedIndexes;

  @override
  void initState() {
    super.initState();
    _selectedIndexes = Set<int>.from(widget.selectedIndexes);
  }

  @override
  void didUpdateWidget(covariant AbcChipsDesign oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(widget.selectedIndexes, _selectedIndexes)) {
      _selectedIndexes = Set<int>.from(widget.selectedIndexes);
    }
  }

  /// ✅ “+추가” 버튼 → 입력칸 대신 부모 콜백 호출
  void _startAdd() {
    if (widget.isExampleMode) return;
    widget.onChipAdd?.call('');
  }

  void _toggleChip(int i, bool selected) {
    if (widget.singleSelect) {
      if (selected) {
        final prev = List<int>.from(_selectedIndexes);
        setState(() {
          _selectedIndexes
            ..clear()
            ..add(i);
        });
        for (final p in prev) {
          if (p != i) widget.onChipToggle?.call(p, false);
        }
        widget.onChipToggle?.call(i, true);
      } else {
        setState(() => _selectedIndexes.remove(i));
        widget.onChipToggle?.call(i, false);
      }
    } else {
      setState(() {
        if (selected) {
          _selectedIndexes.add(i);
        } else {
          _selectedIndexes.remove(i);
        }
      });
      widget.onChipToggle?.call(i, selected);
    }

    // ✅ 여기 추가 (중요!)
    // 칩 선택 후 상위 위젯(예: StepCView → AbcInputScreen)으로 즉시 반영
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {}); // 자체 반영
    });
  }

  void _deleteChip(int i) => widget.onChipDelete?.call(i);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      radius: const Radius.circular(12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              ...List.generate(widget.chips.length, (i) {
                final label = widget.chips[i];
                final isSelected = _selectedIndexes.contains(i);
                final isCustom = !widget.isExampleMode;

                Widget chipWidget =
                    isSelected
                        ? _SelectedChip(
                          label: label,
                          showClose: isCustom,
                          onTap: () => _toggleChip(i, false),
                          onRemove: isCustom ? () => _deleteChip(i) : null,
                        )
                        : _UnselectedChip(
                          label: label,
                          showClose: isCustom,
                          onTap: () => _toggleChip(i, true),
                          onRemove: isCustom ? () => _deleteChip(i) : null,
                        );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: chipWidget,
                  ),
                );
              }),

              // ✅ 입력칩 제거하고, 단순 +추가 버튼만
              if (!widget.isExampleMode) _AddChipButton(onTap: _startAdd),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ 선택된 칩
class _SelectedChip extends StatelessWidget {
  final String label;
  final bool showClose;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _SelectedChip({
    required this.label,
    required this.onTap,
    this.showClose = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 38,
        padding: EdgeInsets.only(left: 16, right: showClose ? 6 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF47A6FF),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF47A6FF).withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Noto Sans KR',
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showClose && onRemove != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ 선택되지 않은 칩
class _UnselectedChip extends StatelessWidget {
  final String label;
  final bool showClose;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _UnselectedChip({
    required this.label,
    required this.onTap,
    this.showClose = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: EdgeInsets.only(left: 16, right: showClose ? 6 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF344B60),
                fontSize: 16,
                fontFamily: 'Noto Sans KR',
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showClose && onRemove != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF47A6FF).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Color(0xFF47A6FF),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ✅ “+추가” 칩
class _AddChipButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _AddChipButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF47A6FF), width: 1.2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 18, color: Color(0xFF47A6FF)),
            SizedBox(width: 4),
            Text(
              '추가',
              style: TextStyle(
                color: Color(0xFF47A6FF),
                fontSize: 14.5,
                fontFamily: 'Noto Sans KR',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
