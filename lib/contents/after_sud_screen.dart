import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ✅ ApplyDesign
import 'package:gad_app_team/features/4th_treatment/week4_skip_choice_screen.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/sud_api.dart';
import 'package:gad_app_team/utils/text_line_utils.dart';
import 'package:gad_app_team/data/apply_solve_provider.dart';
import 'package:provider/provider.dart';

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

  Map _args() => ModalRoute.of(context)?.settings.arguments as Map? ?? {};
  String? get _abcId => _args()['abcId'] as String?;
  String? get _origin => _args()['origin'] as String?;
  dynamic get _diary => _args()['diary'];
  String? get _sudId => _args()['sudId'] as String?;

  // ───────────────────── FastAPI 저장 ─────────────────────
  Future<Map<String, dynamic>?> _saveSud() async {
    final abcId = _abcId;
    final sudId = _sudId;
    if (abcId == null || abcId.isEmpty || sudId == null || sudId.isEmpty) {
      return null;
    }

    final res = await _sudApi.updateSudScore(
      diaryId: abcId,
      sudId: sudId,
      afterScore: _sud,
    );
    return res;
  }

  // ───────────────────── 비교 및 분기 ─────────────────────
  Future<void> _compareAndNavigate(Map<String, dynamic> res) async {
    final beforeSud = (res['before_sud'] as num?)?.toInt() ?? _sud;
    final afterSud  = (res['after_sud']  as num?)?.toInt() ?? _sud;

    final args = _args();
    final flow = context.read<ApplyOrSolveFlow>()..syncFromArgs(args);
    final abcId = _abcId ?? flow.diaryId;
    final origin = _origin ?? flow.origin;
    final diaryArg = _diary ?? flow.diary;
    if (abcId != null) flow.setDiaryId(abcId);
    flow.setOrigin(origin);

    if (origin == 'apply') {
      if (!mounted) return;
      if (diaryArg == 'new') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) =>
                    NotificationSelectionScreen(origin: 'apply', abcId: abcId!),
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

    if (!mounted) return;
    if (afterSud < beforeSud) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder:
              (_, __, ___) => Week4SkipChoiceScreen(
                beforeSud: beforeSud,
                allBList: (_args()['allBList'] as List?)?.cast<String>() ?? const [],
                remainingBList: (_args()['remainingBList'] as List?)?.cast<String>() ?? const [],
                existingAlternativeThoughts: (_args()['allAlternativeThoughts'] as List?)
                      ?.cast<String>() ?? const [],
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
      appBarTitle: '불안 평가',
      cardTitle: '활동을 진행한 후,\n느끼는 불안 정도를 선택해 주세요',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        final res = await _saveSud();
        if (!context.mounted) return;
        final args = _args();
        context.read<ApplyOrSolveFlow>().syncFromArgs(args);

        // sudId 없거나 저장 실패 등
        if (res == null) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
          return;
        }
        await _compareAndNavigate(res);
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
            protectKoreanWords(_caption),
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
