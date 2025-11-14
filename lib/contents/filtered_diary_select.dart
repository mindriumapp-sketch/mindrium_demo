import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/contents/before_sud_screen.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';

class DiarySelectScreen extends StatefulWidget {
  const DiarySelectScreen({super.key});

  @override
  State<DiarySelectScreen> createState() => _DiarySelectScreenState();
}

class _DiarySelectScreenState extends State<DiarySelectScreen> {
  final Set<String> _selectedIds = {};

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _filterBySud(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final filtered = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final d in docs) {
      final sudSnap =
          await d.reference
              .collection('sud_score')
              .orderBy('updatedAt', descending: true)
              .get();
      if (sudSnap.docs.isEmpty) {
        filtered.add(d);
        continue;
      }
      final data = sudSnap.docs.first.data();
      final num? val = data['after_sud'];
      if (val == null || val > 2) filtered.add(d);
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    final String? groupId = args['groupId'] as String?;

    if (abcId == null && groupId == null) {
      return const Scaffold(
        body: Center(child: Text('잘못된 진입입니다 (abcId / groupId 없음)')),
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    final diaryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .where('group_id', isEqualTo: groupId);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: '일기 선택하기'),
      body: Stack(
        children: [
          // 🌊 배경 이미지 + 오션 그라데이션 오버레이
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xCCB3E5FC),
                  Color(0x99E1F5FE),
                  Color(0x66FFFFFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🌿 콘텐츠 본문
          StreamBuilder<QuerySnapshot>(
            stream: diaryRef.snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final rawDocs = snap.data?.docs ?? [];
              return FutureBuilder<
                List<QueryDocumentSnapshot<Map<String, dynamic>>>
              >(
                future: _filterBySud(
                  rawDocs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>(),
                ),
                builder: (context, sudSnap) {
                  if (!sudSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = sudSnap.data!;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          '해당 그룹에 SUD 점수가 3점 이상인 일기가 없습니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontFamily: 'Noto Sans KR',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 100, 20, 120),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final d = docs[index];
                      final data = d.data();
                      final title =
                          data['activatingEvent'] as String? ?? '(제목 없음)';
                      final belief = data['belief'] as String?;
                      final consequence = data['consequence'] as String?;

                      final isSelected = _selectedIds.contains(d.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color:
                                isSelected
                                    ? const Color(0xFF47A6FF)
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() {
                              _selectedIds.clear();
                              _selectedIds.add(d.id);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ✅ 체크 표시
                                Container(
                                  width: 24,
                                  height: 24,
                                  margin: const EdgeInsets.only(
                                    top: 4,
                                    right: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? const Color(0xFF47A6FF)
                                              : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color:
                                        isSelected
                                            ? const Color(0xFF47A6FF)
                                            : Colors.white,
                                  ),
                                  child:
                                      isSelected
                                          ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 16,
                                          )
                                          : null,
                                ),
                                // 📝 일기 내용
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '상황: $title',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Noto Sans KR',
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (belief != null)
                                        Text(
                                          '생각: $belief',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontFamily: 'Noto Sans KR',
                                          ),
                                        ),
                                      if (consequence != null)
                                        Text(
                                          '결과: $consequence',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                            fontFamily: 'Noto Sans KR',
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
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: PrimaryActionButton(
            text: _selectedIds.isNotEmpty ? '선택하기' : '홈으로',
            onPressed:
                _selectedIds.isNotEmpty
                    ? () {
                      final selectedId = _selectedIds.first;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => BeforeSudRatingScreen(abcId: selectedId),
                        ),
                      );
                    }
                    : () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    ),
          ),
        ),
      ),
    );
  }
}
