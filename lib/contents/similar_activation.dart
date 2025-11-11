import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SimilarActivationScreen extends StatelessWidget {
  const SimilarActivationScreen({super.key,});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId   = args['abcId'] as String?;
    final String? groupId = args['groupId'] as String?;
    final int? sud   = args['sud'] as int?;
    debugPrint('[diary_show] abcId=$abcId');
    debugPrint('[diary_show] groupId=$groupId');

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {              
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 정보가 없습니다.')),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: '비슷한 상황 확인'),
      backgroundColor: Colors.grey.shade100,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '해당 일기와 비슷한 상황인가요?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<
                  DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('abc_models')
                    .doc(abcId)
                    .get(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || !snap.data!.exists) {
                    return const Center(child: Text('일기 데이터를 찾을 수 없습니다.'));
                  }

                  final data = snap.data!.data()!;
                  final activatingEvent =
                      (data['activatingEvent'] ?? '').toString().trim();
                  final belief =
                      (data['belief'] ?? '').toString().trim();
                  final consequence =
                      (data['consequence'] ?? '').toString().trim();

                  // Chip 리스트 생성
                  final activatingEventChips = [
                    if (activatingEvent.isNotEmpty)
                      Chip(label: Text(activatingEvent)),
                  ];
                  final beliefChips = [
                    if (belief.isNotEmpty) Chip(label: Text(belief)),
                  ];
                  final resultChips = [
                    if (consequence.isNotEmpty) Chip(label: Text(consequence)),
                  ];

                  return SimilarActivationContent(
                    activatingEventChips: activatingEventChips,
                    beliefChips: beliefChips,
                    resultChips: resultChips,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: NavigationButtons(
          leftLabel: '아니오',
          rightLabel: '네',
          onBack: () {
            Navigator.pushNamed(
              context,
              '/diary_yes_or_no',
              arguments: {'origin': 'apply'}
            );
          },
          onNext: () async {
            // Firestore 에서 completed_education 읽기
            final uid = FirebaseAuth.instance.currentUser?.uid;
            int completed = 0;
            if (uid != null) {
              final snap = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
              completed =
                  (snap.data()?['completed_education'] ?? 0) as int;
            }

            debugPrint('[SimilarActivation] completed_education=$completed (abcId=$abcId)');
            if (!context.mounted) return; // async gap 안전 체크
            
            if (completed >= 4) {
              // 4주차 이상: 이완·대체 선택 화면
              Navigator.pushNamed(
                context,
                '/relax_or_alternative',
                arguments: {
                  'abcId': abcId,
                  'sud': sud
                },
              );
            } else {
              // 1~3주차: 이완 여부 확인
              Navigator.pushNamed(
                context,
                '/relax_yes_or_no',
                arguments: {
                  'abcId': abcId,
                  'sud': sud
                },
              );
            }
          },
        ),
      ),
    );
  }
}

/// 내부 콘텐츠(세로형 카드 스택)를 별도 위젯으로 분리해 가독성 향상.
class SimilarActivationContent extends StatelessWidget {
  const SimilarActivationContent({
    super.key,
    required this.activatingEventChips,
    required this.beliefChips,
    required this.resultChips,
  });

  final List<Widget> activatingEventChips;
  final List<Widget> beliefChips;
  final List<Widget> resultChips;

  @override
  Widget build(BuildContext context) {
    return _buildVerticalContent(
      activatingEventChips: activatingEventChips,
      beliefChips: beliefChips,
      resultChips: resultChips,
    );
  }

  /// 기존 `similar_activation.dart` 의 private 함수 래퍼.
  Widget _buildVerticalContent({
    required List<Widget> activatingEventChips,
    required List<Widget> beliefChips,
    required List<Widget> resultChips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          icon: Icons.event_note,
          title: '상황',
          chips: activatingEventChips,
          backgroundColor: const Color.fromARGB(255, 220, 231, 254),
        ),
        Center(
          child: Icon(Icons.keyboard_arrow_down,
              color: Colors.indigo, size: 40),
        ),
        _buildSectionCard(
          icon: Icons.psychology_alt,
          title: '생각',
          chips: beliefChips,
          backgroundColor: const Color(0xFFB1C9EF),
        ),
        Center(
          child: Icon(Icons.keyboard_arrow_down,
              color: Colors.indigo, size: 40),
        ),
        _buildSectionCard(
          icon: Icons.emoji_emotions,
          title: '결과',
          chips: resultChips,
          backgroundColor: const Color(0xFF95B1EE),
        ),
      ],
    );
  }

  /// 기존 섹션 카드 빌더 복제 (필요 시 DRY 개선).
  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> chips,
    required Color backgroundColor,
  }) {
    return Card(
      color: backgroundColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 4, children: chips),
          ],
        ),
      ),
    );
  }
}
