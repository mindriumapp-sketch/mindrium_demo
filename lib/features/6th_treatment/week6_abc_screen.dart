import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/features/6th_treatment/week6_concentration_screen.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week6AbcScreen extends StatefulWidget {
  const Week6AbcScreen({super.key});

  @override
  State<Week6AbcScreen> createState() => _Week6AbcScreenState();
}

class _Week6AbcScreenState extends State<Week6AbcScreen> {
  Map<String, dynamic>? _abcModel;
  bool _isLoading = true;
  String? _error;
  late final ApiClient _client;
  late final DiariesApi _diariesApi;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    _fetchLatestDiary();
  }

  Future<void> _fetchLatestDiary() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 최신 일기 불러오기
      final latest = await _diariesApi.getLatestDiary();
      setState(() {
        _abcModel = latest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = '데이터를 불러오지 못했습니다.';
        _isLoading = false;
      });
    }
  }

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
    return ApplyDesign(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      cardTitle: '최근 ABC 모델 확인',
      onBack: () => Navigator.pop(context),
      onNext: () {
        // 일기의 consequence_b (행동 리스트) 추출
        final consequenceB = _abcModel?['consequence_b'] ?? [];
        List<String> behaviorList = [];

        if (consequenceB is List) {
          behaviorList = consequenceB
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (consequenceB is String && consequenceB.isNotEmpty) {
          behaviorList = consequenceB
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => Week6ConcentrationScreen(
              behaviorListInput: behaviorList,
              allBehaviorList: behaviorList,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      /// 🌊 기능 내용 (기존 body → child)
      child: Builder(
        builder: (context) {
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

          final a = _abcModel?['activating_events'] ?? '';
          final bList = _abcModel?['belief'] ?? [];
          final b = bList is List ? bList.join(', ') : (bList.toString());
          final cPhysical = _abcModel?['consequence_p'] ?? [];
          final cPhysicalStr = cPhysical is List ? cPhysical.join(', ') : (cPhysical.toString());
          final cEmotion = _abcModel?['consequence_e'] ?? [];
          final cEmotionStr = cEmotion is List ? cEmotion.join(', ') : (cEmotion.toString());
          final cBehavior = _abcModel?['consequence_b'] ?? [];
          final cBehaviorStr = cBehavior is List ? cBehavior.join(', ') : (cBehavior.toString());
          final userName = Provider.of<UserProvider>(
            context,
            listen: false,
          ).userName;

          String formattedDate = '';
          if (_abcModel?['createdAt'] != null) {
            final createdAt = _abcModel!['createdAt'];
            DateTime date;
            if (createdAt is DateTime) {
              date = createdAt;
            } else if (createdAt is String) {
              date = DateTime.parse(createdAt);
            } else {
              date = DateTime.now();
            }
            formattedDate =
                '${date.year}년 ${date.month}월 ${date.day}일에 작성된 걱정일기';
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (formattedDate.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: "$userName님은 "),
                    WidgetSpan(child: _highlightedText("'$a'")),
                    const TextSpan(text: " 상황에서 "),
                    WidgetSpan(child: _highlightedText("'$b'")),
                    const TextSpan(text: " 생각을 하였습니다.\n\n"),
                    if (cPhysicalStr.isNotEmpty ||
                        cEmotionStr.isNotEmpty ||
                        cBehaviorStr.isNotEmpty) ...[
                      const TextSpan(text: "그 결과 "),
                      if (cPhysicalStr.isNotEmpty) ...[
                        const TextSpan(text: "신체적으로 "),
                        WidgetSpan(child: _highlightedText("'$cPhysicalStr'")),
                        const TextSpan(text: " 증상이 나타났고, "),
                      ],
                      if (cEmotionStr.isNotEmpty) ...[
                        WidgetSpan(child: _highlightedText("'$cEmotionStr'")),
                        const TextSpan(text: " 감정을 느끼셨으며, "),
                      ],
                      if (cBehaviorStr.isNotEmpty) ...[
                        WidgetSpan(child: _highlightedText("'$cBehaviorStr'")),
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
        },
      ),
    );
  }
}
