// 🪸 Mindrium TreatmentDesign — UI + AppBar 포함 완전 리팩터링
import 'dart:ui';
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
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        /// 🌊 배경 (그라데이션 + 반투명 이미지)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003B5C), Color(0xFF4EB4E5), Color(0xFFBFF4FF)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Image.asset(
          'assets/image/eduhome.png',
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.35),
        ),

        /// ☀️ 상단 빛기둥 효과
        IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 240,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.25), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),

        /// 💎 본문 컨텐츠
        SafeArea(
          child: Column(
            children: [
              /// 🧭 맨 위 CustomAppBar
              CustomAppBar(title: appBarTitle, showHome: true),

              /// 📖 중앙 카드 콘텐츠
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          width: size.width > 480 ? 420 : double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 28,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.2),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                '치료 프로그램',
                                style: TextStyle(
                                  fontFamily: 'Noto Sans KR',
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF002E4F),
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 6,
                                      color: Colors.white54,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),

                              /// 🪸 주차별 카드 리스트
                              for (int i = 0; i < weekContents.length; i++) ...[
                                _buildWeekCard(
                                  context,
                                  title: weekContents[i]['title'] ?? '',
                                  subtitle: weekContents[i]['subtitle'] ?? '',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => weekScreens[i],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🪸 주차별 카드
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
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE6F6FF),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF0E4569),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
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