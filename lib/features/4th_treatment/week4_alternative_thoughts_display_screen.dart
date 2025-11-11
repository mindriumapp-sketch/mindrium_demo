import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/features/4th_treatment/week4_after_agreement_screen.dart';

class Week4AlternativeThoughtsDisplayScreen extends StatefulWidget {
  final List<String> alternativeThoughts;
  final String previousB;
  final int beforeSud;
  final List<String> remainingBList;
  final List<String> allBList;
  final List<String>? existingAlternativeThoughts;
  final bool isFromAnxietyScreen;
  final List<String> originalBList;
  final String? abcId;
  final int loopCount;

  const Week4AlternativeThoughtsDisplayScreen({
    super.key,
    required this.alternativeThoughts,
    required this.previousB,
    required this.beforeSud,
    required this.remainingBList,
    required this.allBList,
    this.existingAlternativeThoughts,
    this.isFromAnxietyScreen = false,
    this.originalBList = const [],
    this.abcId,
    this.loopCount = 1,
  });

  @override
  State<Week4AlternativeThoughtsDisplayScreen> createState() =>
      _Week4AlternativeThoughtsDisplayScreenState();
}

class _Week4AlternativeThoughtsDisplayScreenState
    extends State<Week4AlternativeThoughtsDisplayScreen> {
  bool _isNextEnabled = false;
  int _secondsLeft = 5;
  bool _showMainText = true;

  List<String> _removeDuplicates(List<String> list) {
    final uniqueList = <String>[];
    for (final item in list) {
      if (!uniqueList.contains(item)) {
        uniqueList.add(item);
      }
    }
    return uniqueList;
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      if (_secondsLeft > 0) {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return false;
        setState(() => _secondsLeft--);
        return true;
      } else {
        setState(() => _isNextEnabled = true);
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    final hasAlt = widget.alternativeThoughts.isNotEmpty;

    final mainText =
        hasAlt
            ? "'${widget.previousB}' 생각에 대해 '${widget.alternativeThoughts.join(', ')}' (이)라는 도움이 되는 생각을 작성해주셨네요. \n\n잘 진행해주시고 계십니다!"
            : "'${widget.previousB}' 생각에 대한\n도움이 되는 생각들을 확인해보세요.";

    final subText =
        '도움이 되는 생각을 해봤을 때, 처음 들었던 불안한 생각을\n'
        '얼마나 강하게 믿고 있는지 다시 한번 평가해볼게요.';

    return ApplyDesign(
      appBarTitle: '4주차 - 인지 왜곡 찾기',
      cardTitle: '도움이 되는 생각 점검',
      onBack: () => Navigator.pop(context),
      onNext:
          _isNextEnabled
              ? () {
                if (_showMainText) {
                  setState(() => _showMainText = false);
                } else {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (_, __, ___) => Week4AfterAgreementScreen(
                            previousB: widget.previousB,
                            beforeSud: widget.beforeSud,
                            remainingBList: widget.remainingBList,
                            allBList: widget.allBList,
                            alternativeThoughts: _removeDuplicates([
                              ...?widget.existingAlternativeThoughts,
                              ...widget.alternativeThoughts,
                            ]),
                            isFromAnxietyScreen: widget.isFromAnxietyScreen,
                            originalBList: widget.originalBList,
                            existingAlternativeThoughts: _removeDuplicates([
                              ...?widget.existingAlternativeThoughts,
                              ...widget.alternativeThoughts,
                            ]),
                            abcId: widget.abcId,
                            loopCount: widget.loopCount,
                          ),
                    ),
                  );
                }
              }
              : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💬 메인 or 서브 텍스트 전환
          const SizedBox(height: 8),
          Image.asset(
            'assets/image/think_blue.png',
            height: 160,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              _showMainText ? mainText : subText,
              key: ValueKey(_showMainText),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.6,
                letterSpacing: 0.2,
                fontFamily: 'Noto Sans KR',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 36),

          // ⏳ 카운트다운 표시
          if (!_isNextEnabled)
            Text(
              '$_secondsLeft초 후에 다음 단계로 이동할 수 있어요',
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFFB0B0B0),
                fontWeight: FontWeight.w400,
                fontFamily: 'Noto Sans KR',
              ),
            ),
        ],
      ),
    );
  }
}
