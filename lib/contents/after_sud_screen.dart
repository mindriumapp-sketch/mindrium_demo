import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ✅ ApplyDesign
import 'package:gad_app_team/features/4th_treatment/week4_skip_choice_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';

class AfterSudRatingScreen extends StatefulWidget {
  const AfterSudRatingScreen({super.key});

  @override
  State<AfterSudRatingScreen> createState() => _AfterSudRatingScreenState();
}

class _AfterSudRatingScreenState extends State<AfterSudRatingScreen> {
  int _sud = 5;

  Map _args() => ModalRoute.of(context)?.settings.arguments as Map? ?? {};
  String? get _abcId => _args()['abcId'] as String?;
  String? get _origin => _args()['origin'] as String?;
  dynamic get _diary => _args()['diary'];

  // ───────────────────── Firestore 저장 ─────────────────────
  Future<void> _saveSud() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final abcId = _abcId;
    if (uid == null || abcId == null || abcId.isEmpty) return;

    final sudRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(abcId)
        .collection('sud_score');

    final payload = {
      'after_sud': _sud,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final snap =
        await sudRef.orderBy('updatedAt', descending: true).limit(1).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update(payload);
    } else {
      await sudRef.add(payload);
    }
  }

  // ───────────────────── 비교 및 분기 ─────────────────────
  Future<void> _compareAndNavigate() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final abcId = _abcId;
    final origin = _origin;
    final diary = _diary;

    if (origin == 'apply') {
      if (!mounted) return;
      if (diary == 'new') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    NotificationSelectionScreen(origin: 'apply', abcId: abcId),
          ),
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      }
      return;
    }

    if (abcId == null || abcId.isEmpty) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      return;
    }

    final sudCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(abcId)
        .collection('sud_score');

    final latest =
        await sudCol.orderBy('updatedAt', descending: true).limit(1).get();
    final data = latest.docs.first.data();
    final beforeSud = (data['before_sud'] ?? 0) as num;
    final afterSud = (data['after_sud'] ?? _sud) as num;

    if (!mounted) return;
    if (afterSud < beforeSud) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (_, __, ___) => Week4SkipChoiceScreen(
                beforeSud: beforeSud.toInt(),
                allBList:
                    (_args()['allBList'] as List?)?.cast<String>() ?? const [],
                remainingBList:
                    (_args()['remainingBList'] as List?)?.cast<String>() ??
                    const [],
                existingAlternativeThoughts:
                    (_args()['allAlternativeThoughts'] as List?)
                        ?.cast<String>() ??
                    const [],
                abcId: abcId,
                isFromAfterSud: true,
              ),
        ),
      );
    }
  }

  // ───────────────────── 색상 / 문구 유틸 ─────────────────────
  static const _green = Color(0xFF4CAF50);
  static const _yellow = Color(0xFFFFC107);
  static const _red = Color(0xFFF44336);

  Color get _accent {
    if (_sud <= 2) return _green;
    if (_sud <= 7) return _yellow;
    return _red;
  }

  String get _caption {
    if (_sud <= 2) return '평온해요';
    if (_sud <= 4) return '약간 불안해요';
    if (_sud <= 6) return '조금 불안해요';
    if (_sud <= 8) return '불안해요';
    return '많이 불안해요';
  }

  // ───────────────────── UI ─────────────────────
  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: 'SUD 평가 (after)',
      cardTitle: '대체 생각을 한 후,\n지금의 불안 정도를 선택해 주세요',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        await _saveSud();
        if (!context.mounted) return;
        await _compareAndNavigate();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_sud',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
          const SizedBox(height: 8),
          Icon(
            _sud <= 2
                ? Icons.sentiment_very_satisfied
                : _sud >= 8
                ? Icons.sentiment_very_dissatisfied_sharp
                : Icons.sentiment_neutral,
            size: 120,
            color: _accent,
          ),
          const SizedBox(height: 6),
          Text(
            _caption,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: const RoundedRectSliderTrackShape(),
              trackHeight: 14,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
              activeTrackColor: _accent,
              inactiveTrackColor: _accent.withOpacity(0.25),
              thumbColor: _accent,
              overlayColor: _accent.withOpacity(0.2),
            ),
            child: Slider(
              value: _sud.toDouble(),
              min: 0,
              max: 10,
              label: '$_sud',
              onChanged: (v) => setState(() => _sud = v.round()),
            ),
          ),
          const Row(
            children: [
              Text('불안하지 않음', style: TextStyle(color: Colors.black87)),
              Spacer(),
              Text('불안함', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
