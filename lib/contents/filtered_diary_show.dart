import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';

class DiaryShowScreen extends StatelessWidget {
  final String? groupId;
  
  const DiaryShowScreen({
    super.key,
    this.groupId
  });

  String _formatAlarm(Map<String, dynamic> d) {
    try {
      final location  = (d['location'] ?? '').toString().trim();
      final inout     = <String>[
        if (d['notifyEnter'] == true) '들어갈 때',
        if (d['notifyExit']  == true) '나올 때',
      ].join('/');
      final timeVal   = (d['time'] ?? '').toString().trim();
      final repeatOpt = (d['repeatOption'] ?? '').toString();

      final rawWd = d['weekdays'];
      final weekdayInts = rawWd is List
          ? rawWd.cast<int>()
          : (rawWd is String && rawWd.isNotEmpty)
              ? rawWd.replaceAll(RegExp(r'[\[\]\s]'), '').split(',')
                  .where((e) => e.isNotEmpty)
                  .map<int>((e) => int.parse(e))
                  .toList()
              : <int>[];
      final wdLabel = _weekdayLabel(weekdayInts);


      final parts = <String>[
        if (repeatOpt == 'daily')
          '[매일'
        else if (repeatOpt == 'weekly' && wdLabel.isNotEmpty)
          '[매주 ($wdLabel)',
        if (location.isNotEmpty) location,
        if (timeVal.isNotEmpty)  timeVal else inout,
      ];
      return parts.join(', ');
    } catch (e, st) {
      debugPrint('⚠️ DiaryCard: format error - $e');
      debugPrintStack(stackTrace: st);
      return '알림 없음';
    }
  }

  String _weekdayLabel(List<int> weekdayInts) {
    if (weekdayInts.isEmpty) return '';
    const names = ['일', '월', '화', '수', '목', '금', '토'];
    weekdayInts..removeWhere((e) => e < 1 || e > 7)..sort();
    return weekdayInts.map((d) => names[d - 1]).join(', ');
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _filterBySud(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    // 각 문서를 독립적으로 처리하고, 병렬 실행으로 지연 최소화
    final results = await Future.wait(docs.map((d) async {
      // 알림 존재 여부
      final notiSnap = await d.reference
          .collection('notification_settings')
          .limit(1)
          .get();

      if (notiSnap.docs.isEmpty) return null;

      // 최신 SUD 1건
      final sudSnap = await d.reference
          .collection('sud_score')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();

      if (sudSnap.docs.isEmpty) return d;

      final sudData = sudSnap.docs.first.data();
      final num? sudVal = sudData['after_sud'];

      return (sudVal == null || sudVal > 2) ? d : null;
    }));

    // null 제거
    return results.whereType<QueryDocumentSnapshot<Map<String, dynamic>>>().toList();
  }

  Widget _buildDiaryList(BuildContext context,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '해결되지 않은 불안이 그룹에 남아있어요. ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return StatefulBuilder(
                builder: (context, setState) {
                  final d = docs[index];
                  final Map<String, dynamic> data = d.data();
                  final title = data['activatingEvent'] as String? ?? '(제목 없음)';
                  return FutureBuilder<QuerySnapshot>(
                    future: d.reference.collection('notification_settings').get(),
                    builder: (context, notiSnap) {
                      if (!notiSnap.hasData || notiSnap.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 16),
                                for (int i = 0; i < notiSnap.data!.docs.length; i++) ...[
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(fontSize: 20, color: Colors.black),
                                      children: [
                                        TextSpan(
                                          text:
                                              '${_formatAlarm(notiSnap.data!.docs[i].data() as Map<String, dynamic>)}] ',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(
                                            text: '에 알림이 울리면 "'),
                                        TextSpan(
                                          text: title,
                                        ),
                                        const TextSpan(
                                            text: '"에 대한 감정을 차분히 들여다보아요.\n'),
                                      ],
                                    ),
                                  ),
                                ],
                                const Text(
                                  '잘 해낼 수 있을거에요!',
                                  style: TextStyle(fontSize: 20),
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
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? groupId = args['groupId'] as String?;
    debugPrint('[diary_show] groupId=$groupId');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    final diaryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .where('group_id', isEqualTo: groupId);
    
    return Scaffold(
      appBar: CustomAppBar(title: '일기 목록'),
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: PrimaryActionButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_)=>false), 
          text: '확인'
        )
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: diaryRef.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final rawDocs = snap.data?.docs ?? [];

          return FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: _filterBySud(
                rawDocs.cast<QueryDocumentSnapshot<Map<String, dynamic>>>()),
            builder: (context, sudSnap) {
              if (sudSnap.hasError) {
                debugPrint('[DiaryShow] filter error=${sudSnap.error}');
                return Center(child: Text('일기 로드 중 오류가 발생했습니다.'));
              }
              if (!sudSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = sudSnap.data!;
              if (docs.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/battle');
                });
                return const SizedBox.shrink();
              }

              return _buildDiaryList(context, docs);
            },
          );
        },
      ),
    );
  }
}