import 'package:flutter/material.dart';
import 'package:gad_app_team/features/6th_treatment/week6_classfication_screen.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

// ✅ 새로 정의된 디자인 위젯 불러오기
import 'package:gad_app_team/widgets/ruled_paragraph.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';

class Week6ConcentrationScreen extends StatefulWidget {
  final List<String> behaviorListInput;
  final List<String> allBehaviorList;

  const Week6ConcentrationScreen({
    super.key,
    required this.behaviorListInput,
    required this.allBehaviorList,
  });

  @override
  State<Week6ConcentrationScreen> createState() =>
      _Week6ConcentrationScreenState();
}

class _Week6ConcentrationScreenState extends State<Week6ConcentrationScreen> {
  bool _isNextEnabled = false;
  int _secondsLeft = 10;
  Map<String, dynamic>? _diary;
  bool _isLoading = true;
  bool _showSituation = true;
  late final ApiClient _client;
  late final DiariesApi _diariesApi;

  @override
  void initState() {
    super.initState();
    _client = ApiClient(tokens: TokenStorage());
    _diariesApi = DiariesApi(_client);
    _startCountdown();
    _fetchLatestDiary();
  }

  Future<void> _fetchLatestDiary() async {
    try {
      // 최신 일기 불러오기
      final latest = await _diariesApi.getLatestDiary();
      setState(() {
        _diary = latest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _diary = null;
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (_secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return false;
        setState(() {
          _secondsLeft--;
        });
        return true;
      } else {
        setState(() {
          _isNextEnabled = true;
        });
        return false;
      }
    });
  }

  String _getFirstBehavior(dynamic behavior) {
    if (behavior == null) return '';
    if (behavior is String) {
      final parts =
          behavior
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      return parts.isNotEmpty ? parts.first : '';
    }
    if (behavior is List) {
      return behavior.isNotEmpty ? behavior.first.toString() : '';
    }
    final parts =
        behavior
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
    return parts.isNotEmpty ? parts.first : '';
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    // BlueWhiteCard에서 쓰던 밑줄 길이를 그대로 사용
    const double kRuleWidth = 220;

    return ApplyDesign(
      appBarTitle: '6주차 - 불안 직면 VS 회피',
      cardTitle: '상황에 집중하기',
      onBack: () => Navigator.pop(context),
      onNext: () {
            if (!_isNextEnabled) {
              BlueBanner.show(context, '$_secondsLeft초 후에 다음 버튼이 활성화됩니다');
              return;
            }
            if (_showSituation) {
              setState(() => _showSituation = false);
            } else {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder:
                      (_, __, ___) => Week6ClassificationScreen(
                    behaviorListInput: widget.allBehaviorList,
                    allBehaviorList: widget.allBehaviorList,
                  ),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8,),
                  Image.asset(
                    'assets/image/think_blue.png',
                    height: 160,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 20),
                  RuledParagraph(
                    text: _showSituation
                        ? _diary != null
                        ? '$userName님, "${_diary!['activating_events'] ?? ''}" (이)라는 상황에서\n'
                        '"${_getFirstBehavior(_diary!['consequence_b'])}"(이)라고 행동을 하였습니다.\n\n그때의 상황에 집중해보세요.'
                        : '이때의 상황을 자세히 떠올려보세요.'
                        : '앞서 보셨던 행동이 불안을 \n직면한 행동인지, 회피한 행동인지 함께 살펴볼게요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2C3C55),
                      height: 1.6,
                    ),
                    lineColor: Color(0xFFE1E8F0),
                    lineThickness: 1.2,
                    lineGapBelow: 8,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    lineWidth: kRuleWidth,
                  ),
                  const SizedBox(height: 16),
                  if (!_isNextEnabled)
                    Text(
                      '$_secondsLeft초 후에 다음 버튼이 활성화됩니다',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9BA7B4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
    );
  }
}
