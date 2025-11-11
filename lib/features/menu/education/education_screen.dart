import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/top_btm_card.dart';
import 'package:gad_app_team/utils/edu_progress.dart';
import 'package:gad_app_team/widgets/edu_progress_section.dart';

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext c, Widget child, ScrollableDetails d) => child;
  @override
  Widget buildScrollbar(BuildContext c, Widget child, ScrollableDetails d) => child;
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad,
  };
}

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});
  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  static const List<BookItem> _items = [
    BookItem('불안이란 무엇인가?', '/education1', 'assets/image/edu_book1.jpg'),
    BookItem('불안이 생기는 원리', '/education2', 'assets/image/edu_book2.jpg'),
    BookItem('동반되기 쉬운 다른 문제들', '/education3', 'assets/image/edu_book3.jpg'),
    BookItem('불안의 치료 방법', '/education4', 'assets/image/edu_book4.jpg'),
    BookItem('Mindrium의 치료 방법', '/education5', 'assets/image/edu_book5.jpg'),
    BookItem('자기 이해를 높이는 방법', '/education6', 'assets/image/edu_book6.jpg'),
  ];

  /// 진행 저장/조회 키 매핑
  static const Map<String, String> _routeToKey = {
    '/education1': 'week1_part1',
    '/education2': 'week1_part2',
    '/education3': 'week1_part3',
    '/education4': 'week1_part4',
    '/education5': 'week1_part5',
    '/education6': 'week1_part6',
  };

  /// 총 페이지 집계용 prefix
  static const Map<String, String> _routeToPrefix = {
    '/education1': 'assets/education_data/week1_part1_',
    '/education2': 'assets/education_data/week1_part2_',
    '/education3': 'assets/education_data/week1_part3_',
    '/education4': 'assets/education_data/week1_part4_',
    '/education5': 'assets/education_data/week1_part5_',
    '/education6': 'assets/education_data/week1_part6_',
  };

  Future<void> _openBook(BuildContext context, BookItem it) async {
    await EduProgress.setLastRoute(it.route);             // 마지막 선택 저장
    final result = await Navigator.pushNamed(context, it.route);
    if (result is int) {                                  // (선택) 상세에서 read 넘겨준 경우 저장
      final key = _routeToKey[it.route];
      if (key != null) await EduProgress.save(key, result);
    }
    // 돌아오면 진행 섹션은 RouteObserver를 통해 자동 새로고침됨(옵션).
  }

  @override
  Widget build(BuildContext context) {
    const coverAspect = 162 / 228; // ≈0.71
    const cardH = 200.0;
    const cardGap = 10.0;
    final cardW = cardH * coverAspect;

    final row1 = _items.sublist(0, 3);
    final row2 = _items.sublist(3, 6);

    return ScrollConfiguration(
      behavior: const _NoScrollbarBehavior(),
      child: ApplyDoubleCard(
        appBarTitle: '교육',
        pagePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        panelPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        panelsGap: 24,
        panelRadius: 20,
        maxWidth: 980,
        topcardColor: Colors.white.withOpacity(0.96),
        btmcardColor: Colors.white.withOpacity(0.96),
        middleNoticeText: null,
        onBack: null,
        onNext: null,

        // 상단 패널: 가로 2줄 스크롤
        topChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PanelHeader(
              subtitle: '주제',
              showDivider: false,
              margin: EdgeInsets.only(bottom: 12),
            ),
            SizedBox(
              height: cardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: row1.length,
                separatorBuilder: (_, __) => const SizedBox(width: cardGap),
                itemBuilder: (context, i) {
                  final it = row1[i];
                  return _BookCard(
                    width: cardW,
                    height: cardH,
                    item: it,
                    onTap: () => _openBook(context, it),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: cardH,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: row2.length,
                separatorBuilder: (_, __) => const SizedBox(width: cardGap),
                itemBuilder: (context, i) {
                  final it = row2[i];
                  return _BookCard(
                    width: cardW,
                    height: cardH,
                    item: it,
                    onTap: () => _openBook(context, it),
                  );
                },
              ),
            ),
          ],
        ),

        // 하단 패널: 분리한 섹션 사용
        bottomChild: EducationProgressSection(
          items: _items,
          routeToKey: _routeToKey,
          routeToPrefix: _routeToPrefix,
        ),
      ),
    );
  }
}

/// 책 표지 카드(이미지 + 둥근모서리 + 그림자)
class _BookCard extends StatelessWidget {
  final double width;
  final double height;
  final BookItem item;
  final VoidCallback onTap;

  const _BookCard({
    required this.width,
    required this.height,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            item.imgPath,
            fit: BoxFit.contain, // 표지 전체 보이게
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}