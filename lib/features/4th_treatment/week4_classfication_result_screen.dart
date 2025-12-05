// lib/features/4th_treatment/week4_classfication_result_screen.dart
import 'package:gad_app_team/utils/text_line_material.dart';
// import 'package:provider/provider.dart';

// import 'package:gad_app_team/data/user_provider.dart';
import 'week4_alternative_thoughts.dart';
import 'week4_skip_choice_screen.dart';
import 'week4_after_sud_screen.dart';
import 'week4_classfication_screen.dart' as week4;
import 'package:gad_app_team/data/apply_solve_provider.dart';

// ✅ 동일 UI 컴포넌트 (SkipChoice와 통일)
import 'package:gad_app_team/widgets/jellyfish_notice.dart';
import 'package:gad_app_team/widgets/quiz_card.dart';
import 'package:gad_app_team/widgets/choice_card_button.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';

class Week4ClassificationResultScreen extends StatelessWidget {
  const Week4ClassificationResultScreen({
    super.key,
    this.bScores,
    this.bList,
    this.beforeSud,
    this.remainingBList,
    this.allBList,
    this.alternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.existingAlternativeThoughts,
    this.abcId,
    this.loopCount = 1,
  });

  List<String> _removeDuplicates(List<String> list) {
    final uniqueList = <String>[];
    for (final item in list) {
      if (!uniqueList.contains(item)) uniqueList.add(item);
    }
    return uniqueList;
  }

  final List<double>? bScores;
  final List<String>? bList;
  final int? beforeSud;
  final List<String>? remainingBList;
  final List<String>? allBList;
  final List<String>? alternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;
  final int loopCount;

  String _chipLabel(dynamic raw) {
    if (raw == null) return '';
    if (raw is Map) {
      return (raw['label'] ?? '').toString();
    }
    if (raw is String) {
      final match = RegExp(r'label\s*[:=]\s*([^,}]+)').firstMatch(raw);
      if (match != null) return match.group(1)?.trim() ?? '';
    }
    return raw.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String mainThought = _chipLabel(
      (bList != null && bList!.isNotEmpty) ? bList!.last : '',
    );

    // 경로 기반 카피/플로우
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final flow = context.read<ApplyOrSolveFlow>()..syncFromArgs(args, notify: false);
    final String? abcId_  = args['abcId'] as String? ?? flow.diaryId;
    final String origin  = args['origin'] as String? ?? flow.origin;
    final dynamic diary   = args['diary'] ?? flow.diary;
    final bool isFromApply = origin == 'apply';

    // final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 메인 문구
    String mainQuestionText;
    if (isFromApply) {
      mainQuestionText = '다른 생각에 대해서도 도움이 되는 생각을 찾아볼까요?';
    } else if (isFromAnxietyScreen) {
      mainQuestionText =
      '방금 보셨던 "$mainThought"라는 생각에 대해 도움이 되는 생각을 찾아보는 시간을 가져보겠습니다!';
    } else {
      mainQuestionText =
      '방금 보셨던 "$mainThought"라는 생각에 대해 도움이 되는 생각을 찾아볼까요?';
    }

    // 디폴트 값들
    final int safeBeforeSud = beforeSud ?? 0;
    final List<String> safeRemainingBList = remainingBList ?? const <String>[];
    final List<String> safeAllBList = allBList ?? const <String>[];

    // 보조 문구/세컨 버튼 라벨
    final supportText = isFromApply
        ? '만약 지금은 좀 부담스러우시다면,\n다음번에 해도 괜찮아요.'
        : '만약 지금은 좀 부담스러우시다면,\n다른 생각들 먼저 보고 다시 돌아와도 괜찮아요.';
    final secondaryButtonLabel =
    isFromApply ? '다음번에 찾아볼게요.' : '다른 생각으로 진행할게요.';

    // QuizCard에 넣을 본문(한 카드로 모으기)
    final String quizText = [
      mainQuestionText,
      if (!isFromAnxietyScreen) // 선택 유도 문구
        '아래 두 가지 방법 중 하나를 선택해주세요.',
    ].join(' ');

    // ===== 네비게이션 핸들러 (원본 로직 유지) =====
    void onPrimary() {
      if (isFromApply) {
        // 적용하기 플로우: 선택 화면으로 돌아가 다른 생각 선택
        Navigator.pushReplacementNamed(
          context,
          '/apply_alt_thought',
          arguments: {
            ...flow.toArgs(),
            'abcId': abcId_,
            'beforeSud': safeBeforeSud,
            'origin': 'apply',
            if (diary != null) 'diary': diary,
          },
        );
        return;
      }
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) =>
              Week4AlternativeThoughtsScreen(
                allBList: safeAllBList,
                previousChips:
                mainThought.isNotEmpty ? [mainThought] : [],
                beforeSud: safeBeforeSud,
                remainingBList: safeRemainingBList,
                existingAlternativeThoughts: _removeDuplicates([
                  ...?existingAlternativeThoughts,
                  ...?alternativeThoughts,
                ]),
                isFromAnxietyScreen: isFromAnxietyScreen,
                originalBList: safeAllBList,
                abcId: abcId ?? abcId_,  // 명시적으로 전달
                loopCount: loopCount,
              ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }

    void onSecondary() {
      if (isFromApply) {
        // 적용하기: 바로 After SUD
        Navigator.pushReplacementNamed(
          context,
          '/after_sud',
          arguments: {
            ...flow.toArgs(),
            'abcId': abcId_,
            'origin': origin,
            'diary': diary,
          },
        );
        return;
      }

      // 대체생각이 있으면 After SUD로
      if (alternativeThoughts != null &&
          alternativeThoughts!.isNotEmpty) {
        final String? diaryId = abcId ?? abcId_;
        if (diaryId != null && diaryId.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  Week4AfterSudScreen(
                    beforeSud: safeBeforeSud,
                    currentB: _chipLabel(
                      (bList != null && bList!.isNotEmpty)
                          ? bList!.last
                          : '',
                    ),
                    remainingBList: safeRemainingBList,
                    allBList: safeAllBList,
                    alternativeThoughts:
                    alternativeThoughts ?? [],
                    abcId: diaryId,
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  Week4AfterSudScreen(
                    beforeSud: safeBeforeSud,
                    currentB: _chipLabel(
                      (bList != null && bList!.isNotEmpty)
                          ? bList!.last
                          : '',
                    ),
                    remainingBList: safeRemainingBList,
                    allBList: safeAllBList,
                    alternativeThoughts:
                    alternativeThoughts ?? [],
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      } else if (safeRemainingBList.isEmpty) {
        // 남은 생각 없으면 Skip Choice
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) =>
                Week4SkipChoiceScreen(
                  allBList: safeAllBList,
                  beforeSud: safeBeforeSud,
                  remainingBList: safeRemainingBList,
                  abcId: abcId,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        // 남은 B가 있으면 다음 B로
        if (abcId_ != null && abcId_.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/alt_thought',
            arguments: {'abcId': abcId_},
          );
        } else {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) =>
                  week4.Week4ClassificationScreen(
                    bListInput: safeRemainingBList,
                    beforeSud: safeBeforeSud,
                    allBList: safeAllBList,
                    alternativeThoughts: alternativeThoughts,
                    abcId: abcId,
                  ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        }
      }
    }

    // ===== 레이아웃 =====
    final horizontal = 34.0;
    final screenW = MediaQuery.of(context).size.width;
    final maxCardWidth = screenW - horizontal * 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: '인지 왜곡 찾기'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌊 배경
          Container(
            color: Colors.white, // 흰 배경 유지
            child: Opacity(
              opacity: 0.35, // ApplyDesign과 동일한 투명도
              child: Image.asset(
                'assets/image/eduhome.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          // 본문
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontal, 24, horizontal, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1) 본문 카드 (진행표시 생략)
                      QuizCard(
                        quizText: quizText,
                        quizSize: 18,
                        currentIndex: 1,
                        // totalCount: null → 진행상태 숨김 (위젯에서 null 허용 구현되어 있어야 함)
                      ),

                      const SizedBox(height: 16),

                      // 2) 해파리 말풍선
                      JellyfishNotice(
                        feedback: supportText
                      ),

                      const SizedBox(height: 20),

                      // 3) 선택 버튼들 (ChoiceCardButton 사용)
                      ChoiceCardButton(
                        // 메인 액션(파란)
                        type: ChoiceType.other,
                        onPressed: onPrimary,
                        // 라벨을 외부에서 덮어쓰기 위해 text 사용(네가 수정한 ChoiceCardButton에 대응)
                        othText: '도움이 되는 생각을 찾아볼게요!',
                        height: 54,
                      ),

                      if (!isFromAnxietyScreen) ...[
                        const SizedBox(height: 10),
                        ChoiceCardButton(
                          // 보조 액션(분홍)
                          type: ChoiceType.another,
                          onPressed: onSecondary,
                          anoText: secondaryButtonLabel,
                          height: 54,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
