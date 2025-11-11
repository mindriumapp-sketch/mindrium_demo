// ─────────────────────────  FLUTTER  ─────────────────────────
import 'package:flutter/material.dart';

// ────────────────────────  PACKAGES  ────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ───────────────────────────  LOCAL  ────────────────────────
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
// import 'package:gad_app_team/features/4th_treatment/week4_visual_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_skip_choice_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';

/// SUD(0~10)를 입력받아 [onSubmit] 콜백으로 전달하는 화면
class AfterSudRatingScreen extends StatefulWidget {

  const AfterSudRatingScreen({
    super.key,
  });

  @override
  State<AfterSudRatingScreen> createState() => _AfterSudRatingScreenState();
}

class _AfterSudRatingScreenState extends State<AfterSudRatingScreen> {
  int _sud = 0; // 초기값

  Map _routeArgs() => ModalRoute.of(context)?.settings.arguments as Map? ?? {};
  String? get _abcId => _routeArgs()['abcId'] as String?;
  String? get _origin => _routeArgs()['origin'] as String?;
  dynamic get _diary => _routeArgs()['diary'];

  Future<void> _saveSud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final String? abcId = _abcId;

    if (uid == null || abcId == null || abcId.isEmpty) return; // 로그인/abcId 없으면 패스

    final abcRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(abcId);

    final sudCol = abcRef.collection('sud_score');

    // 업데이트할 페이로드
    final payload = <String, dynamic>{
      'after_sud': _sud,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // 1) 가장 최근 문서( updatedAt desc ) 1건 조회
    final latestSnap = await sudCol
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .get();

    if (latestSnap.docs.isNotEmpty) {
      // 2) 존재하면 해당 문서에 업데이트
      await latestSnap.docs.first.reference.update(payload);
    } else {
      // 3) 없다면 신규 문서 생성(add)
      await sudCol.add(payload);
    }
  }

  /// abc_models의 before_sud와 after_sud(현재 입력값)를 비교하여 분기 이동한다.
  Future<void> _compareAndNavigate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final String? abcId = _abcId;
    final String? origin = _origin;
    final dynamic diary = _diary;

    debugPrint('[after_sud] diary: $diary');
    // 적용하기 플로우: diary가 'new'면 알림 설정으로, 아니면 홈으로
    if (origin == 'apply') {
      if (!mounted) return;
      if (diary == 'new') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            settings: RouteSettings(arguments: {'diary': diary}),
            builder: (_) => NotificationSelectionScreen(
              origin: 'apply',
              abcId: abcId,
            ),
          ),
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
      return;
    }

    // 추가 인자 (없으면 안전한 기본값)
    // final List<String> originalBList =
    //     (args['originalBList'] as List?)?.cast<String>() ?? const [];
    final List<String> allBList =
        (_routeArgs()['allBList'] as List?)?.cast<String>() ?? const [];
    final List<String> remainingBList =
        (_routeArgs()['remainingBList'] as List?)?.cast<String>() ?? const [];
    final List<String> allAlternativeThoughts =
        (_routeArgs()['allAlternativeThoughts'] as List?)?.cast<String>() ?? const [];

    if (abcId == null || abcId.isEmpty) {
      // abcId가 없으면 기존 로직 유지: 홈으로 복귀 (또는 필요한 기본 플로우)
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    final sudCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(abcId)
        .collection('sud_score');

    // 최신(updatedAt desc) 1건 조회
    final latest = await sudCol.orderBy('updatedAt', descending: true).limit(1).get();
    final data = latest.docs.first.data();
    final beforeSud = (data['before_sud'] ?? 0) as num;
    final afterSud  = (data['after_sud']  ?? _sud) as num;

    // 이전 B 리스트 + 이번 allBList의 중복 제거 머지
    // final mergedPrevChips = <String>{...originalBList, ...allBList}.toList();

    if (!mounted) return;

    if (afterSud < beforeSud) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      // 감소 X: Week4SkipChoiceScreen으로 이동
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => Week4SkipChoiceScreen(
            allBList: allBList,
            beforeSud: beforeSud.toInt(),
            remainingBList: remainingBList,
            isFromAfterSud: true,
            existingAlternativeThoughts: allAlternativeThoughts,
            abcId: abcId,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final Color trackColor = _sud <= 2 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'SUD 평가 (after)',
      ),
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.padding, vertical: 8),
          child: NavigationButtons(
            onBack: () => Navigator.pop(context),
            onNext: () async {
              await _saveSud();
              if (!context.mounted) return;
              await _compareAndNavigate();
            },
            rightLabel: '저장',
            leftLabel: '이전',
          ),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '대체 생각 작성 이후, 느껴지는 불안 정도를 슬라이드로 선택해 주세요.',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 32),

                // 현재 선택 점수를 크게 표시
                Center(
                  child: Text(
                    '$_sud',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: trackColor
                    ),
                  ),
                ),

                // ── 큰 이모티콘 ──
                Icon(
                  _sud <= 2 ? Icons.sentiment_satisfied : Icons.sentiment_very_dissatisfied_sharp,
                  size: 160,
                  color: trackColor,
                ),

                const SizedBox(height: 32),

                // ── 슬라이더 ──
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: trackColor,
                        thumbColor: trackColor,
                      ),
                      child: Slider(
                        value: _sud.toDouble(),
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: '$_sud',
                        onChanged: (v) => setState(() => _sud = v.round()),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      child: Text('0',
                          style:
                              TextStyle(fontSize: 20, color: Colors.black54)),
                    ),
                    const Positioned(
                      right: 0,
                      child: Text('10',
                          style:
                              TextStyle(fontSize: 20, color: Colors.black54)),
                    ),
                  ],
                ),

                // ── 작은 참조 이모티콘 ──
                Row(
                  children: const [
                    SizedBox(width: 12),
                    Text(
                      '평온',
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    Text(
                      '약한\n불안',
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    Text(
                      '중간\n불안',
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    Text(
                      '강한\n불안',
                      textAlign: TextAlign.center,
                    ),
                    Spacer(),
                    Text(
                      '극도의\n불안',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(width: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
