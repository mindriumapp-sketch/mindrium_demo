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
    final filteredSUD = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    for (final d in docs) {
      final sudSnap = await d.reference
          .collection('sud_score')
          .orderBy('updatedAt', descending: true)
          .get();
      // final notiSnap = await d.reference.collection('notification_settings').limit(1).get();
      // if (notiSnap.docs.isNotEmpty) continue;
      if (sudSnap.docs.isEmpty) {
        filteredSUD.add(d);
        continue;
      }
      final sudData = sudSnap.docs.first.data();
      final num? sudVal = sudData['after_sud'];
      if (sudVal == null || sudVal > 2) filteredSUD.add(d);
    }
    return filteredSUD;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    final String? groupId = args['groupId'] as String?;

    if (abcId == null && groupId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('일기 선택')),
        body: const Center(child: Text('잘못된 진입입니다 (abcId / groupId 없음)')),
      );
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('일기 선택')),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    debugPrint('[DiarySelect] filter group_id = $groupId');

    final diaryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .where('group_id', isEqualTo: groupId);

    return Scaffold(
      appBar: const CustomAppBar(title: '일기 선택하기'),
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream: diaryRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rawDocs = snap.data?.docs ?? [];
          for (final d in rawDocs) {
            final val = d['group_id'];
            debugPrint('[DiarySelect] ${d.id} → value=$val type=${val.runtimeType}');
          }
          return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: _filterBySud(rawDocs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>()),
            builder: (context, sudSnap) {
              if (!sudSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = sudSnap.data!;
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '해당 그룹에 SUD 점수가 3점 이상인 일기가 없습니다.',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   Navigator.pushReplacementNamed(
                //     context,
                //     '/diary_show',
                //     arguments: {'groupId': groupId},
                //   );
                // });
                // return const SizedBox.shrink();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.transparent),
                itemBuilder: (context, index) {
                  final d = docs[index];
                  final data = d.data();
                  final title = data['activatingEvent'] as String? ?? '(제목 없음)';
                  final belief = data['belief'] as String?;
                  final consequence = data['consequence'] as String?;
                  return Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: index == 0
                        ? const EdgeInsets.only(bottom: 16)
                        : const EdgeInsets.only(top: 0, bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: CheckboxListTile(
                        value: _selectedIds.contains(d.id),
                        onChanged: (bool? selected) {
                          setState(() {
                            _selectedIds.clear();
                            if (selected == true) {
                              _selectedIds.add(d.id);
                            }
                          });
                        },
                        title: Text('상황: $title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (belief != null) Text('생각: $belief'),
                            if (consequence != null) Text('결과: $consequence'),
                          ],
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryActionButton(
          text: _selectedIds.isNotEmpty ? '선택하기' : '홈으로',
          onPressed: _selectedIds.isNotEmpty
              ? () {
                  final selectedId = _selectedIds.first;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BeforeSudRatingScreen(abcId: selectedId),
                    ),
                  );
                }
              : () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_)=>false),
        ),
      ),
    );
  }
}