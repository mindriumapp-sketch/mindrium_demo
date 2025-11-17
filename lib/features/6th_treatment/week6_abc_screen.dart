import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/6th_treatment/week6_concentration_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';

class Week6AbcScreen extends StatefulWidget {
  const Week6AbcScreen({super.key});

  @override
  State<Week6AbcScreen> createState() => _Week6AbcScreenState();
}

class _Week6AbcScreenState extends State<Week6AbcScreen> {
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  Widget _highlightedText(String text) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF59D).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      cardTitle: '최근 ABC 모델 확인',
      onBack: () => Navigator.pop(context),
      onNext: () {
        final behaviorData = _abcModel?['consequence_behavior'] ?? '';
        List<String> behaviorList = [];

        if (behaviorData is String && behaviorData.isNotEmpty) {
          behaviorList = behaviorData
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week6ConcentrationScreen(
              behaviorListInput: behaviorList,
              allBehaviorList: behaviorList,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      /// 🌊 기능 내용 (기존 body → child)
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_error != null) {
            return Center(
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          }
          if (_abcModel == null) {
            return const Center(
              child: Text(
                '최근에 작성한 ABC모델이 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final a = _abcModel?['activatingEvent'] ?? '';
          final b = _abcModel?['belief'] ?? '';
          final cPhysical = _abcModel?['consequence_physical'] ?? '';
          final cEmotion = _abcModel?['consequence_emotion'] ?? '';
          final cBehavior = _abcModel?['consequence_behavior'] ?? '';
          final userName = Provider.of<UserProvider>(
            context,
            listen: false,
          ).userName;

          String formattedDate = '';
          if (_abcModel?['createdAt'] != null) {
            final timestamp = _abcModel!['createdAt'] as Timestamp;
            final date = timestamp.toDate();
            formattedDate =
                '${date.year}년 ${date.month}월 ${date.day}일에 작성된 걱정일기';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (formattedDate.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/image/question_icon.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '최근에 작성하신 ABC 걱정일기를\n확인해 볼까요?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "$userName님은 "),
                    WidgetSpan(child: _highlightedText("'$a'")),
                    const TextSpan(text: " 상황에서 "),
                    WidgetSpan(child: _highlightedText("'$b'")),
                    const TextSpan(text: " 생각을 하였습니다.\n\n"),
                    if (cPhysical.isNotEmpty ||
                        cEmotion.isNotEmpty ||
                        cBehavior.isNotEmpty) ...[
                      const TextSpan(text: "그 결과 "),
                      if (cPhysical.isNotEmpty) ...[
                        const TextSpan(text: "신체적으로 "),
                        WidgetSpan(child: _highlightedText("'$cPhysical'")),
                        const TextSpan(text: " 증상이 나타났고, "),
                      ],
                      if (cEmotion.isNotEmpty) ...[
                        WidgetSpan(child: _highlightedText("'$cEmotion'")),
                        const TextSpan(text: " 감정을 느끼셨으며, "),
                      ],
                      if (cBehavior.isNotEmpty) ...[
                        WidgetSpan(child: _highlightedText("'$cBehavior'")),
                        const TextSpan(text: "\n행동을 하였습니다.\n\n"),
                      ],
                    ],
                  ],
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
