import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'week3_classification_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Week3ClassificationScreen extends StatefulWidget {
  const Week3ClassificationScreen({super.key});

  @override
  Week3ClassificationScreenState createState() =>
      Week3ClassificationScreenState();
}

class Week3ClassificationScreenState extends State<Week3ClassificationScreen> {
  // 퀴즈 문장 데이터 (문장, 정답)
  final List<Map<String, dynamic>> quizSentences = [
    // 도움이 되지 않는 생각
    {'text': '나는 안전하지 않아', 'type': 'anxious'},
    {'text': '무언가 나쁜 일이 일어날 것이다', 'type': 'anxious'},
    {'text': '나쁜 일이 일어나지 않도록 미리 막아야 한다', 'type': 'anxious'},
    {'text': '사람들이 나를 비웃고 조롱할 것이다', 'type': 'anxious'},
    {'text': '나는 실수를 할 것이고, 그 실수는 돌이킬 수 없을 만큼 심각할 것이다', 'type': 'anxious'},
    {'text': '나는 두려움을 절대 감당할 수 없다', 'type': 'anxious'},
    {'text': '혹시 실수해서 학부모나 학교의 불만을 살까 봐 걱정이 된다', 'type': 'anxious'},
    {'text': '예상치 못한 지출이 생기면 감당할 수 없을 것이다', 'type': 'anxious'},
    {'text': '부모님께 갑자기 큰일이 생기면 어떡하지?', 'type': 'anxious'},
    {'text': '내가 무언가를 완벽히 처리하지 못하면 큰일이 날 것이다', 'type': 'anxious'},
    {'text': '내 말이 오해를 불러일으켰을 수 있어', 'type': 'anxious'},
    // 도움이 되는 생각
    {'text': '대부분의 경우, 실제로는 나쁜 일이 일어나지 않는다', 'type': 'healthy'},
    {'text': '설령 나쁜 일이 일어난다고 해도 나는 잘 대처할 수 있다', 'type': 'healthy'},
    {'text': '나는 생각보다 용기 있고, 대처 능력이 있다', 'type': 'healthy'},
    {'text': '두렵다고 해서 중요한 일을 포기하지 않아도 된다', 'type': 'healthy'},
    {'text': '누구나 실수할 수 있다. 실수는 인간의 당연한 모습이다', 'type': 'healthy'},
    {
      'text': '나는 완벽하지 않아도 괜찮다 (사람들은 완벽한 사람보다는 따뜻하고 친절한 사람을 더 좋아한다)',
      'type': 'healthy',
    },
    {'text': '문제 상황은 보통 내가 잘 해결할 수 있다', 'type': 'healthy'},
    {'text': '때로 불안을 느끼는 것은 정상이며 자연스러운 현상이다', 'type': 'healthy'},
    {'text': '예상치 못한 지출이 생기더라도 감당할 수 있을 것이다', 'type': 'healthy'},
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
        // 마지막 문장 이후 결과 화면으로 이동
        saveQuizResult(correctCount, quizResults);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    Week3ClassificationResultScreen(
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

  void _showWrongDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8F9FF), Color(0xFFE3E6F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '알림',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222244),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF444466),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2962F6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('확인', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
              // 상단 원형 아이콘
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF2962F6), Color(0xFF6EC6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _checkAnswer(String selected) {
    if (answered) return;
    final correct = shuffledSentences[currentIndex]['type'] == selected;
    setState(() {
      answered = true;
      if (correct) {
        correctCount++;
        feedback =
            selected == 'healthy'
                ? '정답! 도움이 되는 생각이에요.'
                : '정답! 도움이 되지 않는 생각이에요.';
        feedbackColor = const Color(0xFF4CAF50); // 초록
      } else {
        feedback =
            selected == 'healthy'
                ? '도움이 되는 생각이라고 하셨군요. 하지만 이건 도움이 되지 않는 생각쪽에 가깝습니다.'
                : '도움이 되지 않는 생각이라고 하셨군요. 하지만 이건 도움이 되는 생각쪽에 가깝습니다.';
        feedbackColor = const Color(0xFFFF5252); // 빨강
        // 오답 다이얼로그 메시지 분기
        String dialogMsg = '';
        if (shuffledSentences[currentIndex]['type'] == 'anxious' &&
            selected == 'healthy') {
          dialogMsg =
              '도움이 된다고 생각하셨군요. 일시적으로 이런 생각이 불안을 줄일 수는 있겠습니다만 장기적으로는 불안을 유지시켜서 도움이 되지 않는 생각에 가깝습니다.';
        } else if (shuffledSentences[currentIndex]['type'] == 'healthy' &&
            selected == 'anxious') {
          dialogMsg =
              '도움이 되지 않는다고 생각하셨군요. 일시적으로 이런 생각이 불안을 높일 수는 있겠습니다만 장기적으로는 불안을 완화시켜서 도움이 되는 생각에 가깝습니다.';
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showWrongDialog(dialogMsg);
        });
      }
      // 결과 저장
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
    // 전체 맞은 개수 저장
    await prefs.setInt('week3_classification_correct_count', correctCount);
    // 오답 문항만 추출
    final wrongList =
        quizResults
            .where((item) => item['isCorrect'] == false)
            .map(
              (item) => {
                'text': item['text'],
                'userChoice': item['userChoice'],
                'correctType': item['correctType'],
              },
            )
            .toList();
    await prefs.setString(
      'week3_classification_wrong_list',
      wrongList.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '3주차 - Self Talk'),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 상단 카드
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Question icon above title
                        Image.asset(
                          'assets/image/question_icon.png',
                          width: 32,
                          height: 32,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '도움이 되는 생각과 도움이 되지 않는 생각을\n구분해 볼까요?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // 퀴즈 문장
                        Text(
                          shuffledSentences[currentIndex]['text'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        Text(
                          '${currentIndex + 1}/${shuffledSentences.length}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // 하단 카드
            Expanded(
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "화면에 보이는 생각이 어떠한 생각인지 선택한 후 '다음'버튼을 누르세요.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // 피드백 영역 (고정 높이)
                      SizedBox(
                        height: 56,
                        child:
                            feedback != null
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '💡',
                                      style: TextStyle(fontSize: 22),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        feedback!,
                                        style: TextStyle(
                                          color: feedbackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                )
                                : Container(
                                  width: double.infinity,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF2F3FE),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: const [
                                      Text(
                                        '💡',
                                        style: TextStyle(fontSize: 22),
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          '여기에서 정답을 확인할 수 있어요!',
                                          style: TextStyle(
                                            color: Color(0xFF8888AA),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 140,
                              child: ElevatedButton(
                                onPressed: () => _checkAnswer('healthy'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2962F6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '도움이 되는 생각',
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 140,
                              child: ElevatedButton(
                                onPressed: () => _checkAnswer('anxious'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    226,
                                    86,
                                    86,
                                  ),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '도움이 되지 않는 생각',
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
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
            ),
            const SizedBox(height: 24), // new spacing
            // Removed Spacer to let cards expand directly above navigation buttons.
            NavigationButtons(
              onBack: () => Navigator.pop(context),
              onNext: () {
                if (answered) {
                  _nextSentence();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
