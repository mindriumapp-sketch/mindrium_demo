// ─────────────────────────  FLUTTER  ─────────────────────────
import 'package:flutter/material.dart';

// ────────────────────────  PACKAGES  ────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// ───────────────────────────  LOCAL  ────────────────────────
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/icon_label.dart';

/// SUD(0‒10)을 입력받아 저장하고, 점수에 따라 후속 행동을 안내하는 화면
class RelaxationScoreScreen extends StatefulWidget {

  const RelaxationScoreScreen({super.key});

  @override
  State<RelaxationScoreScreen> createState() => _RelaxationScoreScreenState();
}

class _RelaxationScoreScreenState extends State<RelaxationScoreScreen> {
  int _relax = 10; // 슬라이더 값 (0‒10)

  // ────────────────────── Firestore 저장 ──────────────────────
  Future<void> _saveRelax() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId   = args['abcId'] as String?;
    if (uid == null) return; // 로그인하지 않은 경우

    final pos = await _getCurrentPosition(); // 위치 권한 없으면 null
    await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('abc_models')
      .doc(abcId)
      .collection('relax_score')
      .add({
        'relax_score': _relax,
        'createdAt': FieldValue.serverTimestamp(),
        if (pos != null) 'latitude': pos.latitude,
        if (pos != null) 'longitude': pos.longitude,
      });
  }

  /// 현재 위치 가져오기 (권한 거부 시 null)
  Future<Position?> _getCurrentPosition() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        return Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.low),
        );
      }
    } catch (_) {
      // 위치를 얻지 못해도 무시
    }
    return null;
  }

  // ────────────────────────── UI ──────────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final String? abcId   = args['abcId'] as String?;

    final trackColor = _relax <= 3
        ? Colors.red
        : _relax >= 7
            ? Colors.green
              : Colors.amber;

    return Scaffold(
      appBar: const CustomAppBar(title: '이완 점수'),
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.padding, vertical: 8),
          child: NavigationButtons(
              leftLabel: '이전',
              rightLabel: '저장',
              onBack: () => Navigator.pop(context),
              onNext: () async {
                // 1) 점수 저장
                await _saveRelax();

                if (!context.mounted) return;
                // 2) 사용자 completed_education 읽기
                final uid = FirebaseAuth.instance.currentUser?.uid;
                int completed = 0;
                if (uid != null) {
                  final snap = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get();
                  completed = (snap.data()?['completed_education'] ?? 0) as int;
                }

                debugPrint('[relaxation_score] completed_education=$completed (abcId=$abcId)');

                // 3) completed_education >= 4 → 대체생각, else after_sud
                if (!context.mounted) return;
                if (args['origin'] == 'apply') {
                  if (completed >= 4) {
                    Navigator.pushNamed(
                      context,
                      '/apply_alt_thought',
                      arguments: {
                        'abcId': abcId,
                        'diary': args['diary'],
                      },
                    );
                  } else {
                    Navigator.pushNamed(
                      context,
                      '/after_sud',
                      arguments: {
                        'abcId': abcId,
                        'diary': args['diary'],
                      },
                    );
                  }
                  return;
                } else {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                }
              }),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '지금 느껴지는 몸의 이완 정도를 슬라이드로 선택해 주세요.',
                  style:TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // ── 현재 점수 (숫자) ──
                Center(
                  child: Text(
                    '$_relax',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: trackColor,
                    ),
                  ),
                ),

                // ── 큰 이모티콘 ──
                Icon(
                  _relax <= 3
                      ? Icons.sentiment_very_dissatisfied_sharp
                      : _relax >= 7
                          ? Icons.sentiment_very_satisfied
                            : Icons.sentiment_neutral,
                  size: 160,
                  color: trackColor,
                ),

                // ── 슬라이더 + 아이콘 설명 (가로 배치) ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── 세로 슬라이더 ──
                    SizedBox(
                      height: 352,
                      child: Column(
                        children: [
                          const Text('10',
                              style: TextStyle(fontSize: 20, color: Colors.black54)),
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: -1,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: trackColor,
                                  thumbColor: trackColor,
                                ),
                                child: Slider(
                                  value: _relax.toDouble(),
                                  min: 0,
                                  max: 10,
                                  divisions: 10,
                                  label: '$_relax',
                                  onChanged: (v) =>
                                      setState(() => _relax = v.round()),
                                ),
                              ),
                            ),
                          ),
                          const Text('0',
                              style: TextStyle(fontSize: 20, color: Colors.black54)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ── 아이콘 + 캡션 세트 ──
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconLabel(
                          icon: Icons.sentiment_very_satisfied,
                          color: Colors.green,
                          label: '이완',
                        ),
                        SizedBox(height: 60),
                        IconLabel(
                          icon: Icons.sentiment_neutral,
                          color: Colors.amber,
                          label: '보통',
                        ),
                        SizedBox(height: 60),
                        IconLabel(
                          icon: Icons.sentiment_very_dissatisfied_sharp,
                          color: Colors.red,
                          label: '긴장',
                        ),
                      ],
                    ),
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