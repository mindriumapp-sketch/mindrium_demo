import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';

/// 💡 Mindrium 스타일: 비슷한 상황 확인 화면
/// 앞쪽은 InnerBtnCardScreen 구조로 감싸고,
/// 내부는 상황-생각-결과 3단을 부드러운 블루·민트 톤 카드로 시각화.
class SimilarActivationScreen extends StatelessWidget {
  const SimilarActivationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId = args['abcId'] as String?;
    final String? groupId = args['groupId'] as String?;
    final int? sud = args['sud'] as int?;
    debugPrint('[SimilarActivation] abcId=$abcId, groupId=$groupId');

    final tokens = TokenStorage();
    final apiClient = ApiClient(tokens: tokens);
    final diariesApi = DiariesApi(apiClient);
    final userDataApi = UserDataApi(apiClient);

    return InnerBtnCardScreen(
      appBarTitle: '비슷한 상황 확인',
      title: '이 일기와 비슷한 상황인가요?',
      primaryText: '네',
      secondaryText: '아니오',
      onPrimary: () async {
        final access = await tokens.access;
        if (access == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
          }
          return;
        }

        int completedWeeks = 8; //TODO: 임시 8주차 완료 처리
        try {
          final progress = await userDataApi.getProgress();
          final weekProgress = progress['week_progress'];
          if (weekProgress is List) {
            for (final item in weekProgress) {
              if (item is Map && item['completed'] == true) {
                completedWeeks++;
              }
            }
          }
        } catch (e) {
          debugPrint('❌ 진행도 정보 조회 실패: $e');
        }

        if (!context.mounted) return;
        final route =
            completedWeeks >= 4 ? '/relax_or_alternative' : '/relax_yes_or_no';
        Navigator.pushNamed(
          context,
          route,
          arguments: {'abcId': abcId, 'sud': sud},
        );
      },
      onSecondary: () {
        Navigator.pushNamed(
          context,
          '/diary_yes_or_no',
          arguments: {'origin': 'apply'},
        );
      },
      child: abcId == null || abcId.isEmpty
          ? const Center(child: Text('일기 정보를 찾을 수 없습니다.'))
          : FutureBuilder<Map<String, dynamic>>(
        future: diariesApi.getDiary(abcId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                '일기 데이터를 불러오지 못했습니다.\n${snap.error}',
                textAlign: TextAlign.center,
              ),
            );
          }
          final data = snap.data;
          if (data == null) {
            return const Center(child: Text('일기 데이터를 찾을 수 없습니다.'));
          }

          final activatingEvent =
              (data['activating_events'] ?? data['activatingEvent'] ?? '')
                  .toString()
                  .trim();
          final beliefValue = data['belief'];
          final belief =
              beliefValue is List
                  ? beliefValue
                      .whereType<String>()
                      .where((e) => e.trim().isNotEmpty)
                      .join(', ')
                  : (beliefValue ?? '').toString().trim();
          final consequences = [
            data['consequence_p'],
            data['consequence_e'],
            data['consequence_b'],
          ]
              .whereType<List>()
              .expand((list) => list)
              .whereType<String>()
              .toList();
          final consequence =
              consequences.isNotEmpty
                  ? consequences.join(', ')
                  : (data['consequence'] ?? '').toString().trim();

          return SimilarActivationVisualizer(
            activatingEvent: activatingEvent,
            belief: belief,
            consequence: consequence,
          );
        },
      ),
    );
  }
}

/// 🎨 Mindrium 스타일 상황-생각-결과 시각화 위젯
class SimilarActivationVisualizer extends StatelessWidget {
  final String activatingEvent;
  final String belief;
  final String consequence;

  const SimilarActivationVisualizer({
    super.key,
    required this.activatingEvent,
    required this.belief,
    required this.consequence,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCardSection(
          title: '상황',
          icon: Icons.event_note,
          content: activatingEvent,
          gradient: const LinearGradient(
            colors: [Color(0xFFB4E0FF), Color(0xFFDDF3FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        const Icon(
          Icons.keyboard_double_arrow_down_rounded,
          color: Color(0xFF2F6EBA),
          size: 36,
        ),
        _buildCardSection(
          title: '생각',
          icon: Icons.psychology_alt,
          content: belief,
          gradient: const LinearGradient(
            colors: [Color(0xFFAEC8FF), Color(0xFFD6E2FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        const Icon(
          Icons.keyboard_double_arrow_down_rounded,
          color: Color(0xFF2F6EBA),
          size: 36,
        ),
        _buildCardSection(
          title: '결과',
          icon: Icons.emoji_emotions,
          content: consequence,
          gradient: const LinearGradient(
            colors: [Color(0xFFBDE6F4), Color(0xFFD8F8E4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ],
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required String content,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2F6EBA), size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Noto Sans KR',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF1F3D63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content.isNotEmpty ? content : '내용이 없습니다.',
              style: const TextStyle(
                fontFamily: 'Noto Sans KR',
                fontSize: 14.5,
                height: 1.5,
                color: Color(0xFF232323),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
