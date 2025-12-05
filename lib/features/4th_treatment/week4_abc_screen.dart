// lib/features/4th_treatment/week4_abc_screen.dart
import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:provider/provider.dart';

import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/4th_treatment/week4_imagination_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_concentration_screen.dart';
import 'package:gad_app_team/features/4th_treatment/week4_before_sud_screen.dart';

// ✅ 튜토리얼/적용하기 공용 레이아웃 (BlueWhiteCard 기반)
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ApplyDesign
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

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
  late final ApiClient _client;
  late final DiariesApi _diariesApi;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    // 요구사항: 항상 "가장 최근" 일기를 기준으로 시작
    // (abcId가 전달되더라도 이 화면에서는 최신 일기 우선)
    _fetchLatestDiary();
  }

  Future<void> _fetchLatestDiary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 서버에서 마지막 일기를 바로 반환
      final latest = await _diariesApi.getLatestDiary();
      setState(() {
        _abcModel = latest;
        _bList = _parseBeliefToList(latest['belief']);
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

  String _chipLabel(dynamic raw) {
    if (raw == null) return '';
    if (raw is Map) {
      return (raw['label'] ?? '').toString();
    }
    return raw.toString();
  }

  String _chipText(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => _chipLabel(e).trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
    }
    return _chipLabel(raw).trim();
  }

  List<String> _parseBeliefToList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => _chipLabel(e).trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final s = _chipLabel(raw);
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
      appBarTitle: '인지 왜곡 찾기',
      cardTitle: '최근 걱정 일기 확인',
      onBack: () => Navigator.pop(context),
      onNext: () {
        // 항상 현재 화면에서 로드한 최신 일기의 ID를 사용
        final id =
            (_abcModel?['diary_id'] ?? _abcModel?['diaryId'])?.toString();

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

        // SUD(before)가 없는 경우 먼저 4주차 전용 Before SUD 화면으로 이동
        if (sud == null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder:
                  (_, __, ___) =>
                      Week4BeforeSudScreen(loopCount: widget.loopCount),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
          return;
        }

        setState(() => _isLoading = true);
        final beforeSudValue = sud;

        if (_bList.isEmpty) {
          setState(() => _isLoading = false);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('B(생각) 데이터가 없습니다.')));
          return;
        }

        setState(() => _isLoading = false);
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) => Week4ConcentrationScreen(
                  bListInput: _bList,
                  beforeSud: beforeSudValue,
                  allBList: _bList,
                  abcId: id, // 최신 일기의 ID 전달
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
        child: Text('최근에 작성한 ABC모델이 없습니다.', style: TextStyle(fontSize: 16)),
      );
    }

    String safe(String text) {
      try {
        // replaces ill-formed UTF-16 sequences with � to avoid TextSpan crashes
        return String.fromCharCodes(text.runes);
      } catch (_) {
        return '';
      }
    }

    final a = safe(_chipText(
      _abcModel?['activation'] ??
          _abcModel?['activating_events'] ??
          _abcModel?['activatingEvent'],
    ));
    // belief는 리스트일 수 있음 → 표시용으로 쉼표 연결
    final b = safe(_chipText(_abcModel?['belief']));
    final cPhysical = safe(_chipText(
      _abcModel?['consequence_physical'] ?? _abcModel?['consequence_p'],
    ));
    final cEmotion = safe(_chipText(
      _abcModel?['consequence_emotion'] ?? _abcModel?['consequence_e'],
    ));
    final cBehavior = safe(_chipText(
      _abcModel?['consequence_action'] ??
          _abcModel?['consequence_behavior'] ??
          _abcModel?['consequence_b'],
    ));
    final userName = Provider.of<UserProvider>(context, listen: false).userName;

    // 날짜
    String formattedDate = '';
    final createdAt = _abcModel?['created_at'] ?? _abcModel?['createdAt'];
    if (createdAt != null) {
      final DateTime date =
          createdAt is DateTime
              ? createdAt
              : DateTime.tryParse(createdAt.toString()) ?? DateTime.now();
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
                '최근에 작성하신 ABC 걱정일기를 확인해 볼까요?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 📄 본문 (Week6와 동일한 문장 구성/하이라이트)
        Text.rich(
          TextSpan(
            children: () {
              final spans = <InlineSpan>[
                TextSpan(text: "$userName님은 "),
                WidgetSpan(child: _highlightedText("'$a'")),
                const TextSpan(text: " 상황에서 "),
                WidgetSpan(child: _highlightedText("'$b'")),
                const TextSpan(text: " 생각을 하였습니다."),
              ];

              final hasC = cPhysical.isNotEmpty || cEmotion.isNotEmpty || cBehavior.isNotEmpty;
              if (hasC) {
                spans.add(const TextSpan(text: " 그 결과 "));
                if (cPhysical.isNotEmpty) {
                  spans.addAll([
                    const TextSpan(text: "신체적으로 "),
                    WidgetSpan(child: _highlightedText("'$cPhysical'")),
                    const TextSpan(text: " 증상이 나타났고, "),
                  ]);
                }
                if (cEmotion.isNotEmpty) {
                  spans.addAll([
                    WidgetSpan(child: _highlightedText("'$cEmotion'")),
                    const TextSpan(text: " 감정을 느끼셨으며, "),
                  ]);
                }
                if (cBehavior.isNotEmpty) {
                  spans.addAll([
                    WidgetSpan(child: _highlightedText("'$cBehavior'")),
                    const TextSpan(text: " 행동을 하였습니다."),
                  ]);
                }
              }
              return spans;
            }(),
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
