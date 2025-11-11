// 🪸 Mindrium ContentScreen — AppBar 제거 + 기능/라우팅 그대로 유지
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tap_design.dart'; // ✅ 공통 디자인 위젯 (AppBar 포함, 하지만 여기선 숨김 처리)

class ContentScreen extends StatelessWidget {
  const ContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    /// 📚 메뉴 항목 데이터 (기능 그대로 유지)
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': '불안에 대한 교육',
        'subtitle': '불안을 이해하고 관리하기',
        'onTap': () => Navigator.pushNamed(context, '/education'),
      },
      {
        'title': '이완',
        'subtitle': '긴장을 완화하고 마음을 안정시키기',
        'onTap': () => Navigator.pushNamed(context, '/relaxation_education'),
      },
      {
        'title': '걱정 일기 목록',
        'subtitle': '나의 걱정 기록 살펴보기',
        'onTap': () => Navigator.pushNamed(context, '/diary_directory'),
      },
      {
        'title': '걱정 그룹',
        'subtitle': '비슷한 걱정을 묶어서 정리하기',
        'onTap': () => Navigator.pushNamed(context, '/diary_group'),
      },
      {
        'title': '보관함',
        'subtitle': '완료한 일기와 그룹을 모아보기',
        'onTap': () => Navigator.pushNamed(context, '/archive'),
      },
    ];

    /// 📋 TreatmentDesign 형식으로 변환
    final weekContents =
        menuItems
            .map(
              (e) => {
                'title': e['title'] as String,
                'subtitle': e['subtitle'] as String,
              },
            )
            .toList();

    /// 📘 라우팅용 위젯 리스트
    final weekScreens =
        menuItems
            .map((e) => _MenuRouteLauncher(onTap: e['onTap'] as VoidCallback))
            .toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        /// 🌊 배경 (TreatmentDesign 내부의 배경을 덮지 않음)
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003B5C), Color(0xFF4EB4E5), Color(0xFFBFF4FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        /// 🪸 본체 — TreatmentDesign 그대로 사용
        Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              /// 원본 디자인 사용
              SafeArea(
                child: TreatmentDesign(
                  appBarTitle: '', // AppBar 제목 비워서 UI 최소화
                  weekContents: weekContents,
                  weekScreens: weekScreens,
                ),
              ),

              /// 🚫 AppBar 시각적으로 가리는 투명 레이어
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: kToolbarHeight + MediaQuery.of(context).padding.top,
                child: IgnorePointer(
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 📘 TreatmentDesign 내부에서 push만 수행하는 위젯
class _MenuRouteLauncher extends StatelessWidget {
  final VoidCallback onTap;
  const _MenuRouteLauncher({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onTap();
    });
    return const SizedBox.shrink();
  }
}
