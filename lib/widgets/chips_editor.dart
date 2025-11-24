import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────
/// ChipsEditor
/// - 탭하면 편집 칩 추가
/// - 편집 중: 텍스트 길이만큼 가로로 늘어나고, 상한 도달 시 자동 줄바꿈으로 세로 증가
/// - 확정 칩: 줄수 제한 없이 내용만큼 높이 확장
/// - 칩 우상단 X 배지 탭 시 삭제
/// - onChanged로 확정된 칩들의 문자열 리스트 전달
/// ─────────────────────────────────────────────────────────────────
class ChipsEditor extends StatefulWidget {
  const ChipsEditor({
    super.key,
    this.initial = const [],
    this.onChanged,
    this.minHeight = 150,
    this.maxWidthFactor = 0.78, // 화면 폭 대비 최대 칩 너비 비율
    this.emptyIcon = const Icon(Icons.edit_note_rounded, size: 64, color: Colors.black45),
    this.emptyText = const Text(
      '여기에 작성해주세요!',
      style: TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w600),
    ),
  });

  /// 초기 칩 텍스트
  final List<String> initial;

  /// 확정(편집 종료)된 칩 리스트가 바뀔 때마다 호출
  final ValueChanged<List<String>>? onChanged;

  /// 입력 영역 기본 높이 (칩이 많아지면 자동 증가)
  final double minHeight;

  /// 한 칩이 차지할 수 있는 최대 너비(화면 폭 비율)
  final double maxWidthFactor;

  /// 아무 것도 없을 때 아이콘/문구
  final Widget emptyIcon;
  final Widget emptyText;

  @override
  State<ChipsEditor> createState() => ChipsEditorState();
}

class ChipsEditorState extends State<ChipsEditor> {
  final List<_ChipItem> _items = [];

  /// 현재 확정된 칩 문자열들
  List<String> get values =>
      _items.where((e) => !e.isEditing && e.text.trim().isNotEmpty).map((e) => e.text.trim()).toList();

  double _maxChipWidth(BuildContext context) =>
      (MediaQuery.of(context).size.width * widget.maxWidthFactor).clamp(180.0, 340.0);

  final TextStyle _chipTextStyle = const TextStyle(
    color: Colors.black54,
    fontWeight: FontWeight.w700,
    height: 1.25,
    fontSize: 14,
  );

  @override
  void initState() {
    super.initState();
    // 초기 칩 생성 (확정 상태)
    for (final t in widget.initial) {
      _items.add(_ChipItem(text: t, editing: false));
    }
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  void _notify() => widget.onChanged?.call(values);

  /// 외부에서 호출해: 현재 편집 중 칩이 있으면 확정 + 포커스 해제
  void unfocusAndCommit() {
    final editingIdx = _items.indexWhere((e) => e.isEditing);
    if (editingIdx != -1) {
      final it = _items[editingIdx];
      _commit(it);
    }
    if (mounted) {
      FocusScope.of(context).unfocus();
    }
  }

  /// 내부에서 사용: 포커스 주거나 새 편집칩 추가
  void focusOrAdd() {
    final editingIdx = _items.indexWhere((e) => e.isEditing);
    if (editingIdx != -1) {
      FocusScope.of(context).requestFocus(_items[editingIdx].focusNode);
      return;
    }
    final item = _ChipItem();
    setState(() => _items.add(item));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(item.focusNode);
    });
  }

  void _commit(_ChipItem item) {
    final value = item.controller.text.trim();
    setState(() {
      if (value.isEmpty) {
        _items.remove(item);
        item.dispose();
      } else {
        item.text = value;
        item.isEditing = false;
      }
    });
    _notify();
  }

  void _remove(_ChipItem item) {
    setState(() {
      _items.remove(item);
      item.dispose();
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: focusOrAdd,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _items.isEmpty
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              widget.emptyIcon,
              const SizedBox(height: 8),
              widget.emptyText,
              const SizedBox(height: 8),
            ],
          )
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _items.map((e) => _buildChip(context, e)).toList(),
          ),
        ),
      ),
    );
  }

  // ───────────────────── 칩 렌더링 ─────────────────────
  Widget _buildChip(BuildContext context, _ChipItem item) {
    final maxW = _maxChipWidth(context);

    if (item.isEditing) {
      // 편집 칩
      return Focus(
        focusNode: item.focusNode,
        onFocusChange: (has) {
          if (!has) _commit(item); // 포커스 잃으면 확정
        },
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: 84, maxWidth: maxW),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFD1D9F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: item.controller,
                autofocus: true,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: null, // 제한 없음 → 높이 자연 증가
                style: _chipTextStyle,
                textAlign: TextAlign.left,
                textAlignVertical: TextAlignVertical.center,
                onChanged: (v) {
                  // 엔터는 확정으로 처리
                  if (v.contains('\n')) {
                    item.controller.text = v.replaceAll('\n', ' ');
                    item.controller.selection =
                        TextSelection.fromPosition(TextPosition(offset: item.controller.text.length));
                    _commit(item);
                    return;
                  }
                  setState(() {}); // IntrinsicWidth 재계산
                },
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
        ),
      );
    }

    // 확정 칩
    return IntrinsicWidth(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: 50, maxWidth: maxW),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF42A5F5).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                item.text,
                softWrap: true,
                style: _chipTextStyle.copyWith(color: Colors.black54),
              ),
            ),
          ),
          Positioned(
            right: -6,
            top: -4,
            child: _DeleteBadge(onTap: () => _remove(item)),
          ),
        ],
      ),
    );
  }
}

/// 내부용 칩 데이터
class _ChipItem {
  _ChipItem({
    this.text = '',
    bool? editing,
    FocusNode? focusNode,
    TextEditingController? controller,
  })  : isEditing = editing ?? true,
        focusNode = focusNode ?? FocusNode(),
        controller = controller ?? TextEditingController(text: text);

  String text;
  bool isEditing;
  final FocusNode focusNode;
  final TextEditingController controller;

  void dispose() {
    focusNode.dispose();
    controller.dispose();
  }
}

/// 삭제 버튼(작은 동그라미 X)
class _DeleteBadge extends StatelessWidget {
  const _DeleteBadge({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 22,
          height: 22,
          child: Center(
            child: Icon(Icons.close, size: 14, color: Color(0xFF1E88E5)),
          ),
        ),
      ),
    );
  }
}
