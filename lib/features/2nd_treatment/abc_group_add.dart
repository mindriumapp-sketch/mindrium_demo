import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/navigation_button.dart';
import 'abc_group_add_screen.dart';
import 'notification_selection_screen.dart';

class AbcGroupAddScreen extends StatefulWidget {
  final String? label;
  final String? abcId;
  final String? origin;
  final int? beforeSud;
  final String? diary;

  const AbcGroupAddScreen({
    super.key,
    this.label,
    this.abcId,
    this.origin,
    this.beforeSud,
    this.diary,
  });

  @override
  State<AbcGroupAddScreen> createState() => _AbcGroupAddScreenState();
}

class _AbcGroupAddScreenState extends State<AbcGroupAddScreen> {
  String? _selectedGroupId;
  DocumentReference? _selectedGroupRef;

  // 🎨 개선된 편집 다이얼로그
  void _showEditDialog(
      BuildContext context,
      Map<String, dynamic> group,
      DocumentReference docRef,
      ) {
    final titleCtrl = TextEditingController(text: group['group_title']);
    final contentsCtrl = TextEditingController(text: group['group_contents']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFAFDFF), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A5B9FD3),
                blurRadius: 20,
                offset: Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B9FD3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "그룹 편집",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Color(0xFF0E2C48),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 제목 입력
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE3F2FD),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: titleCtrl,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    labelText: '제목',
                    labelStyle: TextStyle(
                      color: Color(0xFF5B9FD3),
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 설명 입력
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE3F2FD),
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: contentsCtrl,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    labelText: '설명',
                    labelStyle: TextStyle(
                      color: Color(0xFF5B9FD3),
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade100,
                        foregroundColor: Colors.grey.shade700,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await docRef.update({
                          'group_title': titleCtrl.text,
                          'group_contents': contentsCtrl.text,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_rounded, size: 20),
                      label: const Text(
                        '수정',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B9FD3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 🎨 추가하기 카드 (맑은 유리 스타일)
  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AbcGroupAddScreen1()),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.85),
              Colors.white.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF5B9FD3).withOpacity(0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B9FD3).withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            // 상단 하이라이트 (유리 반짝임)
            BoxShadow(
              color: Colors.white.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF5B9FD3).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 32,
                color: Color(0xFF5B9FD3),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '추가하기',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Color(0xFF0E2C48),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🍶 맑고 반짝이는 유리병 그룹 카드
  Widget _buildGroupCard({
    required Map<String, dynamic> group,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final groupIdStr = group['group_id']?.toString() ?? '';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [
              Color(0xFFE0F2FF), // 더 밝고 맑은 파란색
              Color(0xFFF0F9FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              Colors.white.withOpacity(0.85), // 더 높은 투명도
              Colors.white.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(
            color: const Color(0xFF5B9FD3),
            width: 2.5,
          )
              : Border.all(
            color: Colors.white.withOpacity(0.9), // 밝은 테두리
            width: 1.5,
          ),
          boxShadow: [
            // 메인 그림자
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF5B9FD3).withOpacity(0.35)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isSelected ? 24 : 16,
              spreadRadius: isSelected ? 2 : 0,
              offset: Offset(0, isSelected ? 10 : 6),
            ),
            // 상단 하이라이트 (유리 반짝임 효과)
            BoxShadow(
              color: Colors.white.withOpacity(isSelected ? 0.6 : 0.4),
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
            // 선택 시 글로우
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
            Expanded(
              child: Center(
                child: AnimatedScale(
                  scale: isSelected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [Color(0xFFFFFFFF), Color(0xFFF5FAFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                          : null,
                      color:
                      isSelected ? null : Colors.white.withOpacity(0.7),
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
                      'assets/image/character$groupIdStr.png',
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
            const SizedBox(height: 10),
            Text(
              group['group_title'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }
    final userId = user.uid;
    final groupRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('abc_group');

    return Scaffold(
      extendBody: true, // 💡 추가: body가 bottomNavigationBar 영역까지 확장되도록 설정
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(title: '걱정 그룹 - 추가하기'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🎨 배경 이미지 & 그라데이션
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/image/eduhome.png',
                  fit: BoxFit.cover,
                ),
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

          // 📜 메인 콘텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Grid (스크롤 영역) ───────────────────────────────
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: groupRef.snapshots(),
                      builder: (ctx, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF5B9FD3),
                              strokeWidth: 3,
                            ),
                          );
                        }
                        if (snap.hasError || snap.data == null) {
                          return const Center(
                            child: Text('데이터를 불러오는 중 오류가 발생했습니다.'),
                          );
                        }

                        // 정렬
                        final sortedGroups = snap.data!.docs.toList()
                          ..sort((a, b) {
                            final aData = a.data()! as Map<String, dynamic>;
                            final bData = b.data()! as Map<String, dynamic>;
                            final aId = aData['group_id']?.toString() ?? '';
                            final bId = bData['group_id']?.toString() ?? '';
                            if (aId == '1' && bId != '1') return -1;
                            if (bId == '1' && aId != '1') return 1;
                            final aTime = aData['createdAt'] as Timestamp?;
                            final bTime = bData['createdAt'] as Timestamp?;
                            if (aTime != null && bTime != null) {
                              return aTime.compareTo(bTime);
                            } else if (aTime == null && bTime != null) {
                              return 1;
                            } else if (aTime != null && bTime == null) {
                              return -1;
                            }
                            return 0;
                          });

                        // 🔹 바깥 큰 카드 제거: GridView 자체에 패딩만 적용
                        return GridView.count(
                          padding: const EdgeInsets.all(16), // 여백만 유지
                          crossAxisCount: 3,
                          childAspectRatio: 0.82,
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: ClampingScrollPhysics(),
                          ),
                          children: [
                            _buildAddCard(),
                            for (final doc in sortedGroups)
                              Builder(
                                builder: (_) {
                                  final data = doc.data()! as Map<String, dynamic>;
                                  final groupIdStr = data['group_id']?.toString() ?? '';
                                  final isSelected = _selectedGroupId == groupIdStr;
                                  return _buildGroupCard(
                                    group: data,
                                    isSelected: isSelected,
                                    onTap: () {
                                      setState(() {
                                        _selectedGroupId = groupIdStr;
                                        _selectedGroupRef = doc.reference;
                                      });
                                    },
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ),


                  // ─── 상세 정보 카드 ───────────────────────────────
                  if (_selectedGroupId != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 240,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: groupRef.snapshots(),
                        builder: (ctx, snap) {
                          if (snap.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (snap.hasError || snap.data == null) {
                            return const Center(
                              child: Text('그룹을 불러오는 중 오류가 발생했습니다.'),
                            );
                          }

                          final sortedGroups = snap.data!.docs.toList()
                            ..sort((a, b) {
                              final aData = a.data()! as Map<String, dynamic>;
                              final bData = b.data()! as Map<String, dynamic>;
                              final aId = aData['group_id']?.toString() ?? '';
                              final bId = bData['group_id']?.toString() ?? '';
                              if (aId == '1' && bId != '1') return -1;
                              if (bId == '1' && aId != '1') return 1;
                              final aTime = aData['createdAt'] as Timestamp?;
                              final bTime = bData['createdAt'] as Timestamp?;
                              if (aTime != null && bTime != null) {
                                return aTime.compareTo(bTime);
                              } else if (aTime == null && bTime != null) {
                                return 1;
                              } else if (aTime != null && bTime == null) {
                                return -1;
                              }
                              return 0;
                            });

                          final matches = sortedGroups.where((d) {
                            final data = d.data()! as Map<String, dynamic>;
                            return (data['group_id']?.toString() ?? '') ==
                                _selectedGroupId;
                          }).toList();

                          if (matches.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          final selectedDoc = matches.first;
                          final data =
                          selectedDoc.data()! as Map<String, dynamic>;
                          final groupIdStr =
                              data['group_id']?.toString() ?? '';

                          return StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('abc_models')
                                .where('group_id', isEqualTo: groupIdStr)
                                .snapshots(),
                            builder: (ctx2, snap2) {
                              if (snap2.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF5B9FD3),
                                    strokeWidth: 3,
                                  ),
                                );
                              }
                              if (snap2.hasError || snap2.data == null) {
                                return const Text(
                                    '일기를 불러오는 중 오류가 발생했습니다.');
                              }

                              final diaryDocs = snap2.data!.docs;
                              final count = diaryDocs.length;

                              return FutureBuilder<double>(
                                future: (() async {
                                  double total = 0;
                                  int validCount = 0;
                                  for (final d in diaryDocs) {
                                    final subCol = await FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(userId)
                                        .collection('abc_models')
                                        .doc(d.id)
                                        .collection('sud_score')
                                        .get();
                                    for (final sub in subCol.docs) {
                                      final data = sub.data();
                                      final after = data['after_sud'];
                                      if (after is num) {
                                        total += after.toDouble();
                                        validCount++;
                                      }
                                    }
                                  }
                                  return validCount > 0
                                      ? total / validCount
                                      : 0.0;
                                })(),
                                builder: (ctx3, avgSnap) {
                                  final avgScore = avgSnap.data ?? 0.0;
                                  return AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFAFDFF),
                                          Color(0xFFFFFFFF)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFF5B9FD3),
                                        width: 2.3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5B9FD3)
                                              .withOpacity(0.18),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        // 헤더
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '<${data['group_title']}>',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 18,
                                                  color: Color(0xFF0E2C48),
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => _showEditDialog(
                                                context,
                                                data,
                                                selectedDoc.reference,
                                              ),
                                              child: Container(
                                                padding:
                                                const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF5B9FD3)
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.more_vert_rounded,
                                                  size: 20,
                                                  color: Color(0xFF5B9FD3),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // 통계
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                  const Color(0xFFF6FAFF),
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Text(
                                                      '주관적 점수',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                        Color(0xFF566370),
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${avgScore.toStringAsFixed(1)}/10',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                        FontWeight.w900,
                                                        color:
                                                        Color(0xFF7E57C2),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Container(
                                                padding:
                                                const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color:
                                                  const Color(0xFFF6FAFF),
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const Text(
                                                      '일기',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                        Color(0xFF566370),
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '$count개',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                        FontWeight.w900,
                                                        color:
                                                        Color(0xFF5C6BC0),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // 설명
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF6FAFF),
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            child: SingleChildScrollView(
                                              child: Text(
                                                data['group_contents'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF1B405C),
                                                  height: 1.6,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
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
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        // 💡 수정된 부분: 배경을 투명하게 만듭니다.
        color: Colors.transparent,
        // decoration을 사용하지 않으므로 그림자 효과도 제거됩니다.
        child: Padding(
          // 버튼 자체에 흰색 배경이 있기 때문에, 여백이 필요합니다.
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: NavigationButtons(
            leftLabel: '이전',
            rightLabel: '다음',
            onBack: () => Navigator.pop(context),
            onNext: () async {
              if (_selectedGroupId == null || widget.abcId == null) return;

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('abc_models')
                  .doc(widget.abcId)
                  .update({'group_id': _selectedGroupId});

              final origin = widget.origin ?? 'etc';
              if (origin == 'apply') {
                int completed = 0;
                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid != null) {
                  completed = 5; //TODO: test용 (5주차)
                }
                if (!context.mounted) return;
                if (completed >= 4) {
                  Navigator.pushNamed(
                    context,
                    '/relax_or_alternative',
                    arguments: {
                      'abcId': widget.abcId,
                      if (widget.beforeSud != null)
                        'beforeSud': widget.beforeSud,
                      if (widget.beforeSud != null) 'sud': widget.beforeSud,
                      'diary': widget.diary,
                    },
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    '/relax_yes_or_no',
                    arguments: {
                      'abcId': widget.abcId,
                      if (widget.beforeSud != null)
                        'beforeSud': widget.beforeSud,
                      if (widget.beforeSud != null) 'sud': widget.beforeSud,
                      'diary': widget.diary,
                    },
                  );
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotificationSelectionScreen(
                      origin: origin,
                      abcId: widget.abcId,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}