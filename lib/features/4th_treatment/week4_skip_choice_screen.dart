
// lib/features/4th_treatment/week4_skip_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'week4_concentration_screen.dart';
import 'week4_anxiety_screen.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'week4_finish_screen.dart';

// ✅ UI 위젯
import 'package:gad_app_team/widgets/jellyfish_notice.dart';
import 'package:gad_app_team/widgets/quiz_card.dart';               // 본문 카드
import 'package:gad_app_team/widgets/choice_card_button.dart';      // 선택 버튼(라벨 고정)

class Week4SkipChoiceScreen extends StatelessWidget {
  final List<String> allBList;
  final int beforeSud;
  final List<String> remainingBList;
  final bool isFromAfterSud;
  final List<String>? existingAlternativeThoughts;
  final String? abcId;
  final int loopCount;

  const Week4SkipChoiceScreen({
    super.key,
    required this.allBList,
    required this.beforeSud,
    required this.remainingBList,
    this.isFromAfterSud = false,
    this.existingAlternativeThoughts,
    this.abcId,
    this.loopCount = 1,
  });

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // ===== 안내 문구 =====
    final description = isFromAfterSud
        ? '아직 불안 점수가 낮아지지 않으셨네요. 또 다른 불안한 생각이 있어서 그럴 수 있어요.\n불안을 만드는 또 다른 생각을 하나 찾아보도록 해요!'
        : '아직 도움이 되는 생각을 찾아보지 않은 부분이 있으시네요.\n\n모든 생각에서 꼭 도움이 되는 생각을 찾아봐야 하는 건 아니지만, \n그 중 하나라도 \'조금 덜 불안해지는 방향\'으로 바라보면 어떨까요?';

    // ===== 네비게이션 핸들러 (원본 로직 유지) =====
    void onPrimary() {
      if (!isFromAfterSud) {
        // 건너뛴 생각 다시 보기
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week4ConcentrationScreen(
              bListInput: List<String>.from(allBList),
              beforeSud: beforeSud,
              allBList: allBList,
              abcId: abcId,
              loopCount: loopCount,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        // AfterSUD에서 온 경우: 불안 생각 추가
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week4AnxietyScreen(
              beforeSud: beforeSud,
              existingAlternativeThoughts: existingAlternativeThoughts,
              loopCount: loopCount + 1,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    }

    void onSecondary() {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => Week4AnxietyScreen(
            beforeSud: beforeSud,
            existingAlternativeThoughts: existingAlternativeThoughts,
            loopCount: loopCount + 1,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }

    // ===== 레이아웃 =====
    final horizontal = 34.0;
    final screenW = MediaQuery.of(context).size.width;
    final maxCardWidth = screenW - horizontal * 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: '4주차 - 인지 왜곡 찾기'),
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
                      // =========================
                      // 1) 본문 카드: QuizCard (1/1 진행 표시 안 함)
                      // =========================
                      QuizCard(
                        quizText: description,
                        quizSize: 18,
                        currentIndex: 1,
                        // totalCount
                      ),

                      const SizedBox(height: 16),

                      // =========================
                      // 2) 해파리 알림 풍선
                      // =========================
                      JellyfishNotice(
                        feedback:
                        '만약 지금은 부담스러우시다면,\n걱정일기에 가볍게 적어두고 다음에 \n이어가도 좋아요.',
                      ),

                      const SizedBox(height: 20),

                      // =========================
                      // 3) 선택 버튼들 (라벨은 위젯 고정값)
                      //    - 파란(healthy): 메인 액션
                      //    - 분홍(anxious): 보조 액션
                      // =========================
                      ChoiceCardButton(
                        type: ChoiceType.other, // 파란색: 주 버튼
                        onPressed: onPrimary,
                        othText: '도움이 되는 생각을 찾아볼게요!',
                        height: 54,
                      ),
                      if (!isFromAfterSud) ...[
                        const SizedBox(height: 10),
                        ChoiceCardButton(
                          type: ChoiceType.another, // 분홍색: 보조 버튼
                          onPressed: onSecondary,
                          anoText: '또 다른 생각으로 진행할게요',
                          height: 54,
                        ),
                      ],

                      // (선택) 4주차 마무리하기 — loopCount >= 2일 때 노출
                      if (loopCount >= 2) ...[
                        const SizedBox(height: 10),
                        ChoiceCardButton(
                          type: ChoiceType.another, // 분홍/보조 스타일
                          height: 54,
                          anoText: '4주차 마무리하기',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const Week4FinishScreen(),
                              ),
                            );
                          },
                        ),
                      ]
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
