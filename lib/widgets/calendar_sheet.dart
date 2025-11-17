import 'package:flutter/material.dart';

/// 캘린더 상단 파란 탭 + 고리 4개 + 이어지는 흰 카드 레이아웃
class CalendarSheet extends StatelessWidget {
  final String title;
  final Widget child;

  // 스타일 옵션
  final int ringCount;
  final double ringWidth;
  final double ringHeight;
  final double ringRadius;
  final Color ringColor;
  final double stripHeight;
  final Color stripColor;
  final double whiteRadius;
  final EdgeInsets whitePadding;
  final double overlapOffsetY;

  const CalendarSheet({
    super.key,
    required this.title,
    required this.child,
    this.ringCount = 4,
    this.ringWidth = 12,
    this.ringHeight = 42,
    this.ringRadius = 6,
    this.ringColor = const Color.fromARGB(255, 58, 64, 71),
    this.stripHeight = 68,
    this.stripColor = const Color(0xFF5DADEC), // GAD-7 톤
    this.whiteRadius = 20,
    this.whitePadding = const EdgeInsets.all(24),
    this.overlapOffsetY = -8,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── 파란 탭 + 고리 (좌우 패딩 34)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: SizedBox(
            height: stripHeight,
            child: _BlueStripWithRings(
              ringCount: ringCount,
              ringWidth: ringWidth,
              ringHeight: ringHeight,
              ringRadius: ringRadius,
              ringColor: ringColor,
              stripColor: stripColor,
            ),
          ),
        ),

        // ── 이어지는 흰 카드 (좌우 패딩 34)
        Transform.translate(
          offset: Offset(0, overlapOffsetY),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34),
            child: _WhiteCardContainer(
              title: title,
              whitePadding: whitePadding,
              whiteRadius: whiteRadius,
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

/// 내부 파란 스트립 + 고리
class _BlueStripWithRings extends StatelessWidget {
  final int ringCount;
  final double ringWidth;
  final double ringHeight;
  final double ringRadius;
  final Color ringColor;
  final Color stripColor;

  const _BlueStripWithRings({
    required this.ringCount,
    required this.ringWidth,
    required this.ringHeight,
    required this.ringRadius,
    required this.ringColor,
    required this.stripColor,
  });

  @override
  Widget build(BuildContext context) {
    const innerMaxWidth = 360.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: stripColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: innerMaxWidth,
              child: LayoutBuilder(
                builder: (_, c) {
                  final w = c.maxWidth;
                  final count = ringCount.clamp(1, 8);

                  // 각 고리의 폭 합
                  final totalRing = ringWidth * count;
                  final gaps = (count - 1).toDouble();
                
                  // ① 기본 균등 간격
                  final baseGap = gaps > 0 ? (w - totalRing) / gaps : 0.0;
                
                  // ② 간격 축소 비율 (원하는 값으로 조절: 0.75 = 25% 줄이기)
                  const gapRatio = 0.75;
                  final gap = baseGap * gapRatio;
                
                  // ③ 실제 전체 폭(고리 + 간격)과 시작 위치(중앙 정렬용)
                  final lineWidth = totalRing + gap * gaps;
                  final startX = (w - lineWidth) / 2;

                  return Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(count, (i) {
                      final left = startX + i * (ringWidth + gap);
                    return Positioned(
                        top: -16,
                        left: left,
                        child: Container(
                          width: ringWidth,
                          height: ringHeight,
                          decoration: BoxDecoration(
                            color: ringColor,
                            borderRadius: BorderRadius.circular(ringRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                }
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 흰 카드 컨테이너 (제목 + child)
class _WhiteCardContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final EdgeInsets whitePadding;
  final double whiteRadius;

  const _WhiteCardContainer({
    required this.title,
    required this.child,
    required this.whitePadding,
    required this.whiteRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: whitePadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(0),
          topRight: const Radius.circular(0),
          bottomLeft: Radius.circular(whiteRadius),
          bottomRight: Radius.circular(whiteRadius),
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          // GAD-7 카드 톤과 유사
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
