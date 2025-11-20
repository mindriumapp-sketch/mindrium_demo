import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ✅ ApplyDesign
import 'package:gad_app_team/features/4th_treatment/week4_skip_choice_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/api/sud_api.dart';

class AfterSudRatingScreen extends StatefulWidget {
  const AfterSudRatingScreen({super.key});

  @override
  State<AfterSudRatingScreen> createState() => _AfterSudRatingScreenState();
}

class _AfterSudRatingScreenState extends State<AfterSudRatingScreen> {
  int _sud = 5;
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final SudApi _sudApi = SudApi(_apiClient);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  Map _args() => ModalRoute.of(context)?.settings.arguments as Map? ?? {};
  String? get _abcId => _args()['abcId'] as String?;
  String? get _origin => _args()['origin'] as String?;
  dynamic get _diary => _args()['diary'];

  // ───────────────────── FastAPI 저장 ─────────────────────
  Future<void> _saveSud() async {
    final abcId = _abcId;
    if (abcId == null || abcId.isEmpty) return;
    await _sudApi.createSudScore(
      diaryId: abcId,
      beforeScore: _sud,
      afterScore: _sud,
    );
  }

  // ───────────────────── 비교 및 분기 ─────────────────────
  Future<void> _compareAndNavigate() async {
    final abcId = _abcId;
    final origin = _origin;
    final diaryArg = _diary;

    if (origin == 'apply') {
      if (!mounted) return;
      if (diaryArg == 'new') {
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

    final diaryData = await _diariesApi.getDiary(abcId);
    final scores = diaryData['sudScores'] as List<dynamic>? ?? const [];
    scores.sort((a, b) {
      final da = DateTime.tryParse(a['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(b['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    final latest = scores.isNotEmpty ? scores.first : null;
    final beforeSud = latest?['before_sud'] as num? ?? _sud;
    final afterSud = latest?['after_sud'] as num? ?? _sud;

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
              inactiveTrackColor: _accent.withValues(alpha: 0.25),
              thumbColor: _accent,
              overlayColor: _accent.withValues(alpha: 0.2),
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
