import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:dio/dio.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
// import 'package:provider/provider.dart';
// import 'package:gad_app_team/data/user_provider.dart';

import '../../widgets/custom_appbar.dart';
import '../../widgets/navigation_button.dart';
import '../../data/storage/token_storage.dart';
import '../../data/api/api_client.dart';
import '../../data/api/worry_groups_api.dart';
import '../../data/api/diaries_api.dart';
import 'abc_group_character_screen.dart';
import '../../data/apply_solve_provider.dart';
import 'package:provider/provider.dart';

class AbcGroupAddScreen extends StatefulWidget {
  final String? label;
  final String? abcId;
  final String? origin;
  final int? beforeSud;
  final String? sudId;
  final String? diary;
  final String? sessionId;

  const AbcGroupAddScreen({
    super.key,
    this.label,
    this.abcId,
    this.origin,
    this.beforeSud,
    this.sudId,
    this.diary,
    this.sessionId
  });

  @override
  State<AbcGroupAddScreen> createState() => _AbcGroupAddScreenState();
}

class _AbcGroupAddScreenState extends State<AbcGroupAddScreen> {
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final WorryGroupsApi _worryGroupsApi = WorryGroupsApi(_apiClient);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  String? _selectedGroupId;
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _worryGroupsApi.listWorryGroups(
        includeArchived: false,
      );
      if (mounted) {
        setState(() {
          _groups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ 그룹 목록 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 그룹 상세 정보는 백엔드에서 이미 집계해준
  /// diary_count / avg_sud 를 그대로 사용
  Future<Map<String, dynamic>> _loadGroupDetails(String groupId) async {
    final group = _groups.firstWhere(
          (g) => g['group_id']?.toString() == groupId,
      orElse: () => <String, dynamic>{},
    );

    if (group.isEmpty) {
      return {
        'group': <String, dynamic>{},
        'diaryCount': 0,
        'avgScore': 0.0,
      };
    }

    final diaryCountRaw = group['diary_count'];
    final avgSudRaw = group['avg_sud'];

    final diaryCount =
    diaryCountRaw is num ? diaryCountRaw.toInt() : int.tryParse('$diaryCountRaw') ?? 0;
    final avgScore =
    avgSudRaw is num ? avgSudRaw.toDouble() : double.tryParse('$avgSudRaw') ?? 0.0;

    return {
      'group': group,
      'diaryCount': diaryCount,
      'avgScore': avgScore,
    };
  }

  bool get _shouldContinueTherapyFlow =>
      (widget.origin == 'apply' || widget.origin == 'solve') &&
          widget.abcId != null;

  Future<void> _navigateAfterGroupSelection() async {
    if (!mounted) return;

    if (!_shouldContinueTherapyFlow) {
      _showStartDialog();
      return;
    }

    final flow = context.read<ApplyOrSolveFlow>()
      ..syncFromArgs({
        'origin': widget.origin,
        'abcId': widget.abcId,
        'beforeSud': widget.beforeSud,
        'sudId': widget.sudId,
        'diary': widget.diary,
      });
    flow.setOrigin(widget.origin);
    flow.setDiaryId(widget.abcId);
    if (widget.beforeSud != null) flow.setBeforeSud(widget.beforeSud);
    if (widget.sudId != null) flow.setSudId(widget.sudId);

    final args = <String, dynamic>{
      ...flow.toArgs(),
      'abcId': widget.abcId,
      if (widget.beforeSud != null) 'beforeSud': widget.beforeSud,
      if (widget.diary != null) 'diary': widget.diary,
      if (widget.origin != null) 'origin': widget.origin,
      if (widget.sudId != null) 'sudId': widget.sudId,
    };

    if (widget.origin == 'solve') {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => CustomPopupDesign(
          title: '이완 음성 안내 시작',
          message:
          '잠시 후, 이완을 위한 음성 안내가 시작됩니다.\n주변 소리와 음량을 조절해보세요.',
          positiveText: '확인',
          negativeText: null,
          backgroundAsset: null,
          iconAsset: null,
          onPositivePressed: () async {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              context,
              '/relaxation_noti',
              arguments: {
                ...args,
                'taskId': widget.abcId,
                'mp3Asset': 'noti.mp3',
                'riveAsset': 'noti.riv',
                'nextPage': '/relaxation_score',
                'diary': widget.diary,
              },
            );
          },
        ),
      );
    }

    // NOTE: 나중에 UserProvider 연결되면 currentWeek 기반으로 분기
    // final userProvider = context.read<UserProvider>();
    // final week = userProvider.currentWeek;
    final week = 8; // TODO: 임시: 항상 8주차로 이동
    if (!mounted) return;
    final route = week >= 4 ? '/relax_or_alternative' : '/relax_yes_or_no';
    Navigator.pushReplacementNamed(
      context,
      route,
      arguments: args,
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> group) {
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
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3F2FD), width: 2),
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
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FBFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3F2FD), width: 2),
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
                        try {
                          await _worryGroupsApi.updateWorryGroup(
                            group['group_id']?.toString() ?? '',
                            groupTitle: titleCtrl.text,
                            groupContents: contentsCtrl.text,
                          );
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _loadGroups();
                          }
                        } catch (e) {
                          debugPrint('❌ 그룹 수정 실패: $e');
                        }
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

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AbcGroupCharacterScreen(
              groups: _groups,
              sessionId: widget.sessionId)),
        );

        if (result == true && mounted) {
          debugPrint('🔄 그룹 추가 완료, 목록 새로고침');
          _loadGroups();
        }
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF5B9FD3).withValues(alpha: 0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B9FD3).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
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
                color: const Color(0xFF5B9FD3).withValues(alpha: 0.1),
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

  Widget _buildGroupCard({
    required Map<String, dynamic> group,
    required bool isSelected,
    required VoidCallback onTap,
  }) {

    final characterIdStr = group['character_id']?.toString() ?? '1';

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
              Color(0xFFE0F2FF),
              Color(0xFFF0F9FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: const Color(0xFF5B9FD3), width: 2.5)
              : Border.all(
            color: Colors.white.withValues(alpha: 0.9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF5B9FD3).withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 24 : 16,
              spreadRadius: isSelected ? 2 : 0,
              offset: Offset(0, isSelected ? 10 : 6),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: isSelected ? 0.6 : 0.4),
              blurRadius: 8,
              spreadRadius: -2,
              offset: const Offset(0, -2),
            ),
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF5B9FD3).withValues(alpha: 0.2),
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
                      color: isSelected
                          ? null
                          : Colors.white.withValues(alpha: 0.7),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFF5B9FD3).withValues(alpha: 0.3)
                              : Colors.black.withValues(alpha: 0.05),
                          blurRadius: isSelected ? 16 : 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/image/character$characterIdStr.png',
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      },
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: CustomAppBar(
          title: '걱정 그룹 - 추가하기',
          onBack: () {
            // TODO: 홈으로 돌아가는 게 맞나용...? 경우에 따라 알림으로 돌아가야 하는거 아니에요?
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (_) => false);
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
                        colors: [Color(0xCCFFFFFF), Color(0x88FFFFFF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _isLoading
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF5B9FD3),
                          strokeWidth: 3,
                        ),
                      )
                          : GridView.count(
                        padding: const EdgeInsets.all(16),
                        crossAxisCount: 3,
                        childAspectRatio: 0.82,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        children: [
                          _buildAddCard(),
                          for (final group in _groups)
                            Builder(
                              builder: (_) {
                                final groupIdStr =
                                    group['group_id']?.toString() ?? '';
                                final isSelected =
                                    _selectedGroupId == groupIdStr;
                                return _buildGroupCard(
                                  group: group,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(
                                          () =>
                                      _selectedGroupId = groupIdStr,
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    if (_selectedGroupId != null) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 240,
                        child: FutureBuilder<Map<String, dynamic>>(
                          future: _loadGroupDetails(_selectedGroupId!),
                          builder: (ctx, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF5B9FD3),
                                  strokeWidth: 3,
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(
                                child: Text('그룹 정보를 불러오는 중 오류가 발생했습니다.'),
                              );
                            }

                            final details = snapshot.data!;
                            final data =
                            details['group'] as Map<String, dynamic>;
                            final count = details['diaryCount'] as int;
                            final avgScore = details['avgScore'] as double;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFAFDFF),
                                    Color(0xFFFFFFFF),
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
                                    color: const Color(
                                      0xFF5B9FD3,
                                    ).withValues(alpha: 0.18),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                        onTap: () =>
                                            _showEditDialog(context, data),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF5B9FD3,
                                            ).withValues(alpha: 0.1),
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
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF6FAFF),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text(
                                                '주관적 점수',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF566370),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${avgScore.toStringAsFixed(1)}/10',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF7E57C2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF6FAFF),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              const Text(
                                                '일기',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF566370),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '$count개',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF5C6BC0),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6FAFF),
                                        borderRadius: BorderRadius.circular(12),
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
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: NavigationButtons(
              leftLabel: '이전',
              rightLabel: '다음',
              onBack: () => Navigator.pop(context),
              onNext: () async {
                if (_selectedGroupId == null || widget.abcId == null) return;

                try {
                  debugPrint(
                    '🔵 그룹 업데이트 시작: diaryId=${widget.abcId}, groupId=$_selectedGroupId',
                  );

                  // ✅ 백엔드 diaries 스키마: group_id(문자열)
                  await _diariesApi.updateDiary(widget.abcId!, {
                    'group_id': _selectedGroupId,
                  });

                  debugPrint(
                    '✅ 일기 그룹 할당 완료: diaryId=${widget.abcId}, groupId=$_selectedGroupId',
                  );
                } on DioException catch (e, stackTrace) {
                  debugPrint(
                    '❌ 일기 그룹 할당 DioException: ${e.response?.statusCode}',
                  );
                  debugPrint('Response data: ${e.response?.data}');
                  debugPrint('Request: PUT /diaries/${widget.abcId}');
                  debugPrint(
                    'Body: {group_id: $_selectedGroupId}',
                  );
                  debugPrint('Error message: ${e.message}');
                  debugPrint('Stack trace: $stackTrace');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '그룹 할당 실패: ${e.response?.data ?? e.message}',
                      ),
                    ),
                  );
                  return;
                } catch (e, stackTrace) {
                  debugPrint('❌ 일기 그룹 할당 실패: $e');
                  debugPrint('Stack trace: $stackTrace');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('그룹 할당 실패: $e')));
                  return;
                }

                if (!context.mounted) return;
                await _navigateAfterGroupSelection();
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomPopupDesign(
        title: '이완 음성 안내 시작',
        message:
        '잠시 후, 이완을 위한 음성 안내가 시작됩니다.\n주변 소리와 음량을 조절해보세요.',
        positiveText: '확인',
        negativeText: null,
        backgroundAsset: null,
        iconAsset: null,
        onPositivePressed: () async {
          Navigator.pop(context);
          Navigator.pushReplacementNamed(
            context,
            '/relaxation_education',
            arguments: {
              'sessionId': widget.sessionId,
              'taskId': 'week2_education',
              'weekNumber': 2,
              'mp3Asset': 'week2.mp3',
              'riveAsset': 'week2.riv',
            },
          );
        },
      ),
    );
  }
}
