// 🔹 Mindrium: 걱정 일기 알림 목록 화면 (DiaryShowScreen)
// 사용자가 특정 걱정 그룹(groupId)에 설정한 알림(notification_settings)을 모아 보여주는 화면
// 해결되지 않은(불안 점수 SUD > 2) 일기들만 표시하며,
// 각 일기별 알림 시간·요일·장소 조건을 설명문 형태로 보여줌
// 연결 흐름:
//   DiarySelectScreen → DiaryShowScreen
//     ├─ Firestore에서 group_id에 해당하는 일기 목록 조회
//     ├─ notification_settings 하위 컬렉션이 존재하는 문서만 필터링
//     ├─ SUD(after_sud)가 3 이상인 일기만 남김
//     ├─ 각 일기 카드에 알림 내용(요일, 시간, 장소 등)을 자연어로 표시
//     ├─ 일기가 없으면 자동으로 /battle 화면으로 이동
//     └─ 하단 ‘확인’ 버튼 → 홈(/home)으로 복귀
// import 목록:
//   cloud_firestore.dart      → Firestore 데이터 조회 및 필터링
//   firebase_auth.dart        → 로그인 사용자 UID 확인
//   flutter/material.dart     → 기본 Flutter 위젯
//   gad_app_team/widgets/custom_appbar.dart → 공통 상단바
//   gad_app_team/widgets/primary_action_button.dart → 하단 버튼 UI

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';

/// 🌊 Mindrium 스타일: 걱정 일기 알림 목록 화면
/// - 오션 톤 그라데이션 + eduhome 반투명 오버레이
/// - Glass 카드 + 부드러운 텍스트 + 자연스러운 문장 강조
///
class DiaryShowScreen extends StatelessWidget {
  final String? groupId;

  const DiaryShowScreen({super.key, this.groupId});

  String _weekdayLabel(List<int> weekdayInts) {
    if (weekdayInts.isEmpty) return '';
    const names = ['일', '월', '화', '수', '목', '금', '토'];
    weekdayInts
      ..removeWhere((e) => e < 1 || e > 7)
      ..sort();
    return weekdayInts.map((d) => names[d - 1]).join(', ');
  }

  String _formatAlarm(Map<String, dynamic> d) {
    try {
      final location = (d['location'] ?? '').toString().trim();
      final inout = <String>[
        if (d['notifyEnter'] == true) '들어갈 때',
        if (d['notifyExit'] == true) '나올 때',
      ].join('/');
      final timeVal = (d['time'] ?? '').toString().trim();
      final repeatOpt = (d['repeatOption'] ?? '').toString();

      final rawWd = d['weekdays'];
      final weekdayInts =
          rawWd is List
              ? rawWd.cast<int>()
              : (rawWd is String && rawWd.isNotEmpty)
              ? rawWd
                  .replaceAll(RegExp(r'[\[\]\s]'), '')
                  .split(',')
                  .where((e) => e.isNotEmpty)
                  .map<int>((e) => int.parse(e))
                  .toList()
              : <int>[];
      final wdLabel = _weekdayLabel(weekdayInts);

      final parts = <String>[
        if (repeatOpt == 'daily')
          '매일'
        else if (repeatOpt == 'weekly' && wdLabel.isNotEmpty)
          '매주 ($wdLabel)',
        if (location.isNotEmpty) location,
        if (timeVal.isNotEmpty) timeVal else inout,
      ];
      return parts.join(', ');
    } catch (_) {
      return '알림 없음';
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _filterBySud(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final results = await Future.wait(
      docs.map((d) async {
        final notiSnap =
            await d.reference
                .collection('notification_settings')
                .limit(1)
                .get();
        if (notiSnap.docs.isEmpty) return null;

        final sudSnap =
            await d.reference
                .collection('sud_score')
                .orderBy('updatedAt', descending: true)
                .limit(1)
                .get();
        if (sudSnap.docs.isEmpty) return d;

        final sudData = sudSnap.docs.first.data();
        final num? sudVal = sudData['after_sud'];
        return (sudVal == null || sudVal > 2) ? d : null;
      }),
    );
    return results
        .whereType<QueryDocumentSnapshot<Map<String, dynamic>>>()
        .toList();
  }

  Widget _buildDiaryCard(
    BuildContext context,
    String title,
    List<QueryDocumentSnapshot> notifications,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F3D63),
            ),
          ),
          const SizedBox(height: 10),
          for (final n in notifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Noto Sans KR',
                    fontSize: 14.5,
                    height: 1.5,
                    color: Color(0xFF232323),
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${_formatAlarm(n.data() as Map<String, dynamic>)}에 ',
                      style: const TextStyle(
                        color: Color(0xFF47A6FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '알림이 울리면 '),
                    TextSpan(
                      text: '"$title"',
                      style: const TextStyle(
                        color: Color(0xFF007BCE),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: '에 대한 감정을 차분히 들여다보세요.\n'),
                    const TextSpan(
                      text: '잘 해낼 수 있을 거예요 💙',
                      style: TextStyle(
                        color: Color(0xFF007BCE),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDiaryList(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return Stack(
      children: [
        // 🌊 배경: 오션 그라데이션 + 반투명 오버레이
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB4E0FF), Color(0xFFE3F6FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Opacity(
          opacity: 0.25,
          child: Image.asset(
            'assets/image/eduhome.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 80),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                child: Text(
                  '아직 해결되지 않은 불안이 남아있어요 🐚\n아래 일기들을 다시 살펴보세요.',
                  style: TextStyle(
                    fontFamily: 'Noto Sans KR',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F3D63),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final d = docs[index];
                    final data = d.data();
                    final title =
                        (data['activatingEvent'] ?? '(제목 없음)').toString();
                    return FutureBuilder<QuerySnapshot>(
                      future:
                          d.reference.collection('notification_settings').get(),
                      builder: (context, notiSnap) {
                        if (!notiSnap.hasData || notiSnap.data!.docs.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _buildDiaryCard(
                          context,
                          title,
                          notiSnap.data!.docs,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? groupId = args['groupId'] as String?;
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
      appBar: const CustomAppBar(title: '걱정 일기 알림 목록'),
      body: StreamBuilder<QuerySnapshot>(
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
              if (sudSnap.hasError) {
                return const Center(child: Text('일기 로드 중 오류가 발생했습니다.'));
              }
              if (!sudSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = sudSnap.data!;
              if (docs.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/battle');
                  }
                });
                return const SizedBox.shrink();
              }
              return _buildDiaryList(context, docs);
            },
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: PrimaryActionButton(
          text: '확인',
          onPressed:
              () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (_) => false,
              ),
        ),
      ),
    );
  }
}
