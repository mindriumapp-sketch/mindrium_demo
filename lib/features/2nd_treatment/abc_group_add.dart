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
  // ✅ 인덱스 대신 DB상의 group_id(문자열)와 문서 ref를 상태로 보관
  String? _selectedGroupId;
  DocumentReference? _selectedGroupRef;

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> group,
    DocumentReference docRef,
  ) {
    final titleCtrl = TextEditingController(text: group['group_title']);
    final contentsCtrl = TextEditingController(text: group['group_contents']);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "그룹 편집",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '제목'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contentsCtrl,
                decoration: const InputDecoration(labelText: '설명'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // ElevatedButton.icon(
                  //   onPressed: () async {
                  //     await docRef.delete();
                  //     Navigator.pop(ctx);
                  //   },
                  //   icon: const Icon(Icons.delete),
                  //   label: const Text("삭제"),
                  //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  // ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await docRef.update({
                        'group_title': titleCtrl.text,
                        'group_contents': contentsCtrl.text,
                      });
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save),
                    label: const Text("수정"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black26),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, size: 40, color: Colors.blue),
            SizedBox(height: 8),
            Text(
              '추가하기',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 카드 UI (선택 여부는 group_id로 판단)
  Widget _buildGroupCard({
    required Map<String, dynamic> group,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final groupIdStr = group['group_id']?.toString() ?? '';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Image.asset(
                'assets/image/character$groupIdStr.png',
                height: 70,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stack) =>
                        const Icon(Icons.image_not_supported, size: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              group['group_title'] ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? Colors.indigo : Colors.black,
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
      appBar: CustomAppBar(title: '걱정 그룹 - 추가하기'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Grid (스크롤 영역) ───────────────────────────────
            Expanded(
              flex: 3,
              child: StreamBuilder<QuerySnapshot>(
                stream: groupRef.snapshots(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError || snap.data == null) {
                    return const Center(child: Text('데이터를 불러오는 중 오류가 발생했습니다.'));
                  }

                  // 1) 정렬 (group_id == "1" 우선, 그다음 createdAt 오름차순)
                  final sortedGroups =
                      snap.data!.docs.toList()..sort((a, b) {
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

                  // 2) Grid 렌더링 (인덱스 사용 금지, group_id로 선택)
                  return GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: ClampingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(bottom: 8),
                    children: [
                      _buildAddCard(),
                      for (final doc in sortedGroups)
                        Builder(
                          builder: (_) {
                            final data = doc.data()! as Map<String, dynamic>;
                            final groupIdStr =
                                data['group_id']?.toString() ?? '';
                            final isSelected = _selectedGroupId == groupIdStr;
                            return _buildGroupCard(
                              group: data,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedGroupId =
                                      groupIdStr; // ✅ DB상의 group_id
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

            // ─── 상세 정보 (고정 높이로 오버플로 방지) ───────────────
            if (_selectedGroupId != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 240, // 필요 시 200~320 사이로 조정
                child: StreamBuilder<QuerySnapshot>(
                  stream: groupRef.snapshots(),
                  builder: (ctx, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }
                    if (snap.hasError || snap.data == null) {
                      return const Center(
                        child: Text('그룹을 불러오는 중 오류가 발생했습니다.'),
                      );
                    }

                    // 동일한 정렬 로직
                    final sortedGroups =
                        snap.data!.docs.toList()..sort((a, b) {
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

                    // ✅ firstWhere(orElse) 대신 where().toList()로 안전 처리
                    final matches =
                        sortedGroups.where((d) {
                          final data = d.data()! as Map<String, dynamic>;
                          return (data['group_id']?.toString() ?? '') ==
                              _selectedGroupId;
                        }).toList();

                    if (matches.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    final selectedDoc = matches.first;
                    final data = selectedDoc.data()! as Map<String, dynamic>;
                    final groupIdStr = data['group_id']?.toString() ?? '';

                    // ✅ 여기서만 수정됨 — 주관적 점수 계산 부분
                    return StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('abc_models')
                              .where('group_id', isEqualTo: groupIdStr)
                              .snapshots(),
                      builder: (ctx2, snap2) {
                        if (snap2.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snap2.hasError || snap2.data == null) {
                          return const Text('일기를 불러오는 중 오류가 발생했습니다.');
                        }

                        final diaryDocs = snap2.data!.docs;
                        final count = diaryDocs.length;

                        // ✅ after_sud 기반 평균 계산으로 교체
                        return FutureBuilder<double>(
                          future:
                              (() async {
                                double total = 0;
                                int validCount = 0;
                                for (final d in diaryDocs) {
                                  final subCol =
                                      await FirebaseFirestore.instance
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
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.indigo,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.25),
                                    blurRadius: 6,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '<${data['group_title']}>',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap:
                                            () => _showEditDialog(
                                              context,
                                              data,
                                              selectedDoc.reference,
                                            ),
                                        child: const Icon(
                                          Icons.more_vert,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '주관적 점수: ${avgScore.toStringAsFixed(1)} /10',
                                    style: const TextStyle(fontSize: 15.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '일기 개수: $count개',
                                    style: const TextStyle(fontSize: 15.5),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 100,
                                    width: double.infinity,
                                    child: SingleChildScrollView(
                                      child: Text(
                                        data['group_contents'] ?? '',
                                        style: const TextStyle(fontSize: 15.5),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          leftLabel: '이전',
          rightLabel: '다음',
          onBack: () => Navigator.pop(context),
          onNext: () async {
            if (_selectedGroupId == null || widget.abcId == null) return;

            // ✅ 선택된 DB상의 group_id 문자열을 그대로 저장
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('abc_models')
                .doc(widget.abcId)
                .update({'group_id': _selectedGroupId});

            final origin = widget.origin ?? 'etc';
            if (origin == 'apply') {
              // 적용하기 플로우: 알림 설정을 건너뛰고 개입 선택으로 이동
              int completed = 0;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                // final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                // completed = (snap.data()?['completed_education'] ?? 0) as int;
                completed = 5; //TODO: test용 (5주차)
              }
              if (!context.mounted) return;
              if (completed >= 4) {
                Navigator.pushNamed(
                  context,
                  '/relax_or_alternative',
                  arguments: {
                    'abcId': widget.abcId,
                    if (widget.beforeSud != null) 'beforeSud': widget.beforeSud,
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
                    if (widget.beforeSud != null) 'beforeSud': widget.beforeSud,
                    if (widget.beforeSud != null) 'sud': widget.beforeSud,
                    'diary': widget.diary,
                  },
                );
              }
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => NotificationSelectionScreen(
                        origin: origin,
                        abcId: widget.abcId,
                      ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
