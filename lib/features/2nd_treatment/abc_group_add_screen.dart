import 'package:flutter/material.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_popup_design.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/worry_groups_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class AbcGroupAddScreen1 extends StatefulWidget {
  final String? abcId;

  const AbcGroupAddScreen1({super.key, this.abcId});

  @override
  State<AbcGroupAddScreen1> createState() => _AbcGroupAddScreen1State();
}

class _AbcGroupAddScreen1State extends State<AbcGroupAddScreen1> {
  int? _selectedCharacterIndex;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ApiClient _apiClient;
  late final WorryGroupsApi _worryGroupsApi;

  List<Map<String, dynamic>> availableCharacters = [];
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    final tokens = TokenStorage();
    _apiClient = ApiClient(tokens: tokens);
    _worryGroupsApi = WorryGroupsApi(_apiClient);
    _loadAvailableCharacters();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      // 2행 그리드에서 한 페이지당 2개 열
      final pageWidth = 110.0 + 12.0; // 카드 너비 + 간격
      setState(() {
        _currentPage = _scrollController.offset / pageWidth;
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableCharacters() async {
    try {
      // 기존 그룹 조회 (보관된 것 포함)
      final groups = await _worryGroupsApi.listWorryGroups(
        includeArchived: true,
      );

      // character_id 또는 group_id를 사용해서 이미 사용된 캐릭터 확인
      final usedCharacterIds =
          groups.map((group) {
            // character_id가 있으면 그것을 사용, 없으면 group_id 사용
            final charId = group['character_id'] ?? group['group_id'];
            return int.tryParse(charId?.toString() ?? '') ?? -1;
          }).toSet();

      debugPrint('🔍 사용된 캐릭터 IDs: $usedCharacterIds');

      final allCharacters = List.generate(
        20,
        (index) => {
          'id': index + 1,
          'name': '캐릭터 ${index + 1}',
          'image': 'assets/image/character${index + 1}.png',
        },
      );

      setState(() {
        availableCharacters =
            allCharacters
                .where((char) => !usedCharacterIds.contains(char['id']))
                .toList();
      });

      debugPrint('✅ 사용 가능한 캐릭터: ${availableCharacters.length}개');
    } catch (e) {
      debugPrint('❌ 캐릭터 목록 로드 실패: $e');
    }
  }

  Widget _buildPageIndicator() {
    if (availableCharacters.isEmpty) return const SizedBox.shrink();

    // 2행 그리드에서 페이지 수 계산 (한 페이지에 2개 열 = 4개 캐릭터)
    final totalPages = (availableCharacters.length / 4).ceil();
    final currentPageIndex = _currentPage.round().clamp(0, totalPages - 1);

    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalPages, (index) {
          final isActive = index == currentPageIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color:
                  isActive ? const Color(0xFF5B9FD3) : const Color(0xFFB0BEC5),
              borderRadius: BorderRadius.circular(4),
                      boxShadow:
                          isActive
                              ? [
                                BoxShadow(
                                  color: const Color(0xFF5B9FD3)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
            ),
          );
        }),
      ),
    );
  }

  Future<void> _addGroupToFirebase() async {
    if (_selectedCharacterIndex == null ||
        titleController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('모든 필드를 입력하세요.'),
          backgroundColor: const Color(0xFFE53B3B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    final selectedCharacter = availableCharacters[_selectedCharacterIndex!];

    try {
      await _worryGroupsApi.createWorryGroup(
        groupId: selectedCharacter['id'].toString(),
        groupTitle: titleController.text,
        groupContents: descriptionController.text,
        characterId: selectedCharacter['id'],
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (ctx) => CustomPopupDesign(
                title: '그룹 추가 완료',
                message: '그룹이 성공적으로 추가되었습니다!',
                positiveText: '확인',
                onPositivePressed: () async {
                  Navigator.pop(ctx); // 다이얼로그 닫기
                  Navigator.pop(context, true); // 이전 화면(그룹 선택)으로 돌아가며 true 반환
                },
              ),
        );
      }
    } catch (e) {
      debugPrint('❌ 그룹 추가 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFFE53B3B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '그룹 추가',
        showHome: false,
        confirmOnBack: false,
        onBack: () async {
          final navigator = Navigator.of(context);
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (dialogCtx) => CustomPopupDesign(
                  title: '그룹 추가 취소',
                  message: '작성 중인 내용이 저장되지 않습니다.\n정말 나가시겠습니까?',
                  positiveText: '나가기',
                  negativeText: '취소',
                  onPositivePressed: () => Navigator.pop(dialogCtx, true),
                  onNegativePressed: () => Navigator.pop(dialogCtx, false),
                ),
          );

          if (!mounted) return;
          if (shouldExit == true) {
            navigator.pop();
          }
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌊 배경
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

          /// 📝 컨텐츠
          SafeArea(
            child:
                availableCharacters.isEmpty
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5B9FD3),
                      ),
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 캐릭터 선택 섹션
                          const Text(
                            '캐릭터 선택',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF0E2C48),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '걱정 그룹을 대표할 캐릭터를 선택해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF546E7A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 260,
                            child: GridView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 0.82,
                                  ),
                              itemCount: availableCharacters.length,
                              itemBuilder: (context, index) {
                                final character = availableCharacters[index];
                                final isSelected =
                                    _selectedCharacterIndex == index;
                                return GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => _selectedCharacterIndex = index,
                                      ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFFF8FBFF)
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? const Color(0xFF90CAF9)
                                                : const Color(0xFFE3F2FD),
                                        width: isSelected ? 2.2 : 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              isSelected
                                                  ? const Color(
                                                    0xFF90CAF9,
                                                  ).withValues(alpha: 0.25)
                                                  : Colors.black
                                                      .withValues(alpha: 0.04),
                                          blurRadius: isSelected ? 10 : 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 78,
                                          height: 78,
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFE3F2FD,
                                            ).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Image.asset(
                                              character['image'],
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        // 🚨 캐릭터 넘버링 텍스트 위젯 제거
                                        // const SizedBox(height: 8),
                                        // Text(
                                        //   '${character['id']}',
                                        //   textAlign: TextAlign.center,
                                        //   style: TextStyle(
                                        //     fontWeight: FontWeight.w700,
                                        //     fontSize: 13,
                                        //     color: isSelected
                                        //         ? const Color(0xFF5B9FD3)
                                        //         : const Color(0xFF455A64),
                                        //   ),
                                        // ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 13),
                          Center(child: _buildPageIndicator()),
                          const SizedBox(height: 22),

                          // 그룹 제목 섹션
                          const Text(
                            '그룹 제목',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0E2C48),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              hintText: '그룹 제목을 입력하세요',
                              hintStyle: const TextStyle(
                                color: Color(0xFFB0BEC5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3F2FD),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3F2FD),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5B9FD3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 그룹 설명 섹션
                          const Text(
                            '그룹 설명',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0E2C48),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: '그룹 설명을 입력하세요',
                              hintStyle: const TextStyle(
                                color: Color(0xFFB0BEC5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3F2FD),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE3F2FD),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF5B9FD3),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 추가 버튼
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7BB8E8),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadowColor: const Color(
                                  0xFF7BB8E8,
                                ).withValues(alpha: 0.4),
                              ),
                              onPressed: _addGroupToFirebase,
                              child: const Text(
                                '그룹 추가',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
