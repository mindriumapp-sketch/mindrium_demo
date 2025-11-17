import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/abc_chips_design.dart';
import 'package:gad_app_team/widgets/abc_step_card.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

class StepBView extends StatefulWidget {
  final List<String> beliefs;
  final Set<int> selectedBGrid;
  final void Function(int index, bool selected)? onChipTap;
  final void Function(String text)? onAddBelief;
  final void Function(int index)? onDeleteBelief;
  final bool isExampleMode;

  const StepBView({
    super.key,
    required this.beliefs,
    required this.selectedBGrid,
    this.onChipTap,
    this.onAddBelief,
    this.onDeleteBelief,
    this.isExampleMode = false,
  });

  @override
  State<StepBView> createState() => _StepBViewState();
}

class _StepBViewState extends State<StepBView> {
  String _bannerMessage = "아래에 '넘어질까봐 두려움' 칩을 눌러 \n선택해보세요!";

  @override
  Widget build(BuildContext context) {
    final int defaultCount = widget.isExampleMode ? 5 : 4;

    final selectedLabels =
        widget.selectedBGrid
            .where((i) => i >= 0 && i < widget.beliefs.length)
            .map((i) => widget.beliefs[i])
            .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AbcStepCard(
            activeIndex: 1,
            smallText: '그 상황에서 어떤 생각을\n했는지 적어봐요',
            bigText: '그때 어떤 생각이\n들었나요?',
            selectedChips: selectedLabels,
            isStepA: false,
          ),
          const SizedBox(height: 40),

          // ✅ 예시 모드 전용 배너
          if (widget.isExampleMode) ...[
            JellyfishBanner(message: _bannerMessage),
            const SizedBox(height: 30),
          ],

          // ✅ 칩 디자인
          AbcChipsDesign(
            chips: widget.beliefs,
            defaultCount: defaultCount,
            selectedIndexes: widget.selectedBGrid,
            onChipToggle: (index, selected) {
              widget.onChipTap?.call(index, selected);

              if (widget.isExampleMode) {
                final label = widget.beliefs[index];
                setState(() {
                  _bannerMessage =
                      (selected && label == '넘어질까봐 두려움')
                          ? "선택한 뒤 아래의 '다음' 버튼을 눌러주세요!"
                          : "아래에 '넘어질까봐 두려움' 칩을 눌러 \n선택해보세요!";
                });
              }
            },
            // ✅ 삭제/추가 콜백은 상위 AbcInputScreen에서 처리
            onChipDelete:
                widget.isExampleMode
                    ? null
                    : (index) => widget.onDeleteBelief?.call(index),
            onChipAdd:
                widget.isExampleMode
                    ? null
                    : (label) => widget.onAddBelief?.call(label),
            isExampleMode: widget.isExampleMode,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
