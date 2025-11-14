import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'week5_classification_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/q_quiz_card.dart';
import 'package:gad_app_team/widgets/q_jellyfish_notice.dart';
import 'package:gad_app_team/widgets/choice_card_button.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

class Week5ClassificationScreen extends StatefulWidget {
  const Week5ClassificationScreen({super.key});

  @override
  Week5ClassificationScreenState createState() =>
      Week5ClassificationScreenState();
}

class Week5ClassificationScreenState extends State<Week5ClassificationScreen> {
  final List<Map<String, dynamic>> quizSentences = [
    // 불안 회피
    {'text': '부담스러운 일정이나 모임을\n계속 미루거나 빠진다.', 'type': 'anxious'},
    {'text': '불편한 사람과의 만남이나 대화를\n계속 피한다.', 'type': 'anxious'},
    {'text': '불안한 장소에 가더라도\n빨리 떠날 생각만 한다.', 'type': 'anxious'},
    {'text': '불안감에서 벗어나려고 스마트폰이나 TV 등 즉각적인 자극에 지나치게 몰두한다.', 'type': 'anxious'},
    {'text': '모임이나 대화 중 질문에 대답을 짧게 하거나 말하는 것을 최소화한다.', 'type': 'anxious'},
    {'text': '중요한 결정을 불안 때문에 계속 미룬다.', 'type': 'anxious'},
    {'text': '불안을 느낄 때마다 자주\n약(진정제, 두통약 등)에 의존한다.', 'type': 'anxious'},
    {'text': '발표나 회의 시 항상 원고나 자료에만\n집중하며 대화는 최소화한다.', 'type': 'anxious'},
    {'text': '불안을 덜기 위해 휴대폰이나 작은 물건을\n계속 만지작거린다.', 'type': 'anxious'},
    {'text': '불안한 생각이 떠오르면 즉시 다른 일로\n주의를 돌려 생각을 차단한다.', 'type': 'anxious'},
    {'text': '걱정거리를 "생각하지 말자"라고\n애써 무시한다.', 'type': 'anxious'},
    // 불안 직면
    {'text': '부담스러운 일정이나 모임을 오랜 시간동안 참석해본다.', 'type': 'healthy'},
    {'text': '불편한 사람과의 만남이나 대화를\n짧게라도 시도해본다.', 'type': 'healthy'},
    {'text': '불안한 장소에서 잠시 머물며 몸이\n천천히 적응하는 걸 경험한다.', 'type': 'healthy'},
    {'text': '모임에서 간단한 질문을 먼저 하거나,\n상대방과 짧은 대화를 시도한다.', 'type': 'healthy'},
    {'text': '불안하더라도 작은 일부터 우선순위를\n정해 조금씩 결정을 내린다.', 'type': 'healthy'},
    {'text': '불안할 때 약물 대신 심호흡이나\n근육 이완법을 시도해본다.', 'type': 'healthy'},
    {'text': '발표나 회의 시 미리 준비한 내용에서 벗어나 조금씩 자유롭게 말한다.', 'type': 'healthy'},
    {'text': '불안한 생각이 들면 그것을 간단히 적어보고 현실적인지 점검한다.', 'type': 'healthy'},
    {'text': '걱정거리를 명확하게 적어보고\n가능한 대체 생각을 간략히 정리한다.', 'type': 'healthy'},
  ];

  late List<Map<String, dynamic>> shuffledSentences;
  int currentIndex = 0;
  String? feedback;
  Color? feedbackColor;
  bool answered = false;
  int correctCount = 0;
  List<Map<String, dynamic>> quizResults = [];

  @override
  void initState() {
    super.initState();
    shuffledSentences = List<Map<String, dynamic>>.from(quizSentences);
    shuffledSentences.shuffle();
  }

  void _nextSentence() {
    setState(() {
      if (currentIndex < shuffledSentences.length - 1) {
        currentIndex++;
        feedback = null;
        feedbackColor = null;
        answered = false;
      } else {
        saveQuizResult(correctCount, quizResults);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                Week5ClassificationResultScreen(
                  correctCount: correctCount,
                  quizResults: quizResults,
                ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    });
  }

  void _checkAnswer(String selected) {
    if (answered) return;

    final correct = shuffledSentences[currentIndex]['type'] == selected;

    setState(() {
      answered = true;

      if (correct) {
        correctCount++;
        feedback = selected == 'healthy'
            ? '정답! 불안을 직면하는 행동이에요.'
            : '정답! 불안을 회피하는 행동이에요.';
        feedbackColor = const Color(0xFF4CAF50);
      } else {
        feedback = selected == 'healthy'
            ? '불안을 직면하는 행동이라고 하셨군요.\n하지만 이건 불안을 회피하는 행동 쪽에 가깝습니다.'
            : '불안을 회피하는 행동이라고 하셨군요.\n하지만 이건 불안을 직면하는 행동 쪽에 가깝습니다.';
        feedbackColor = const Color(0xFFFF5252);
      }

      quizResults.add({
        'text': shuffledSentences[currentIndex]['text'],
        'correctType': shuffledSentences[currentIndex]['type'],
        'userChoice': selected,
        'isCorrect': correct,
      });
    });
  }

  Future<void> saveQuizResult(
      int correctCount,
      List<Map<String, dynamic>> quizResults,
      ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('week5_classification_correct_count', correctCount);

    final wrongList = quizResults
        .where((item) => item['isCorrect'] == false)
        .map((item) => {
      'text': item['text'],
      'userChoice': item['userChoice'],
      'correctType': item['correctType'],
    })
        .toList();

    await prefs.setString(
      'week5_classification_wrong_list',
      wrongList.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double sidePadding = 20.0;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🌊 배경
          Opacity(
            opacity: 0.35,
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              filterQuality: FilterQuality.high,
            ),
          ),

          // 🌟 실제 콘텐츠
          SafeArea(
            child: Column(
              children: [
                const CustomAppBar(title: '5주차 - 불안 직면 VS 회피'),

                // 위쪽: 남은 영역 전부
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),

                        // 🔹 문제 카드
                        QuizCard(
                          quizText: shuffledSentences[currentIndex]['text'],
                          currentIndex: currentIndex + 1,
                          totalCount: shuffledSentences.length,
                        ),
                        const SizedBox(height: 15),

                        // 🔹 해파리 말풍선 (피드백)
                        JellyfishNotice(
                          feedback: feedback,
                          feedbackColor: feedbackColor,
                        ),

                        const SizedBox(height: 10),

                        // 🔹 선택 버튼
                        Column(
                          children: [
                            ChoiceCardButton(
                              type: ChoiceType.healthy,
                              height: 54,
                              onPressed: () => _checkAnswer('healthy'),
                            ),
                            const SizedBox(height: 10),
                            ChoiceCardButton(
                              type: ChoiceType.anxious,
                              height: 54,
                              onPressed: () => _checkAnswer('anxious'),
                            ),
                          ],
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // 아래: 항상 바닥에 붙는 네비게이션
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: NavigationButtons(
                    onBack: () => Navigator.pop(context),
                    onNext: () {
                      if (answered) {
                        _nextSentence();
                      } else {
                        BlueBanner.show(context, '답변을 선택해주세요!');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
