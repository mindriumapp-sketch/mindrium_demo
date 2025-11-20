import 'package:flutter/material.dart';
// import 'package:gad_app_team/widgets/detail_popup.dart';
// import 'package:gad_app_team/widgets/thought_card.dart'; // ThoughtBubble
// import 'package:gad_app_team/widgets/jellyfish_notice.dart'; // 안 쓰면 지워도 됨

/// ABC 3단계 탭 + 하얀 카드 본문을 한 번에 보여주는 위젯
/// - activeIndex: 0(A), 1(B), 2(C)
/// - smallText: 위쪽 작은 텍스트
/// - bigText: 중앙 큰 텍스트
/// - selectedChips: 아래 칩에서 사용자가 선택한 라벨들 (카드 안에 pill로 2개까지 보여줌)
class AbcStepCard extends StatelessWidget {
  final int activeIndex;
  final String smallText;
  final String bigText;
  final List<String> selectedChips;
  final bool? isStepA;

  const AbcStepCard({
    super.key,
    required this.activeIndex,
    required this.smallText,
    required this.bigText,
    this.selectedChips = const [],
    this.isStepA = false,
  });

  @override
  Widget build(BuildContext context) {
    const previewCount = 2;
    final bool needMore = selectedChips.length > previewCount;
    // final List<String> preview =
    needMore ? selectedChips.sublist(0, previewCount) : selectedChips;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AbcStepTabs(activeIndex: activeIndex),

        // 본문 카드
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  smallText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF263C69),
                    height: 1.4,
                    fontFamily: 'Noto Sans KR',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  bigText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF141F35),
                    height: 1.3,
                    wordSpacing: 1.3,
                    fontFamily: 'Noto Sans KR',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        ),
      ],
    );
  }
}

/// 내부에서만 쓰는 탭 바
class _AbcStepTabs extends StatelessWidget {
  final int activeIndex;
  const _AbcStepTabs({required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55, // 전체 높이는 고정
      child: Row(
        children: [
          _AbcTab(label: 'A 상황', isActive: activeIndex == 0),
          _AbcTab(label: 'B 생각', isActive: activeIndex == 1),
          _AbcTab(label: 'C 결과', isActive: activeIndex == 2),
        ],
      ),
    );
  }
}

class _AbcTab extends StatelessWidget {
  final String label;
  final bool isActive;
  const _AbcTab({required this.label, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        // 아래쪽으로 붙여서 높이 차이가 나도 하단선이 일치하도록
        alignment: Alignment.bottomCenter,
        child: Container(
          height: isActive ? 52 : 35,
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF47A6FF) // 활성 탭
                : const Color(0xFFAADCFD), // 비활성 탭
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: isActive ? 20 : 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Noto Sans KR',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
