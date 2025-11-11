import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/quiz_card.dart';
import 'package:gad_app_team/widgets/jellyfish_notice.dart';
import 'package:gad_app_team/widgets/choice_card_button.dart';
import 'package:gad_app_team/data/user_provider.dart';

// ✅ 결과 화면
import 'week6_visual_screen.dart';

class Week6FinishQuizScreen extends StatefulWidget {
  /// [{behavior: ..., userChoice: ..., actualResult: ...}]
  final List<Map<String, dynamic>> mismatchedBehaviors;

  const Week6FinishQuizScreen({super.key, required this.mismatchedBehaviors});

  @override
  State<Week6FinishQuizScreen> createState() => _Week6FinishQuizScreenState();
}

class _Week6FinishQuizScreenState extends State<Week6FinishQuizScreen> {
  int _currentIdx = 0;
  final Map<int, String> _answers = {}; // 'face' | 'avoid'
  Map<String, dynamic>? _abcModel;
  String? _abcModelId;
  bool _isLoading = true;
  String? _error;

  List<String> _behaviorList = [];
  String _currentBehavior = '';

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
          _behaviorList = [];
          _currentBehavior = '';
          _isLoading = false;
        });
        return;
      }

      final data = snapshot.docs.first.data();
      final docId = snapshot.docs.first.id;

      final consequenceBehavior = (data['consequence_behavior'] ?? '').toString();
      final list = consequenceBehavior
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      setState(() {
        _abcModel = data;
        _abcModelId = docId;
        _behaviorList = list;
        _currentBehavior = _behaviorList.isNotEmpty ? _behaviorList.first : '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  /// 🔹 모든 답변이 끝났을 때 결과 화면으로 이동
  void _goToVisualScreen() {
    // 회피/직면으로 나누어 테이블에 표시할 리스트 생성
    final List<String> avoidList = [];
    final List<String> faceList = [];

    for (int i = 0; i < _behaviorList.length; i++) {
      final ans = _answers[i];
      if (ans == 'avoid') {
        avoidList.add(_behaviorList[i]);
      } else if (ans == 'face') {
        faceList.add(_behaviorList[i]);
      }
    }

    // Week6VisualScreen으로 이동 (팝업 없이)
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Week6VisualScreen(
          previousChips: avoidList,        // ← 불안을 회피하는 행동
          alternativeChips: faceList,      // ← 불안을 직면하는 행동
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// 다음 문항으로 이동하거나, 마지막이면 결과 화면으로 이동
  void _nextBehavior() {
    if (_currentIdx < _behaviorList.length - 1) {
      setState(() {
        _currentIdx++;
        _currentBehavior = _behaviorList[_currentIdx];
      });
    } else {
      // 🔚 마지막 문제를 답한 뒤에는 저장 대신 결과 화면으로
      _goToVisualScreen();
    }
  }

  bool get _hasBehavior => _currentBehavior.isNotEmpty;
  bool get _canAnswer => _hasBehavior && _answers[_currentIdx] == null;

  /// 비활성화처럼 보이게 하는 시각/터치 래퍼
  Widget _wrapDisabled({required bool enabled, required Widget child}) {
    return enabled
        ? child
        : Opacity(opacity: 0.5, child: IgnorePointer(ignoring: true, child: child));
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: '6주차 - 마무리 퀴즈'),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌊 배경 (원본 이미지 + 밝은 오버레이)
          Image.asset('assets/image/eduhome.png', fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.35)),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (!_hasBehavior)
              const Center(
                child: Text(
                  '최근에 작성한 ABC모델이 없습니다.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // 🧠 상단 퀴즈 카드
                      Expanded(
                        flex: 4,
                        child: QuizCard(
                          quizText: '$userName님이 작성한 행동: $_currentBehavior',
                          currentIndex: _currentIdx + 1,
                          totalCount: _behaviorList.length, // 1/n 표시
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 💬 피드백 (선택 전/후 메시지)
                      JellyfishNotice(
                        feedback: _answers[_currentIdx] == null
                            ? '이 행동은 불안을 직면하는 쪽일까요, 회피하는 쪽일까요?'
                            : _answers[_currentIdx] == 'face'
                            ? '불안을 직면하는 행동이라고 선택하셨습니다.'
                            : '불안을 회피하는 행동이라고 선택하셨습니다.',
                        feedbackColor: _answers[_currentIdx] == null
                            ? Colors.indigo
                            : _answers[_currentIdx] == 'face'
                            ? const Color(0xFF40C79A) // 민트
                            : const Color(0xFFEB6A67), // 코랄
                      ),
                      const SizedBox(height: 20),

                      // 🎯 선택 버튼 (Mindrium 공통 위젯)
                      SizedBox(
                        height: 180,
                        child: Column(
                          children: [
                            Expanded(
                              child: _wrapDisabled(
                                enabled: _canAnswer,
                                child: ChoiceCardButton(
                                  type: ChoiceType.healthy,
                                  onPressed: () {
                                    if (!_canAnswer) return;
                                    setState(() => _answers[_currentIdx] = 'face');
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: _wrapDisabled(
                                enabled: _canAnswer,
                                child: ChoiceCardButton(
                                  type: ChoiceType.anxious,
                                  onPressed: () {
                                    if (!_canAnswer) return;
                                    setState(() => _answers[_currentIdx] = 'avoid');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ⛵ 네비게이션 버튼 (다음은 답변 후에만 활성)
                      NavigationButtons(
                        onBack: _currentIdx > 0
                            ? () {
                          setState(() {
                            _currentIdx--;
                            _currentBehavior = _behaviorList[_currentIdx];
                          });
                        }
                            : () => Navigator.pop(context),
                        onNext: (_answers[_currentIdx] != null) ? _nextBehavior : null,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
