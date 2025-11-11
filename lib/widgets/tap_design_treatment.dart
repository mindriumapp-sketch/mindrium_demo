// 🪸 Mindrium TreatmentDesign — 앱바 제거 + 깔끔한 배경 + 버튼 효과
import 'package:flutter/material.dart';

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

    return Scaffold(
      backgroundColor: const Color(0xFFBFF4FF), // 밝은 아쿠아 블루
      extendBodyBehindAppBar: true, // ✅ 상단까지 배경 확장
      body: Stack(
        children: [
          /// 🌊 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.25),
            ),
          ),

          /// 💎 본문 컨텐츠
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              48,
              20,
              32,
            ), // ✅ 상단 여백 확보 (앱바 없을 때 대비)
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: size.width > 480 ? 420 : double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.00), // 은은한 반투명
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// 🪸 주차별 카드 리스트
                    for (int i = 0; i < weekContents.length; i++) ...[
                      _buildWeekCard(
                        context,
                        weekNumber: i + 1,
                        title: weekContents[i]['title'] ?? '',
                        subtitle: weekContents[i]['subtitle'] ?? '',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => weekScreens[i]),
                          );
                        },
                      ),
                      if (i < weekContents.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🪸 주차별 카드 (그라디언트 + 소프트 섀도우로 버튼 느낌)
  Widget _buildWeekCard(
    BuildContext context, {
    required int weekNumber,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final parts = subtitle.split(' / ');
    final koreanText = parts.length > 1 ? parts[1] : '';
    final englishText = parts.isNotEmpty ? parts[0] : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          // ✨ 은은한 그라디언트 (위에서 아래로)
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0.98),
              Colors.white.withOpacity(0.88),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE3F2FD).withOpacity(0.8),
            width: 1.2,
          ),
          boxShadow: [
            // 🌟 상단 하이라이트
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 1,
              offset: const Offset(0, -0.5),
            ),
            // 💫 소프트 섀도우
            BoxShadow(
              color: const Color(0xFF7FC4EC).withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: -2,
            ),
            // 🎨 메인 섀도우
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 좌측: 주차 아이콘
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE6F6FF), Color(0xFFD5EFFF)],
                ),
                border: Border.all(
                  color: Color(0xFF7FC4EC).withOpacity(0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7FC4EC).withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF5BA8D8),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            /// 중앙: subtitle (한글 + 영어)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    koreanText,
                    style: const TextStyle(
                      color: Color(0xFF4A7BA7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  if (englishText.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      englishText,
                      style: const TextStyle(
                        color: Color(0xFF6B9AC4),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            /// 우측: 화살표
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF5BA8D8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
