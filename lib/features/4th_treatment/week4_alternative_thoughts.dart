import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 공용 레이아웃 & 칩 에디터
import 'package:gad_app_team/widgets/top_btm_card.dart';
import 'package:gad_app_team/widgets/chips_editor.dart';

// 다음 화면 (기존 로직 유지)
import 'week4_alternative_thoughts_display_screen.dart';

class Week4AlternativeThoughtsScreen extends StatefulWidget {
  final List<String> previousChips;
  final int? beforeSud;
  final List<String> remainingBList;
  final List<String> allBList;
  final List<String>? existingAlternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String> originalBList;
  final String? abcId;
  final int loopCount;

  const Week4AlternativeThoughtsScreen({
    super.key,
    required this.previousChips,
    this.beforeSud,
    required this.remainingBList,
    required this.allBList,
    this.existingAlternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.originalBList = const [],
    this.abcId,
    this.loopCount = 1,
  });

  @override
  State<Week4AlternativeThoughtsScreen> createState() =>
      _Week4AlternativeThoughtsScreenState();
}

class _Week4AlternativeThoughtsScreenState
    extends State<Week4AlternativeThoughtsScreen> {
  // ▶ 칩 에디터 상태 & 값
  final _chipsKey = GlobalKey<ChipsEditorState>();
  List<String> _chips = [];

  @override
  void initState() {
    super.initState();
    // 화면에는 현재 작성 중(새로 입력) 대체생각만 보여주고 저장 시 합쳐서 저장
  }

  // ───────────────────── Firebase 저장 (기존 로직 유지) ─────────────────────
  Future<void> _saveAlternativeThoughtsToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('❌ 저장 실패: 사용자가 로그인하지 않았습니다.');
        return;
      }

      final current = _chipsKey.currentState?.values ?? _chips;
      debugPrint('✅ 저장 시작 - User ID: ${user.uid}');
      debugPrint('✅ 현재 chips: $current');
      debugPrint('✅ 기존 thoughts: ${widget.existingAlternativeThoughts}');

      final allAlternativeThoughts = [
        ...?widget.existingAlternativeThoughts,
        ...current,
      ];
      debugPrint('✅ 저장할 전체 thoughts: $allAlternativeThoughts');

      String targetAbcId;

      if (widget.abcId == null || widget.abcId!.isEmpty) {
        debugPrint('⚠️ abcId가 없습니다. 최신 ABC 모델을 찾습니다...');
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('abc_models')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          debugPrint('❌ ABC 모델이 없습니다. 저장을 중단합니다.');
          return;
        }
        targetAbcId = snapshot.docs.first.id;
        debugPrint('✅ 최신 ABC 모델을 찾았습니다: $targetAbcId');
      } else {
        targetAbcId = widget.abcId!;
        debugPrint('✅ 전달받은 ABC ID 사용: $targetAbcId');
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .doc(targetAbcId)
          .set({
        'alternative_thoughts': allAlternativeThoughts,
        'week4_completed': true,
        'week4_completed_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ 도움이 되는 생각이 Firebase에 저장되었습니다!');
      debugPrint('   경로: users/${user.uid}/abc_models/$targetAbcId');
    } catch (e, st) {
      debugPrint('❌ Firebase 저장 오류: $e');
      debugPrint('❌ Stack trace: $st');
    }
  }

  // 칩 변경 콜백
  void _onChipsChanged(List<String> v) {
    setState(() => _chips = v);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[alt_thought] abcId: ${widget.abcId}');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ApplyDoubleCard(
        appBarTitle: '4주차 - 인지 왜곡 찾기',

        // ◀◀ 뒤로/다음 (기존 로직 유지)
        onBack: () => Navigator.pop(context),
        onNext: _chips.isNotEmpty
            ? () async {
          // 저장
          await _saveAlternativeThoughtsToFirebase();

          // 항상 현재 B(생각)을 명확히 전달
          final bToShow = widget.previousChips.isNotEmpty
              ? widget.previousChips.last
              : (widget.remainingBList.isNotEmpty
              ? widget.remainingBList.first
              : '');

          if (widget.abcId != null && widget.abcId!.isNotEmpty) {
            final routeArgs =
                ModalRoute.of(context)?.settings.arguments as Map? ?? {};
            final origin = (routeArgs['origin'] as String?) ?? 'etc';
            final diary = routeArgs['diary'];
            debugPrint('[alt_thought] origin=$origin, diary=$diary');

            Navigator.pushNamed(
              context,
              '/alt_thought',
              arguments: {
                'abcId': widget.abcId,
                'origin': origin,
                if (diary != null) 'diary': diary,
                'loopCount': widget.loopCount,
              },
            );
          } else {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) =>
                    Week4AlternativeThoughtsDisplayScreen(
                      alternativeThoughts:
                      _chipsKey.currentState?.values ?? _chips,
                      previousB: bToShow,
                      beforeSud: widget.beforeSud ?? 0,
                      remainingBList: widget.remainingBList,
                      allBList: widget.allBList,
                      existingAlternativeThoughts:
                      widget.existingAlternativeThoughts,
                      isFromAnxietyScreen: widget.isFromAnxietyScreen,
                      originalBList: widget.originalBList,
                      abcId: widget.abcId,
                      loopCount: widget.loopCount,
                    ),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        }
            : null,

        // 레이아웃 옵션 (이전 화면과 동일 톤)
        pagePadding: const EdgeInsets.symmetric(horizontal: 34, vertical: 12),
        panelsGap: 2,
        panelRadius: 20,
        panelPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),

        // ─────────────────── 상단 패널 (제목 + 이미지) ───────────────────
        // ─────────────────── 상단 패널 (제목 + 이미지 꽉 채우기) ───────────────────
        topChild: LayoutBuilder(
          builder: (context, c) {
            // 패널 내부 유효 폭(WhitePanel padding 고려 후의 실제 폭)이 들어와요
            final double panelWidth = c.maxWidth;
            // 폭 기준으로 적당한 높이 산정 (상단 고정, 좌우/아래로 채워지는 느낌)
            final double imgHeight = (panelWidth * 0.62).clamp(180.0, 320.0).toDouble();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text(
                  '도움이 되는 생각을 찾아보는 시간',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ✅ 가로는 꽉, 높이는 여유 있게 / 상단 기준으로 크롭
                Container(
                  width: double.infinity,
                  height: imgHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/image/alternative thoughts.png',
                    fit: BoxFit.cover,                 // 화면을 가득 채움(양옆/아래 잘림 허용)
                    alignment: Alignment.topCenter,    // 🔹 상단을 기준으로 고정
                  ),
                ),
              ],
            );
          },
        ),

        // 패널 사이 말풍선
        middleBannerText: '입력 영역을 탭하면 항목이 추가돼요!\n엔터 또는 바깥 터치로 확정됩니다',
        // height: 120,
        // topPadding: 20,

        // ─────────────────── 하단 패널 (칩 입력) ───────────────────
        bottomChild: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChipsEditor(
              key: _chipsKey,
              initial: const [],      // 초기 칩이 있다면 전달
              onChanged: _onChipsChanged,
              minHeight: 150,
              maxWidthFactor: 0.78,
              // 빈 상태 UI 문구를 이 화면에 맞게
              emptyText: const Text(
                '여기에 입력한 내용이 표시됩니다',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),

        // 하단 패널 배경 톤
        btmcardColor: const Color(0xFF7DD9E8).withOpacity(0.35),
      ),
    );
  }
}
