// 🪸 Mindrium TreatmentDesign — UI + AppBar 포함 완전 리팩터링
// import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class TreatmentDesign extends StatelessWidget {
  final String appBarTitle;
  final List<Map<String, String>> weekContents;
  final List<Widget> weekScreens;

  const TreatmentDesign({
    super.key,
    required this.appBarTitle,
    required this.weekContents,
    required this.weekScreens,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        /// 🌊 배경 (HomeScreen과 동일 - 전체 화면)
        Positioned.fill(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/image/eduhome.png', fit: BoxFit.cover),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xAAFFFFFF), Color(0x66FFFFFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 💎 본문 컨텐츠
        Column(
          children: [
            /// 🧭 맨 위 CustomAppBar (SafeArea 포함)
            SafeArea(
              bottom: false,
              child: CustomAppBar(
                title: '메뉴',
                showHome: true,
                onBack: () {
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/home', (route) => false);
                },
              ),
            ),

            /// 📖 카드 리스트
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    /// 🪸 주차별 카드 리스트
                    for (int i = 0; i < weekContents.length; i++) ...[
                      _buildWeekCard(
                        context,
                        title: weekContents[i]['title'] ?? '',
                        subtitle: weekContents[i]['subtitle'] ?? '',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => weekScreens[i]),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🪸 주차별 카드 (체크 아이콘 제거)
  Widget _buildWeekCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3F2FD), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0E2C48),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF1B405C),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF0E4569),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
