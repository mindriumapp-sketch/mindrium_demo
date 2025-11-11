// lib/features/4th_treatment/week4_abc_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/4th_treatment/week4_imagination_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_concentration_screen.dart';

// ✅ 튜토리얼/적용하기 공용 레이아웃 (BlueWhiteCard 기반)
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ApplyDesign

class Week4AbcScreen extends StatefulWidget {
  final String? abcId;
  final int? sud;
  final int loopCount;

  const Week4AbcScreen({super.key, this.abcId, this.sud, this.loopCount = 1});

  @override
  State<Week4AbcScreen> createState() => _Week4AbcScreenState();
}

class _Week4AbcScreenState extends State<Week4AbcScreen> {
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;
  List<String> _bList = [];

  @override
  void initState() {
    super.initState();
    final id = widget.abcId;
    if (id != null && id.isNotEmpty) {
      _fetchAbcModelById(id);
    } else {
      _fetchLatestAbcModel();
    }
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
        _bList = _parseBeliefToList(_abcModel?['belief']);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  List<String> _parseBeliefToList(dynamic raw) {
    final s = (raw ?? '').toString();
    return s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _fetchAbcModelById(String abcId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보 없음');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .doc(abcId)
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        setState(() {
          _abcModel = null;
          _bList = [];
          _isLoading = false;
          _error = '해당 ABC모델을 찾을 수 없습니다.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _abcModel = doc.data();
        _bList = _parseBeliefToList(_abcModel?['belief']);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  // ✅ Week6 스타일에 맞춘 하이라이트 박스
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
    final sud = widget.sud;

    return ApplyDesign(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      cardTitle: '최근 ABC 모델 확인',
      onBack: () => Navigator.pop(context),
      onNext: () {
        final id = widget.abcId;

        if (id == null || id.isEmpty) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const Week4ImaginationScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          return;
        }

        setState(() => _isLoading = true);
        final beforeSudValue = sud ?? 0;

        if (_bList.isEmpty) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('B(생각) 데이터가 없습니다.')),
          );
          return;
        }

        setState(() => _isLoading = false);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week4ConcentrationScreen(
              bListInput: _bList,
              beforeSud: beforeSudValue,
              allBList: _bList,
              abcId: widget.abcId,
              loopCount: widget.loopCount,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      // 💬 카드 내부 콘텐츠 (Week6 스타일 그대로 구성)
      child: _buildCardBody(context),
    );
  }

  Widget _buildCardBody(BuildContext context) {
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
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 날짜
    String formattedDate = '';
    if (_abcModel?['createdAt'] != null) {
      final timestamp = _abcModel!['createdAt'] as Timestamp;
      final date = timestamp.toDate();
      formattedDate = '${date.year}년 ${date.month}월 ${date.day}일에 작성된 걱정일기';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 📅 날짜 칩 (회색 배경, 둥근 모서리) — Week6 스타일
        if (formattedDate.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

        // ❓ 물음표 아이콘 + 부제목 (정중앙)
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

        // 📄 본문 (Week6와 동일한 문장 구성/하이라이트)
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "${userName ?? '사용자'}님은 "),
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
  }
}
