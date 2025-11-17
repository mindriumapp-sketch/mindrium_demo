// 🔹 SUD(불안 정도) 입력 및 저장 화면
// 사용자가 0~10 점수 선택 → Firestore 저장 → 점수에 따라 다음 화면 이동
// Mindrium 공통 ApplyDesign 사용 (튜토리얼 카드형 레이아웃)

// ─────────────────────────  FLUTTER  ─────────────────────────
import 'package:flutter/material.dart';

// ────────────────────────  PACKAGES  ────────────────────────
import 'package:dio/dio.dart';

// ───────────────────────────  LOCAL  ────────────────────────
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ★ ApplyDesign 가져오기
import 'package:gad_app_team/data/storage/token_storage.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/api/sud_api.dart';

/// SUD(0‒10)을 입력받아 저장하고, 점수에 따라 후속 행동을 안내하는 화면
class BeforeSudRatingScreen extends StatefulWidget {
  final String? abcId;
  const BeforeSudRatingScreen({super.key, this.abcId});

  @override
  State<BeforeSudRatingScreen> createState() => _BeforeSudRatingScreenState();
}

class _BeforeSudRatingScreenState extends State<BeforeSudRatingScreen> {
  int _sud = 5; // 슬라이더 값 (0‒10)
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);
  late final SudApi _sudApi = SudApi(_apiClient);
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[SUD] arguments = ${widget.abcId}');
  }

  // ────────────────────── FastAPI 저장 ──────────────────────
  Future<void> _saveSud(String? abcId) async {
    if (abcId == null || abcId.isEmpty) return;
    final access = await _tokens.access;
    if (access == null) {
      throw Exception('로그인이 필요합니다.');
    }

    await _sudApi.createSudScore(
      diaryId: abcId,
      beforeScore: _sud,
      afterScore: _sud,
    );
  }


  Future<String> _loadGroupId(String abcId) async {
    try {
      final diary = await _diariesApi.getDiary(abcId);
      final dynamic raw = diary['group_Id'] ?? diary['groupId'];
      return raw == null ? '' : raw.toString();
    } on DioException catch (_) {
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<bool> _hasAccessToken() async {
    final access = await _tokens.access;
    return access != null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    });
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
        if (_saving) return;
        setState(() => _saving = true);

        try {
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

          final isLoggedIn = await _hasAccessToken();
          if (!isLoggedIn) {
            _showSnack('로그인 정보가 없습니다.');
            return;
          }

          if (!hasAbcId) {
            _showSnack('기록 정보를 찾을 수 없습니다. 다시 시도해 주세요.');
            return;
          }

          final ensuredAbcId = abcId!;
          final groupId = await _loadGroupId(ensuredAbcId);
          if (!context.mounted) return;

          if (_sud > 2) {
            Navigator.pushReplacementNamed(
              context,
              '/similar_activation',
              arguments: {'abcId': ensuredAbcId, 'groupId': groupId, 'sud': _sud},
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
        } on DioException catch (e) {
          final message =
              e.response?.data is Map ? e.response?.data['detail']?.toString() : e.message;
          _showSnack('SUD를 저장하지 못했습니다: ${message ?? '알 수 없는 오류'}');
        } catch (e) {
          _showSnack('SUD를 저장하지 못했습니다: $e');
        } finally {
          if (mounted) setState(() => _saving = false);
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
