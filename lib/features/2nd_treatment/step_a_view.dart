import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/abc_chips_design.dart';
import 'package:gad_app_team/widgets/abc_step_card.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

class StepAView extends StatefulWidget {
  final List<String> situations;
  final Set<int> selectedAGrid;
  final void Function(int index, bool selected)? onChipTap;
  final void Function(String text)? onAddSituation;
  final void Function(int index)? onDeleteSituation;
  final bool isExampleMode;

  const StepAView({
    super.key,
    required this.situations,
    required this.selectedAGrid,
    this.onChipTap,
    this.onAddSituation,
    this.onDeleteSituation,
    this.isExampleMode = false,
  });

  @override
  State<StepAView> createState() => _StepAViewState();
}

class _StepAViewState extends State<StepAView> {
  String _bannerMessage = "아래에 '자전거를 타려고 함' 칩을 눌러 \n선택해보세요!";

  @override
  Widget build(BuildContext context) {
    final int defaultCount = widget.isExampleMode ? 4 : 3;

    final selectedLabels =
        widget.selectedAGrid
            .where((i) => i >= 0 && i < widget.situations.length)
            .map((i) => widget.situations[i])
            .toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AbcStepCard(
            activeIndex: 0,
            smallText: '반응을 유발하는 사건이나 상황을 확인해요',
            bigText: '불안감을 느꼈을 때,\n어떤 상황이었나요?',
            selectedChips: selectedLabels,
            isStepA: true,
          ),
          const SizedBox(height: 40),

          // ✅ 예시모드 전용 배너
          if (widget.isExampleMode) ...[
            JellyfishBanner(message: _bannerMessage),
            const SizedBox(height: 30),
          ],

          // ✅ 칩 영역
          AbcChipsDesign(
            chips: widget.situations,
            defaultCount: defaultCount,
            selectedIndexes: widget.selectedAGrid,
            singleSelect: true,
            onChipToggle: (index, selected) {
              widget.onChipTap?.call(index, selected);

              if (widget.isExampleMode) {
                final label = widget.situations[index];
                setState(() {
                  _bannerMessage =
                      (selected && label == '자전거를 타려고 함')
                          ? "선택한 뒤 아래의 '다음' 버튼을 눌러주세요!"
                          : "아래에 '자전거를 타려고 함' 칩을 눌러 \n선택해보세요!";
                });
              }
            },
            // ✅ 삭제/추가 콜백은 상위(AbcInputScreen)에서 처리
            onChipDelete:
                widget.isExampleMode
                    ? null
                    : (index) => widget.onDeleteSituation?.call(index),
            onChipAdd:
                widget.isExampleMode
                    ? null
                    : (label) => widget.onAddSituation?.call(label),
            isExampleMode: widget.isExampleMode,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
