// ─────────────────────────  FLUTTER  ─────────────────────────
import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:gad_app_team/utils/text_line_utils.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/relaxation_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/apply_solve_provider.dart';

/// SUD(0‒10)을 입력받아 저장하고, 점수에 따라 후속 행동을 안내하는 화면
class RelaxationScoreScreen extends StatefulWidget {
  const RelaxationScoreScreen({super.key});

  @override
  State<RelaxationScoreScreen> createState() => _RelaxationScoreScreenState();
}

class _RelaxationScoreScreenState extends State<RelaxationScoreScreen> {
  int _relax = 10; // 슬라이더 값 (0‒10)
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final RelaxationApi _relaxationApi = RelaxationApi(_apiClient);

  // ────────────────────── Mongo 저장 ──────────────────────
  Future<bool> _saveRelax(String? relaxId) async {
    if (relaxId == null || relaxId.isEmpty) {
      debugPrint('[relaxation_score] relaxId is null or empty, skip save');
      return false;
    }

    try {
      await _relaxationApi.updateRelaxationScore(
        relaxId: relaxId,
        relaxationScore: _relax.toDouble(),
      );
      debugPrint(
        '[relaxation_score] updateRelaxationScore success (id=$relaxId, score=$_relax)',
      );
      return true;
    } catch (e) {
      debugPrint('[relaxation_score] updateRelaxationScore error: $e');
      // 저장 실패해도 플로우 자체는 진행시킬 거면 여기서 false만 리턴
      return false;
    }
  }

  /// 점수에 따른 캡션 (기존 텍스트 그대로 활용: 이완 / 보통 / 긴장)
  String get _caption {
    if (_relax <= 3) return '긴장';
    if (_relax >= 7) return '이완';
    return '보통';
  }

  // ────────────────────────── UI ──────────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final flow = context.read<ApplyOrSolveFlow>()
      ..syncFromArgs(args, override: true, notify: false);
    final String? abcId = args['taskId'] as String? ?? flow.diaryId;
    final String? relaxId = args['relaxId'] as String?;
    final String origin = args['origin'] as String? ?? flow.origin;

    final userProvider = context.watch<UserProvider>();
    final int currentWeek = userProvider.currentWeek;
    final bool isWeek4OrAbove = currentWeek >= 4;

    // 🔥 기존 색 로직 그대로 유지
    final trackColor = _relax <= 3
        ? Colors.red
        : _relax >= 7
        ? Colors.green
        : Colors.amber;

    return ApplyDesign(
      appBarTitle: '이완 점수',
      // 🔥 기존 설명 텍스트 그대로
      cardTitle: '지금 느껴지는 몸의 이완 정도를 슬라이드로 선택해 주세요.',
      onBack: () => Navigator.pop(context),
      onNext: () async {
        // 1) 점수 저장
        await _saveRelax(relaxId);
        if (!context.mounted) return;

        // 2) completed_education >= 4 → 대체생각, else after_sud
        if (origin == 'apply') {
          if (isWeek4OrAbove) {
            Navigator.pushNamed(
              context,
              '/apply_alt_thought',
              arguments: {
                ...flow.toArgs(),
                'abcId': abcId,
                'diary': args['diary'],
                'beforeSud': args['beforeSud'],
                'sudId': args['sudId']
              },
            );
          } else {
            Navigator.pushNamed(
              context,
              '/after_sud',
              arguments: {
                ...flow.toArgs(),
                'abcId': abcId,
                'diary': args['diary'],
                'beforeSud': args['beforeSud'],
                'sudId': args['sudId']
              },
            );
          }
          return;
        }

        if (origin == 'solve') {
          Navigator.pushNamed(
            context,
            '/alt_yes_or_no',
            arguments: {
              ...flow.toArgs(),
              'abcId': abcId,
              'diary': args['diary'],
              'beforeSud': args['beforeSud'],
              'sudId': args['sudId']
            },
          );
          return;
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      },

      // ─── 카드 내부 콘텐츠 (BeforeSud 구조에 맞춤) ───
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 현재 점수(숫자)
          Text(
            '$_relax',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w900,
              color: trackColor,
            ),
          ),
          const SizedBox(height: 8),

          // 큰 아이콘 (기존 조건 그대로)
          Icon(
            _relax <= 3
                ? Icons.sentiment_very_dissatisfied_sharp
                : _relax >= 7
                ? Icons.sentiment_very_satisfied
                : Icons.sentiment_neutral,
            size: 120,
            color: trackColor,
          ),
          const SizedBox(height: 6),

          // 캡션 (이완 / 보통 / 긴장)
          Text(
            protectKoreanWords(_caption),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // ── 슬라이더 (가로, 색 변화 로직 그대로) ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackShape: const RoundedRectSliderTrackShape(),
                  trackHeight: 14,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 13,
                    elevation: 2,
                    pressedElevation: 4,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                  tickMarkShape: SliderTickMarkShape.noTickMark,
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                  activeTrackColor: trackColor,
                  inactiveTrackColor: trackColor.withValues(alpha: 0.22),
                  thumbColor: trackColor,
                  overlayColor: trackColor.withValues(alpha: 0.16),
                  showValueIndicator: ShowValueIndicator.onDrag,
                  valueIndicatorColor: trackColor,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: Slider(
                  value: _relax.toDouble(),
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '$_relax',
                  onChanged: (v) => setState(() => _relax = v.round()),
                ),
              ),
              const Row(
                children: [
                  Text(
                    '0',
                    style: TextStyle(color: Colors.black87),
                  ),
                  Spacer(),
                  Text(
                    '10',
                    style: TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
