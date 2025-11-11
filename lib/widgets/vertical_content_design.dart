import 'package:flutter/material.dart';

/// ✅ 칩 데이터 구조 (디자인에서 자체 정의)
class GridItem {
  final String label;
  final IconData icon;
  GridItem(this.label, this.icon);
}

/// 🎨 완전 독립형 디자인 전용 위젯
class VerticalContentDesign extends StatelessWidget {
  final List<GridItem> activatingEventChips;
  final List<GridItem> beliefChips;
  final List<GridItem> resultChips;

  const VerticalContentDesign({
    super.key,
    required this.activatingEventChips,
    required this.beliefChips,
    required this.resultChips,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          icon: Icons.event_note,
          title: '상황',
          chips: activatingEventChips,
          backgroundColor: const Color(0xFFDCE7FE), // 연한 파랑
        ),
        _buildArrow(),
        _buildSectionCard(
          icon: Icons.psychology_alt,
          title: '생각',
          chips: beliefChips,
          backgroundColor: const Color(0xFFB1C9EF), // 중간 파랑
        ),
        _buildArrow(),
        _buildSectionCard(
          icon: Icons.emoji_emotions,
          title: '결과',
          chips: resultChips,
          backgroundColor: const Color(0xFF95B1EE), // 진한 파랑
        ),
      ],
    );
  }

  /// ⬇️ 구간 구분용 화살표
  Widget _buildArrow() => const Center(
    child: Icon(
      Icons.keyboard_arrow_down,
      color: Color(0xFF263C69), // 남색
      size: 40,
    ),
  );

  /// 🎨 공통 섹션 카드 디자인
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<GridItem> chips,
    required Color backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF081F5C).withOpacity(0.22),
            offset: const Offset(4, 12),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 왼쪽 아이콘
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF263C69), // 짙은 남색 원
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 10),
            // 타이틀 + 칩 목록
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        chips.map((item) {
                          return Chip(
                            avatar: Icon(
                              item.icon,
                              size: 15,
                              color: const Color(0xFF263C69),
                            ),
                            label: Text(
                              item.label,
                              style: const TextStyle(
                                color: Color(0xFF263C69),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor: const Color(0xFFF6F8FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Color(0xFFCED4DA),
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
