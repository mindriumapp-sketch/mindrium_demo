// 🪸 Mindrium AbcGroupAddDesign — TreatmentDesign 새 구조 완전 호환 버전
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/widgets/tap_design.dart'; // ✅ 새 구조로 교체

class AbcGroupAddDesign {
  /// 📂 Firestore 정렬 (그룹 생성일 기준)
  static List<QueryDocumentSnapshot<Map<String, dynamic>>> sortGroups(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    docs.sort((a, b) {
      final aTime = a.data()['createdAt'] as Timestamp?;
      final bTime = b.data()['createdAt'] as Timestamp?;
      if (aTime != null && bTime != null) return aTime.compareTo(bTime);
      return 0;
    });
    return docs;
  }

  /// 🌊 TreatmentDesign 기반 전체 레이아웃
  static Widget buildLayout({
    required BuildContext context,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> groups,
    required String? selectedGroupId,
    required void Function(String, DocumentReference) onSelect,
    required VoidCallback onAddTap,
    Map<String, dynamic>? summary,
  }) {
    return TreatmentDesign(
      appBarTitle: '', // AppBar 없음
      weekContents: const [
        {'title': '내 걱정 그룹', 'subtitle': '당신의 걱정 물고기들을 모아보세요'},
      ],
      weekScreens: [
        _AbcGroupGridScreen(
          groups: groups,
          selectedGroupId: selectedGroupId,
          onSelect: onSelect,
          onAddTap: onAddTap,
          summary: summary,
        ),
      ],
    );
  }
}

/// 🐚 그룹 목록 화면 (TreatmentDesign 내부 콘텐츠)
class _AbcGroupGridScreen extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> groups;
  final String? selectedGroupId;
  final void Function(String, DocumentReference) onSelect;
  final VoidCallback onAddTap;
  final Map<String, dynamic>? summary;

  const _AbcGroupGridScreen({
    required this.groups,
    required this.selectedGroupId,
    required this.onSelect,
    required this.onAddTap,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 1080;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: groups.length + 1,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width < 420 ? 2 : 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 18 * scale,
                mainAxisSpacing: 18 * scale,
              ),
              itemBuilder: (context, index) {
                if (index == 0) {
                  /// ➕ 그룹 추가 버튼
                  return GestureDetector(
                    onTap: onAddTap,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB8E1FF), Color(0xFFD9F7F1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24 * scale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .1),
                            blurRadius: 10 * scale,
                            offset: const Offset(3, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add,
                          color: Color(0xFF0A223D),
                          size: 52,
                        ),
                      ),
                    ),
                  );
                }

                final doc = groups[index - 1];
                final data = doc.data();
                final groupId = data['group_id']?.toString() ?? '';
                final title = data['group_title'] ?? '';
                final isSelected = selectedGroupId == groupId;

                return GestureDetector(
                  onTap: () {
                    onSelect(groupId, doc.reference);
                    if (summary != null) {
                      _showSummaryPopup(context, scale, summary!);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20 * scale),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFF4EB4E5)
                                : Colors.black12,
                        width: isSelected ? 2.4 * scale : 1.2 * scale,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .05),
                          blurRadius: 8 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18 * scale),
                            child: Image.asset(
                              'assets/image/character$groupId.png',
                              width: 90 * scale,
                              height: 90 * scale,
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => const Icon(
                                    Icons.person,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10 * scale),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF0E2C48),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🌫 Glass Popup 요약창 (TreatmentDesign 일관 스타일)
  static void _showSummaryPopup(
    BuildContext context,
    double scale,
    Map<String, dynamic> summary,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      builder: (context) {
        final width = MediaQuery.of(context).size.width * 0.88;
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28 * scale),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: width,
                padding: EdgeInsets.all(28 * scale),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .25),
                  borderRadius: BorderRadius.circular(28 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: .2),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF0A223D),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        summary['titleText'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0A223D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        summary['scoreText'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4EB4E5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary['countText'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0A223D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .4),
                          borderRadius: BorderRadius.circular(16 * scale),
                        ),
                        child: Text(
                          summary['contentText'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF0E2C48),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
