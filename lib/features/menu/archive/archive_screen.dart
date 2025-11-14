import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/features/menu/menu_screen.dart'; // 또는 실제 경로

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});
  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    final uid = user.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '걱정 물고기 보관함',
        showHome: true,
        confirmOnHome: false,
        confirmOnBack: false,
        onBack: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ContentScreen()),
                (route) => false,
          );
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🎨 배경
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/image/eduhome.png', fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xCCFFFFFF), Color(0x88FFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 📜 본문
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('abc_models')
                  .snapshots(),
              builder: (ctxAll, allSnap) {
                if (allSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5B9FD3),
                      strokeWidth: 3,
                    ),
                  );
                }

                final diaryDocs = allSnap.data?.docs
                    .where((d) =>
                (d.data()['group_id'] as String?)?.isNotEmpty ==
                    true)
                    .toList() ??
                    [];

                // group_id → docs
                final Map<String,
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>>
                diariesByGroup = {};
                for (var d in diaryDocs) {
                  final gid = d.data()['group_id'] as String;
                  diariesByGroup.putIfAbsent(gid, () => []).add(d);
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('abc_group')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (ctxGrp, grpSnap) {
                    if (grpSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5B9FD3),
                          strokeWidth: 3,
                        ),
                      );
                    }

                    final archivedDocs = grpSnap.data?.docs
                        .where((d) => d.data()['archived'] == true)
                        .toList() ??
                        [];

                    if (archivedDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: const Color(0xFF5B9FD3).withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '보관된 걱정 그룹이 없습니다',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF1B405C),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '걱정 물고기를 보관해보세요 🪸',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // 보관일 최근순
                    archivedDocs.sort((a, b) {
                      final aTs =
                          (a.data()['archived_at'] as Timestamp?)?.toDate() ??
                              DateTime(0);
                      final bTs =
                          (b.data()['archived_at'] as Timestamp?)?.toDate() ??
                              DateTime(0);
                      return bTs.compareTo(aTs);
                    });

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;

                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 32 : 16,
                            vertical: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 🎯 섹션 타이틀
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.35),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        '보관된 걱정 물고기',
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0E2C48),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F4FD),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF5B9FD3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '총 ${archivedDocs.length}개',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5B9FD3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 🐠 N×N 그리드 (유리병 느낌 카드)
                              _buildGridCards(
                                context: context,
                                isWide: isWide,
                                docs: archivedDocs,
                              ),

                              // 📝 상세 카드 (테두리 유지)
                              if (_selectedGroupId != null) ...[
                                const SizedBox(height: 24),
                                _buildDetailCard(
                                  uid,
                                  archivedDocs,
                                  diariesByGroup,
                                ),
                              ],

                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔲 N×N 그리드 레이아웃 (반응형)
  Widget _buildGridCards({
    required BuildContext context,
    required bool isWide,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) {
    // 화면 크기에 따라 열 개수 결정
    final crossAxisCount = isWide ? 4 : 3;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // 더 투명한 배경으로 물결 무늬 노출
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.82, // 적당한 가로세로 비율
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          return _buildGlassBottleCard(
            doc: doc,
            isSelected:
            _selectedGroupId == doc.data()['group_id']?.toString(),
            onTap: () {
              setState(() {
                _selectedGroupId = doc.data()['group_id']?.toString();
              });
            },
          );
        },
      ),
    );
  }

  /// 🍶 유리병 느낌 카드 (선택 시 강조 표현 강화)
  Widget _buildGlassBottleCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final data = doc.data();
    final groupId = data['group_id']?.toString() ?? '';
    final title = data['group_title']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // 🍶 유리병 느낌: 선택 시 더 밝고 선명한 그라데이션
          gradient: isSelected
              ? const LinearGradient(
            colors: [
              Color(0xFFE8F4FD), // 밝은 파란색 톤
              Color(0xFFF0F8FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              Colors.white.withOpacity(0.65),
              Colors.white.withOpacity(0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          // ✨ 선택 시 테두리 추가 + 더 강한 그림자
          border: isSelected
              ? Border.all(
            color: const Color(0xFF5B9FD3),
            width: 2.5,
          )
              : null,
          boxShadow: [
            // 메인 그림자
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF5B9FD3).withOpacity(0.35)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 24 : 16,
              spreadRadius: isSelected ? 2 : 0,
              offset: Offset(0, isSelected ? 10 : 6),
            ),
            // 선택 시 추가 글로우 효과
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF5B9FD3).withOpacity(0.2),
                blurRadius: 16,
                spreadRadius: -2,
                offset: const Offset(0, 0),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🐟 캐릭터 이미지 (선택 시 스케일 효과)
            Expanded(
              child: Center(
                child: Hero(
                  tag: 'character_$groupId',
                  child: AnimatedScale(
                    scale: isSelected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // 선택 시 더 밝고 선명한 배경
                        gradient: isSelected
                            ? const LinearGradient(
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFF5FAFF),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                            : null,
                        color: isSelected
                            ? null
                            : Colors.white.withOpacity(0.7),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF5B9FD3).withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: isSelected ? 16 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/image/character$groupId.png',
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.catching_pokemon,
                          size: 50,
                          color: isSelected
                              ? const Color(0xFF5B9FD3)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // 📝 제목 (선택 시 더 진한 색상)
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isSelected ? 13 : 12.5,
                color: isSelected
                    ? const Color(0xFF0E2C48)
                    : const Color(0xFF4A5568),
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📋 상세 카드 (테두리 유지)
  Widget _buildDetailCard(
      String uid,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> archivedDocs,
      Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      diariesByGroup,
      ) {
    if (_selectedGroupId == null) return const SizedBox.shrink();

    final matches = archivedDocs
        .where((d) =>
    (d.data()['group_id']?.toString() ?? '') == _selectedGroupId)
        .toList();
    if (matches.isEmpty) return const SizedBox.shrink();

    final selectedDoc = matches.first;
    final data = selectedDoc.data();
    final groupId = data['group_id']?.toString() ?? '';
    final title = data['group_title']?.toString() ?? '';
    final contents = data['group_contents']?.toString() ?? '';
    final timestamp = data['archived_at'] as Timestamp?;
    final archivedAt = timestamp?.toDate() ?? DateTime.now();
    final archivedStr = DateFormat('yyyy.MM.dd').format(archivedAt);
    final count = diariesByGroup[groupId]?.length ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFAFDFF), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        // ✅ 테두리 유지
        border: Border.all(
          color: const Color(0xFF5B9FD3),
          width: 2.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5B9FD3).withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 헤더
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 캐릭터 아바타
              Hero(
                tag: 'detail_character_$groupId',
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB8DAF5), Color(0xFFD4E7F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5B9FD3).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/image/character$groupId.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.catching_pokemon,
                        size: 32,
                        color: Color(0xFF0E2C48),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // 제목 및 보관일
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: Color(0xFF0E2C48),
                        height: 1.3,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD6E2FF)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Color(0xFF496AC6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '보관일: $archivedStr',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF496AC6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 📝 설명
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B9FD3).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    contents.isEmpty ? '저장된 설명이 없습니다.' : contents,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF1B405C),
                      height: 1.58,
                      fontWeight:
                      contents.isEmpty ? FontWeight.w500 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 📔 일기 CTA
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('일기 목록으로 이동합니다.')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Text(
                    '일기',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF566370),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFE8FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count개',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF4659C2),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Color(0xFF4659C2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}