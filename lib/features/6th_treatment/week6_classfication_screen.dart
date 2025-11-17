// 📘 week6_classification_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/quiz_card.dart';
import 'package:gad_app_team/widgets/q_jellyfish_notice.dart';
import 'package:gad_app_team/widgets/choice_card_button.dart';

import 'week6_next_relieve_screen.dart';

class Week6ClassificationScreen extends StatefulWidget {
  final List<String> behaviorListInput;
  final List<String> allBehaviorList;

  const Week6ClassificationScreen({
    super.key,
    required this.behaviorListInput,
    required this.allBehaviorList,
  });

  @override
  State<Week6ClassificationScreen> createState() =>
      _Week6ClassificationScreenState();
}

class _Week6ClassificationScreenState extends State<Week6ClassificationScreen> {
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;

  late List<String> _behaviorList;
  late String _currentBehavior;
  final Map<String, double> _behaviorScores = {};
  String? _selectedFeedback;

  @override
  void initState() {
    super.initState();
    _fetchLatestAbcModel();
  }

  Future<void> _fetchLatestAbcModel() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _abcModel = null;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _abcModel = snapshot.docs.first.data();
        _behaviorList = widget.behaviorListInput;
        _currentBehavior =
        _behaviorList.isNotEmpty ? _behaviorList.first : '행동이 없습니다.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  void _onSelectBehaviorType(String type) {
    if (_currentBehavior.isEmpty) return;

    setState(() {
      _behaviorScores[_currentBehavior] = (type == 'face') ? 0.0 : 10.0;
      _selectedFeedback = type == 'face'
          ? '정답! 불안을 직면하는 행동이에요.'
          : '정답! 불안을 회피하는 행동이에요.';
    });
  }

  void _onNext() {
    // ✋ 로직 그대로 유지
    if (!_behaviorScores.containsKey(_currentBehavior)) return;

    final currentIndex = widget.allBehaviorList.indexOf(_currentBehavior);
    List<String> remainingBehaviors = [];
    if (currentIndex >= 0 && currentIndex < widget.allBehaviorList.length - 1) {
      remainingBehaviors = widget.allBehaviorList.sublist(currentIndex + 1);
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week6NextRelieveScreen(
          selectedBehavior: _currentBehavior,
          behaviorType:
          _behaviorScores[_currentBehavior] == 0.0 ? 'face' : 'avoid',
          sliderValue: 5.0,
          remainingBehaviors:
          remainingBehaviors.isNotEmpty ? remainingBehaviors : null,
          allBehaviorList: widget.allBehaviorList,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double sidePadding = 20.0;
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🌊 배경 (Week3 스타일과 동일)
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

          SafeArea(
            child: Column(
              children: [
                const CustomAppBar(title: '6주차 - 불안 직면 VS 회피'),

                // 위쪽 콘텐츠 영역
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: 12,
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : (_error != null)
                        ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                        : (_abcModel == null)
                        ? const Center(
                      child: Text(
                        '최근에 작성한 ABC모델이 없습니다.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                        : Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),

                        // 🔹 행동 카드
                        QuizCard(
                          noticeText: '$userName님께서 작성한 행동',
                          quizText: _currentBehavior,
                          // 이 화면은 한 개씩만 보여주니까 1/1로
                          currentIndex: 1,
                          totalCount: 1,
                        ),
                        // const SizedBox(height: 15),

                        // 🔹 해파리 말풍선
                        JellyfishNotice(
                          feedback: _selectedFeedback ??
                              '위 행동이 불안을 직면하는 행동인지, \n회피하는 행동인지 선택해주세요.',
                          feedbackColor: _selectedFeedback == null
                              ? Colors.grey.shade600
                              : _behaviorScores[_currentBehavior] ==
                              0.0
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF5252),
                        ),
                        // const SizedBox(height: 20),

                        // 🔹 선택 버튼
                        Column(
                          children: [
                            ChoiceCardButton(
                              height: 54,
                              type: ChoiceType.healthy,
                              onPressed: () =>
                                  _onSelectBehaviorType('face'),
                            ),
                            const SizedBox(height: 10),
                            ChoiceCardButton(
                              height: 54,
                              type: ChoiceType.anxious,
                              onPressed: () =>
                                  _onSelectBehaviorType('avoid'),
                            ),
                          ],
                        ),

                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // 아래 네비게이션 고정
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: NavigationButtons(
                    leftLabel: '이전',
                    rightLabel: '다음',
                    onBack: () => Navigator.pop(context),
                    onNext: _onNext,
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
