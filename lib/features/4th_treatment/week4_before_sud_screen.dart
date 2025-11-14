import 'package:flutter/material.dart';
import 'package:gad_app_team/features/4th_treatment/week4_concentration_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ 새로 쓰는 공용 디자인
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ApplyDesign
import 'package:gad_app_team/widgets/blue_banner.dart';

class Week4BeforeSudScreen extends StatefulWidget {
  final int loopCount;

  const Week4BeforeSudScreen({super.key, this.loopCount = 1});

  @override
  State<Week4BeforeSudScreen> createState() => _Week4BeforeSudScreenState();
}

class _Week4BeforeSudScreenState extends State<Week4BeforeSudScreen> {
  int _sud = 5;
  bool _isLoading = false;

  Future<List<String>> _fetchBListFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('로그인 정보 없음');
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('abc_models')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return [];
    final abcModel = snapshot.docs.first.data();
    final bRaw = (abcModel['belief'] ?? '') as String;
    return bRaw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Color get _trackColor =>
      _sud <= 2 ? Colors.green : (_sud >= 8 ? Colors.red : Colors.amber);

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '4주차 - SUD 평가 (before)',
      cardTitle: '지금 느끼는 불안 정도를\n선택해 주세요',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        setState(() => _isLoading = true);
        final beforeSudValue = _sud;
        try {
          final actualBList = await _fetchBListFromFirestore();
          if (actualBList.isEmpty) {
            setState(() => _isLoading = false);
            if (!mounted) return;
            BlueBanner.show(context, 'B(생각) 데이터가 없습니다.');
            return;
          }
          setState(() => _isLoading = false);
          if (!mounted) return;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => Week4ConcentrationScreen(
                bListInput: actualBList,
                beforeSud: beforeSudValue,
                allBList: actualBList,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        } catch (e) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          BlueBanner.show(context, 'B(생각) 불러오기 실패 : ${e.toString()}');
        }
      },

      // ===== 카드 내부 UI =====
      child: _isLoading
          ? const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      )
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 점수
          Text(
            '$_sud',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: _trackColor,
            ),
          ),
          const SizedBox(height: 8),

          // 얼굴 아이콘
          Icon(
            _sud <= 2
                ? Icons.sentiment_very_satisfied
                : _sud >= 8
                ? Icons.sentiment_very_dissatisfied_sharp
                : Icons.sentiment_neutral,
            size: 120,
            color: _trackColor,
          ),
          const SizedBox(height: 20),

          // 슬라이더
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 12,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 14,
                elevation: 2,
                pressedElevation: 4,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 24,
              ),
              tickMarkShape: SliderTickMarkShape.noTickMark,
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              activeTrackColor: _trackColor,
              inactiveTrackColor: _trackColor.withOpacity(0.25),
              thumbColor: _trackColor,
              overlayColor: _trackColor.withOpacity(0.18),
              showValueIndicator: ShowValueIndicator.never,
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

          // 0 / 10 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: const [
                Text('0', style: TextStyle(color: Colors.black54)),
                Spacer(),
                Text('10', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 범례
          const Row(
            children: [
              SizedBox(width: 12),
              Text('평온'),
              Spacer(),
              Text('보통'),
              Spacer(),
              Text('불안'),
              SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }
}
