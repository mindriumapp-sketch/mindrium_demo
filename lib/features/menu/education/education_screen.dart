// 📄 education_screen.dart (최종 확정본)
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/utils/edu_progress.dart';
import 'package:gad_app_team/widgets/edu_progress_section.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';

class _NoScrollbarBehavior extends ScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext c,
    Widget child,
    ScrollableDetails d,
  ) => child;

  @override
  Widget buildScrollbar(BuildContext c, Widget child, ScrollableDetails d) =>
      child;

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class EducationScreen extends StatefulWidget {
  final bool isRelax;

  const EducationScreen({
    super.key,
    this.isRelax = false
  });

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }
  void _loadUserName() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _userName = userProvider.userName);
  }

  late final List<BookItem> _items = widget.isRelax? [
    BookItem('불안이란 무엇인가?', '/education1', 'assets/image/edu_book1.jpg'),
    BookItem('동반되기 쉬운 다른 문제들', '/education3', 'assets/image/edu_book3.jpg'),
    BookItem('불안의 치료 방법', '/education4', 'assets/image/edu_book4.jpg'),
    BookItem('점진적 이완 훈련 안내', '/education7', 'assets/image/edu_relaxation.png'),
  ] : [
    BookItem('불안이란 무엇인가?', '/education1', 'assets/image/edu_book1.jpg'),
    BookItem('불안이 생기는 원리', '/education2', 'assets/image/edu_book2.jpg'),
    BookItem('동반되기 쉬운 다른 문제들', '/education3', 'assets/image/edu_book3.jpg'),
    BookItem('불안의 치료 방법', '/education4', 'assets/image/edu_book4.jpg'),
    BookItem('Mindrium의 치료 방법', '/education5', 'assets/image/edu_book5.jpg'),
    BookItem('자기 이해를 높이는 방법', '/education6', 'assets/image/edu_book6.jpg'),
  ];

  late final Map<String, String> _routeToKey = widget.isRelax? {
    '/education1': 'week1_part1',
    '/education3': 'week1_part3',
    '/education4': 'week1_part4',
    '/education7': 'week1_relaxation',
  } : {
    '/education1': 'week1_part1',
    '/education2': 'week1_part2',
    '/education3': 'week1_part3',
    '/education4': 'week1_part4',
    '/education5': 'week1_part5',
    '/education6': 'week1_part6',
  };

  late final Map<String, String>  _routeToPrefix = widget.isRelax? {
    '/education1': 'assets/education_data/week1_part1_',
    '/education3': 'assets/education_data/week1_part3_',
    '/education4': 'assets/education_data/week1_part4_',
    '/education7': 'assets/education_data/week1_relaxation_',
  } : {
    '/education1': 'assets/education_data/week1_part1_',
    '/education2': 'assets/education_data/week1_part2_',
    '/education3': 'assets/education_data/week1_part3_',
    '/education4': 'assets/education_data/week1_part4_',
    '/education5': 'assets/education_data/week1_part5_',
    '/education6': 'assets/education_data/week1_part6_',
  };

  Future<void> _openBook(BuildContext context, BookItem it) async {
    await EduProgress.setLastRoute(it.route);
    final result = await Navigator.pushNamed(context, it.route);
    if (result is int) {
      final key = _routeToKey[it.route];
      if (key != null) await EduProgress.save(key, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    const coverAspect = 162 / 228;
    const cardH = 200.0;
    const cardGap = 10.0;
    final cardW = cardH * coverAspect;
    final row1 = widget.isRelax? _items.sublist(0, 2): _items.sublist(0, 3);
    final row2 = widget.isRelax? _items.sublist(2, 4): _items.sublist(3, 6);

    return WillPopScope(
      // ✅ 물리적 뒤로가기 → '/contents'
      onWillPop: () async {
        if (widget.isRelax) {
          // ✅ 이완 모드일 때: /treatment까지 돌아가기
          Navigator.pushNamedAndRemoveUntil(context, '/treatment', (_)=>false);
        } else {
          // ✅ 일반 모드일 때: 기존대로 /contents
          Navigator.pushNamedAndRemoveUntil(context, '/contents', (_)=>false);
        }
        return false; // 뒤로가기 기본 동작 막기
      },
      child: ScrollConfiguration(
        behavior: const _NoScrollbarBehavior(),
        child: Scaffold(
          backgroundColor: Colors.white, // ✅ 온백 유지
          body: Stack(
            children: [
              /// 🌊 Mindrium-style 배경
              Positioned.fill(
                child: Image.asset(
                  'assets/image/eduhome.png',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.35),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    /// ✅ CustomAppBar (뒤로가기 → /contents)
                    CustomAppBar(
                      title: widget.isRelax? '1주차 - 불안에 대한 교육': '불안에 대한 교육',
                      showHome: true,
                      confirmOnHome: true,
                      confirmOnBack: false,
                      onBack:() {
                        if (widget.isRelax) {
                          // ✅ 이완 모드일 때: /treatment 까지 돌아가기
                          Navigator.pushNamedAndRemoveUntil(context, '/treatment', (_)=>false);
                        } else {
                          // ✅ 일반 모드일 때: 기존 동작 유지
                          Navigator.pushNamedAndRemoveUntil(context, '/contents', (_)=>false);
                        }
                      },
                      titleTextStyle: const TextStyle(
                        fontFamily: 'Noto Sans KR',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      toolbarHeight: 56,
                    ),

                    /// ✅ 메인 콘텐츠 스크롤 영역
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 980),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                _buildCardSection(
                                  row1,
                                  row2,
                                  cardH,
                                  cardW,
                                  cardGap,
                                ),
                                const SizedBox(height: 24),
                                _buildProgressSection(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection(
    List<BookItem> row1,
    List<BookItem> row2,
    double cardH,
    double cardW,
    double cardGap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '주제',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _horizontalBookList(row1, cardH, cardW, cardGap),
          const SizedBox(height: 16),
          _horizontalBookList(row2, cardH, cardW, cardGap),
        ],
      ),
    );
  }

  Widget _horizontalBookList(
    List<BookItem> items,
    double cardH,
    double cardW,
    double cardGap,
  ) {
    return SizedBox(
      height: cardH,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(width: cardGap),
        itemBuilder: (context, i) {
          final it = items[i];
          return _BookCard(
            width: cardW,
            height: cardH,
            item: it,
            onTap: () {
              if (widget.isRelax) {
                ///TODO: 스크린타임 해결 후 이거 진행률에 따라 lock/unlock 이든 팝업창이든 가능하게 만들기
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EducationPage(
                          jsonPrefixes: const [
                            'week1_part1_',
                            'week1_part3_',
                            'week1_part4_',
                            'week1_relaxation_',
                          ],
                          isRelax: true,
                        ),
                  ),
                );
              } else {
                _openBook(context, it);
              }
            }
          );
        },
      ),
    );
  }

  Widget _buildProgressSection() {
    final name = _userName ?? '사용자';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: widget.isRelax? Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            '$name님, 1주차에서는 불안에 대해 배워보고, 점진적 이완을 연습해보겠습니다.',
            style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
          ),
        ),
      ): EducationProgressSection(
        items: _items,
        routeToKey: _routeToKey,
        routeToPrefix: _routeToPrefix,
      ),
    );
  }
}

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
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            item.imgPath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
