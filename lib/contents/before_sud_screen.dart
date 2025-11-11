// ─────────────────────────  FLUTTER  ─────────────────────────
import 'package:flutter/material.dart';

// ────────────────────────  PACKAGES  ────────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

// ───────────────────────────  LOCAL  ────────────────────────
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ★ ApplyDesign 가져오기

/// SUD(0‒10)을 입력받아 저장하고, 점수에 따라 후속 행동을 안내하는 화면
class BeforeSudRatingScreen extends StatefulWidget {
  final String? abcId;
  const BeforeSudRatingScreen({super.key, this.abcId});

  @override
  State<BeforeSudRatingScreen> createState() => _BeforeSudRatingScreenState();
}

class _BeforeSudRatingScreenState extends State<BeforeSudRatingScreen> {
  int _sud = 5; // 슬라이더 값 (0‒10)

  @override
  void initState() {
    super.initState();
    debugPrint('[SUD] arguments = ${widget.abcId}');
  }

  // ────────────────────── Firestore 저장 ──────────────────────
  Future<void> _saveSud(String? abcId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (abcId == null || abcId.isEmpty) return;

    final pos = await _getCurrentPosition(); // 위치 권한 없으면 null

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(abcId)
        .collection('sud_score')
        .add({
      'before_sud': _sud,
      'after_sud': _sud,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
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
    } catch (_) {}
    return null;
  }

  Future<String> _loadGroupId(String uid, String abcId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('abc_models')
          .doc(abcId)
          .get();
      final data = doc.data();
      if (data == null) return '';
      final dynamic raw = data['group_id'] ?? data['groupId'];
      return raw == null ? '' : raw.toString();
    } catch (_) {
      return '';
    }
  }

  // ────────────────────── 구간/스타일 유틸 ──────────────────────
  static const _green = Color(0xFF4CAF50);
  static const _yellow = Color(0xFFFFC107);
  static const _red = Color(0xFFF44336);

  // 3색 그룹 매핑 (0–2 초록 / 3–7 노랑 / 8–10 빨강)
  Color get _accent {
    if (_sud <= 2) return _green;
    if (_sud <= 7) return _yellow;
    return _red;
  }

  // 캡션
  String get _caption {
    if (_sud <= 2) return '평온해요';
    if (_sud <= 4) return '약간 불안해요';
    if (_sud <= 6) return '조금 불안해요';
    if (_sud <= 8) return '불안해요';
    return '많이 불안해요';
  }

  // ────────────────────────── UI ──────────────────────────
  @override
  Widget build(BuildContext context) {
    final Object? rawArgs = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> args =
    rawArgs is Map ? rawArgs.cast<String, dynamic>() : <String, dynamic>{};

    final String? origin = args['origin'] as String?;
    final dynamic diary = args['diary'];
    final String? routeAbcId = args['abcId'] as String?;
    final String? abcId = widget.abcId ?? routeAbcId;
    final bool hasAbcId = abcId?.isNotEmpty ?? false;

    // ApplyDesign로 상단/본문/하단을 모두 구성 (eduhome.png 배경 포함)
    return ApplyDesign(
      appBarTitle: 'SUD 평가 (before)',
      cardTitle: '지금 느끼는 불안 정도를\n선택해 주세요',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        await _saveSud(abcId);
        if (!context.mounted) return;

        if (!hasAbcId && origin == 'apply') {
          Navigator.pushReplacementNamed(
            context,
            '/diary_yes_or_no',
            arguments: {
              'origin': 'apply',
              if (diary != null) 'diary': diary,
              'beforeSud': _sud,
            },
          );
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인 정보가 없습니다.')),
          );
          return;
        }

        if (!hasAbcId) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('기록 정보를 찾을 수 없습니다. 다시 시도해 주세요.'),
            ),
          );
          return;
        }

        final ensuredAbcId = abcId!;
        final groupId = await _loadGroupId(user.uid, ensuredAbcId);
        if (!context.mounted) return;

        if (_sud > 2) {
          Navigator.pushReplacementNamed(
            context,
            '/similar_activation',
            arguments: {
              'abcId': ensuredAbcId,
              'groupId': groupId,
              'sud': _sud,
            },
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/diary_relax_home',
            arguments: {
              'abcId': ensuredAbcId,
              'groupId': groupId,
              'sud': _sud,
              'origin': origin,
            },
          );
        }
      },

      // ─── 카드 내부 콘텐츠 ───
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 점수(숫자)
          Text(
            '$_sud',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: _accent,
            ),
          ),
          const SizedBox(height: 8),

          // 아이콘
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

          // 캡션
          Text(
            _caption,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // 슬라이더
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  // 알약형 트랙
                  trackShape: const RoundedRectSliderTrackShape(),
                  trackHeight: 14,
                  // 엄지
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 13,
                    elevation: 2,
                    pressedElevation: 4,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                  // 눈금 제거
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                  // 색상
                  activeTrackColor: _accent,
                  inactiveTrackColor: _accent.withOpacity(0.22),
                  thumbColor: _accent,
                  overlayColor: _accent.withOpacity(0.16),
                  // 값 라벨(항상 표시하려면 always)
                  showValueIndicator: ShowValueIndicator.onDrag,
                  valueIndicatorColor: _accent,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
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
              const Row(
                children: [
                  Text('불안하지 않음', style: TextStyle(color: Colors.black87)),
                  Spacer(),
                  Text('불안함', style: TextStyle(color: Colors.black87)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
