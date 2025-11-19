import 'package:flutter/material.dart';
import 'package:gad_app_team/contents/before_sud_screen.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';

class DiarySelectScreen extends StatefulWidget {
  const DiarySelectScreen({super.key});

  @override
  State<DiarySelectScreen> createState() => _DiarySelectScreenState();
}

class _DiarySelectScreenState extends State<DiarySelectScreen> {
  final Set<String> _selectedIds = {};
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  Future<List<Map<String, dynamic>>> _loadFilteredDiaries(int groupId) async {
    final diaries = await _diariesApi.listDiaries(groupId: groupId);
    final filtered = <Map<String, dynamic>>[];
    for (final diary in diaries) {
      final sudScores = diary['sudScores'] as List<dynamic>? ?? const [];
      final latest = _latestSud(sudScores);
      final after = latest?['after_sud'] as num?;
      if (after == null || after > 2) {
        filtered.add(diary);
      }
    }
    return filtered;
  }

  Map<String, dynamic>? _latestSud(List<dynamic> scores) {
    if (scores.isEmpty) return null;
    scores.sort((a, b) {
      final da = DateTime.tryParse(
            (a as Map)['updated_at']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(
            (b as Map)['updated_at']?.toString() ?? '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return scores.first as Map<String, dynamic>?;
  }

  String _buildBelief(dynamic raw) {
    if (raw is List) {
      return raw.whereType<String>().join(', ');
    }
    return raw?.toString() ?? '';
  }

  String _buildConsequence(Map<String, dynamic> diary) {
    final pieces = <String>[];
    for (final key in ['consequence_p', 'consequence_e', 'consequence_b']) {
      final value = diary[key];
      if (value is List) {
        pieces.addAll(value.whereType<String>());
      } else if (value is String && value.trim().isNotEmpty) {
        pieces.add(value.trim());
      }
    }
    return pieces.join(', ');
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

    final groupIdInt =
        groupId == null ? null : int.tryParse(groupId.toString());
    if (groupIdInt == null) {
      return const Scaffold(
        body: Center(child: Text('그룹 정보를 찾을 수 없습니다.')),
      );
    }

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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadFilteredDiaries(groupIdInt),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      '일기를 불러오지 못했습니다.\n${snap.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }
              final docs = snap.data ?? const [];
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
                  final diary = docs[index];
                  final diaryId = diary['diaryId']?.toString() ?? '';
                  final title =
                      diary['activating_events']?.toString().trim() ??
                      '(제목 없음)';
                  final belief = _buildBelief(diary['belief']);
                  final consequence = _buildConsequence(diary);
                  final isSelected = _selectedIds.contains(diaryId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                          if (diaryId.isNotEmpty) {
                            _selectedIds.add(diaryId);
                          }
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                  if (belief.isNotEmpty)
                                    Text(
                                      '생각: $belief',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        fontFamily: 'Noto Sans KR',
                                      ),
                                    ),
                                  if (consequence.isNotEmpty)
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
