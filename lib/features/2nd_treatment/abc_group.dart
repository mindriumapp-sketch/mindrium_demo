import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/worry_groups_api.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'abc_group_add_screen.dart';
import '../menu/archive/character_battle.dart';
import 'package:gad_app_team/features/menu/menu_screen.dart'; // 또는 실제 경로
import 'package:gad_app_team/navigation/screen/home_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AbcGroupScreen extends StatefulWidget {
  final String? label;
  final String? abcId;
  final String? origin;
  const AbcGroupScreen({super.key, this.label, this.abcId, this.origin});

  @override
  State<AbcGroupScreen> createState() => _AbcGroupScreenState();
}

class _AbcGroupScreenState extends State<AbcGroupScreen> {
  /// 현재 펼쳐진 카드 인덱스 (-1 = 모두 접힘)
  int _selectedIndex = -1;

  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final WorryGroupsApi _worryGroupsApi = WorryGroupsApi(_apiClient);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  List<Map<String, dynamic>> _groups = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadGroups);
  }

  Future<void> _loadGroups() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final groups = await _worryGroupsApi.listWorryGroups();
      print('🔍 API 응답 받은 그룹 수: ${groups.length}');
      for (var g in groups) {
        print(
          '   - group_id: ${g['group_id']}, title: ${g['group_title']}, archived: ${g['archived']}',
        );
      }
      if (!mounted) return;
      setState(() {
        _groups = groups;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            e.response?.data is Map
                ? e.response?.data['detail']?.toString()
                : e.message ?? '알 수 없는 오류가 발생했습니다.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '걱정 그룹을 불러오지 못했습니다: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> group) {
    final titleCtrl = TextEditingController(text: group['group_title'] ?? '');
    final contentsCtrl = TextEditingController(
      text: group['group_contents'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              24,
              24,
              24,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 상단 핸들바
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text(
                    '그룹 편집',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF0E2C48),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 제목 입력
                  const Text(
                    '제목',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0E2C48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '그룹 제목을 입력하세요',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8FBFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3F2FD),
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3F2FD),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B9FD3),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 설명 입력
                  const Text(
                    '설명',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0E2C48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentsCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '그룹 설명을 입력하세요',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8FBFF),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3F2FD),
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3F2FD),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF5B9FD3),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 버튼
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await _worryGroupsApi.updateWorryGroup(
                          group['group_id']?.toString() ?? '',
                          {
                            'group_title': titleCtrl.text,
                            'group_contents': contentsCtrl.text,
                          },
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _loadGroups();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7BB8E8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: const Color(0xFF7BB8E8).withOpacity(0.4),
                    ),
                    child: const Text(
                      '수정 완료',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AbcGroupAddScreen1(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF5B9FD3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF5B9FD3),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                '그룹 추가',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF0E2C48),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 드롭다운(펼침) 내용 위젯: 일기 개수/설명 전체/생성일/버튼들
  Widget _ExpandedGroupBody({
    required String groupId,
    required String fullContents,
    required DateTime? createdAt,
    required String groupTitle,
  }) {
    final createdStr =
        (createdAt == null)
            ? '-'
            : '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _diariesApi.listDiaries(groupId: int.tryParse(groupId)),
        builder: (context, diariesSnap) {
          if (diariesSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFF5B9FD3)),
              ),
            );
          }

          final diaries = diariesSnap.data ?? [];

          return FutureBuilder<double?>(
            future: _avgAfterSudFromDiaries(diaries),
            builder: (context, avgSnap) {
              final hasScore = avgSnap.data != null;
              final avg = (avgSnap.data ?? 0).clamp(0, 10);
              final ratio = hasScore ? avg / 10.0 : 0.0;

              final barColor =
                  Color.lerp(
                    const Color(0xFF4CAF50),
                    const Color(0xFFF44336),
                    ratio,
                  )!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주관적 불안점수 섹션
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: barColor.withOpacity(0.3),
                        width: 2.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              '주관적 불안점수',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1B405C),
                                letterSpacing: -0.2,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: barColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: barColor.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${avg.toStringAsFixed(1)} / 10',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: barColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            minHeight: 10,
                            value: hasScore ? ratio : 0.0,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation(barColor),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '※ 2점 이하 시 삭제 가능',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 생성일 / 일기 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 생성일 (한 줄로 표시)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '생성일 $createdStr',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0E2C48),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      // 일기 버튼
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/diary_directory',
                            arguments: {'groupId': int.tryParse(groupId)},
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '일기 ${diaries.length}개',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF417CAF),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: Color(0xFF417CAF),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 불안 삭제 버튼 (기본 그룹(id=1)은 제외, 평균 ≤ 2.0일 때만 활성)
                  if (groupId != '1')
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              hasScore && avg <= 2.0
                                  ? const Color(0xFFF44336)
                                  : Colors.grey.shade300,
                          foregroundColor:
                              hasScore && avg <= 2.0
                                  ? Colors.white
                                  : Colors.grey.shade500,
                          elevation: hasScore && avg <= 2.0 ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: Icon(
                          hasScore && avg <= 2.0
                              ? Icons.delete_outline
                              : Icons.lock_outline,
                          size: 22,
                        ),
                        label: const Text(
                          '불안 삭제',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        onPressed:
                            hasScore && avg <= 2.0
                                ? () {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder:
                                        (ctx) => Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '정말 "$groupTitle" 그룹을\n삭제하시겠습니까?',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF0E2C48),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  '삭제된 그룹은 보관함에서 확인 가능합니다.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF1B405C),
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              ctx,
                                                            ),
                                                        style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 12,
                                                              ),
                                                          side:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFF5B9FD3,
                                                                ),
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          '취소',
                                                          style: TextStyle(
                                                            color: Color(
                                                              0xFF5B9FD3,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.pop(ctx);
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (
                                                                    _,
                                                                  ) => PokemonBattleDeletePage(
                                                                    groupId:
                                                                        groupId,
                                                                    onGoArchive: () {
                                                                      Navigator.pushAndRemoveUntil(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder:
                                                                              (_) => const HomeScreen(
                                                                                initialIndex:
                                                                                    2,
                                                                              ),
                                                                        ),
                                                                        (_) =>
                                                                            false,
                                                                      );
                                                                    },
                                                                  ),
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 12,
                                                              ),
                                                          backgroundColor:
                                                              const Color(
                                                                0xFFF44336,
                                                              ),
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                        child: const Text(
                                                          '삭제',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                  );
                                }
                                : null,
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> data, int i) {
    final groupId = (data['group_id'] ?? '').toString();
    final title = (data['group_title'] ?? '제목 없음').toString();
    final contents = (data['group_contents'] ?? '').toString();
    final createdAtRaw = data['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else if (createdAtRaw is String) {
      try {
        createdAt = DateTime.parse(createdAtRaw);
      } catch (_) {}
    }

    final selected = _selectedIndex == i;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = selected ? -1 : i;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F4FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF5B9FD3) : const Color(0xFFE3F2FD),
            width: selected ? 2.5 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  selected
                      ? const Color(0xFF5B9FD3).withOpacity(0.25)
                      : Colors.black.withOpacity(0.05),
              blurRadius: selected ? 12 : 8,
              offset: Offset(0, selected ? 6 : 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            childrenPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFB8DAF5),
              backgroundImage: AssetImage('assets/image/character$groupId.png'),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: const Color(0xFF0E2C48),
                fontSize: 16,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            subtitle:
                contents.isNotEmpty
                    ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        contents,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1B405C),
                          fontSize: 13,
                        ),
                      ),
                    )
                    : null,
            trailing: IconButton(
              icon: const Icon(
                Icons.more_vert,
                color: Color(0xFF5B9FD3),
                size: 24,
              ),
              onPressed: () => _showEditDialog(context, data),
            ),
            children: [
              _ExpandedGroupBody(
                groupId: groupId,
                fullContents: contents,
                createdAt: createdAt,
                groupTitle: title,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5B9FD3)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _loadGroups, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_groups.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadGroups,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildAddCard(),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3F2FD)),
              ),
              child: const Text(
                '등록된 걱정 그룹이 없습니다.\n상단 버튼에서 새 그룹을 추가할 수 있습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1B405C),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _groups.length + 1,
        itemBuilder: (ctx, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _buildAddCard(),
            );
          }
          return _buildGroupCard(_groups[i - 1], i - 1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '걱정 그룹 관리',
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
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/image/eduhome.png', fit: BoxFit.cover),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xAAFFFFFF), Color(0x66FFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(child: _buildGroupList()),
        ],
      ),
    );
  }

  Future<double?> _avgAfterSudFromDiaries(
    List<Map<String, dynamic>> diaries,
  ) async {
    if (diaries.isEmpty) {
      print('📊 SUD 계산: 일기 없음');
      return null;
    }

    print('📊 SUD 계산 시작: ${diaries.length}개 일기');
    int sum = 0, cnt = 0;

    for (final diary in diaries) {
      final sudScores = diary['sudScores'] as List?;
      print('  일기 ${diary['diaryId']}: sudScores = $sudScores');

      if (sudScores == null || sudScores.isEmpty) {
        print('    ❌ sudScores 없음');
        continue;
      }

      // Sort by created_at to get the latest score
      final scores = List<Map<String, dynamic>>.from(
        sudScores.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      );
      scores.sort((a, b) {
        final aDate = _parseDate(a['created_at']);
        final bDate = _parseDate(b['created_at']);
        return aDate.compareTo(bDate);
      });

      if (scores.isEmpty) continue;
      final latestScore = scores.last;
      final afterSud = latestScore['after_sud'];
      print('    최신 after_sud: $afterSud (타입: ${afterSud.runtimeType})');

      int? afterValue;
      if (afterSud is int) {
        afterValue = afterSud;
      } else if (afterSud is num) {
        afterValue = afterSud.toInt();
      } else if (afterSud is String) {
        afterValue = int.tryParse(afterSud);
      }

      if (afterValue != null) {
        sum += afterValue.clamp(0, 10);
        cnt++;
        print('    ✅ 점수: $afterValue');
      } else {
        print('    ❌ 점수 파싱 실패');
      }
    }

    if (cnt == 0) {
      print('📊 결과: 점수 없음 (0개 처리됨)');
      return null;
    }

    final avg = sum / cnt;
    print('📊 결과: 평균 ${avg.toStringAsFixed(1)} (총 $cnt개)');
    return avg;
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value.toUtc();
    if (value is String) {
      try {
        return DateTime.parse(value).toUtc();
      } catch (_) {}
    }
    return DateTime.now().toUtc();
  }
}
