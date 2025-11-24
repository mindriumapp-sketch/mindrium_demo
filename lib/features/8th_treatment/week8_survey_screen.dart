// File: features/8th_treatment/week8_survey_screen.dart
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'package:gad_app_team/features/8th_treatment/week8_final_screen.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/survey_api.dart';
import 'package:gad_app_team/data/api/users_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week8SurveyScreen extends StatefulWidget {
  const Week8SurveyScreen({super.key});

  @override
  State<Week8SurveyScreen> createState() => _Week8SurveyScreenState();
}

class _Week8SurveyScreenState extends State<Week8SurveyScreen> {
  bool _isLoading = true;
  int? _beforeScore;
  int? _afterScore;
  int? _scoreChange;
  String _userName = '';

  // API 클라이언트
  late final ApiClient _apiClient;
  late final SurveyApi _surveyApi;
  late final UsersApi _usersApi;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(tokens: TokenStorage());
    _surveyApi = SurveyApi(_apiClient);
    _usersApi = UsersApi(_apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadSurveys(), _loadUserName()]);
  }

  Future<void> _loadUserName() async {
    try {
      final me = await _usersApi.me();
      final name = (me['name'] as String?)?.trim();
      if (mounted) {
        setState(() {
          _userName = name?.isNotEmpty == true ? name! : '사용자';
        });
      }
    } catch (e) {
      debugPrint('사용자 이름 로드 실패: $e');
      if (mounted) {
        setState(() {
          _userName = '사용자';
        });
      }
    }
  }

  Future<void> _loadSurveys() async {
    try {
      final surveys = await _surveyApi.getSurveys();
      debugPrint('설문 목록: $surveys');

      // before_survey와 after_survey 찾기
      Map<String, dynamic>? beforeSurvey;
      Map<String, dynamic>? afterSurvey;

      for (final survey in surveys) {
        final type = survey['type']?.toString().toLowerCase();
        debugPrint('설문 type: $type');

        if (type == 'before_survey' || type == 'gad7_pre') {
          beforeSurvey = survey;
          debugPrint('before_survey 찾음: $beforeSurvey');
        } else if (type == 'after_survey' || type == 'gad7_post') {
          afterSurvey = survey;
          debugPrint('after_survey 찾음: $afterSurvey');
        }
      }

      if (beforeSurvey != null) {
        final answers = beforeSurvey['answers'];
        debugPrint(
          'before_survey answers: $answers (type: ${answers.runtimeType})',
        );
        if (answers != null) {
          if (answers is Map) {
            final score = answers['gad7_score'];
            if (score != null) {
              _beforeScore =
                  score is int ? score : int.tryParse(score.toString());
              debugPrint('before_survey gad7_score: $_beforeScore');
            }
          }
        }
      }

      if (afterSurvey != null) {
        final answers = afterSurvey['answers'];
        debugPrint(
          'after_survey answers: $answers (type: ${answers.runtimeType})',
        );
        if (answers != null) {
          if (answers is Map) {
            final score = answers['gad7_score'];
            if (score != null) {
              _afterScore =
                  score is int ? score : int.tryParse(score.toString());
              debugPrint('after_survey gad7_score: $_afterScore');
            }
          }
        }
      }

      if (_beforeScore != null && _afterScore != null) {
        _scoreChange = _afterScore! - _beforeScore!;
      }

      debugPrint(
        '최종 결과: before=$_beforeScore, after=$_afterScore, change=$_scoreChange',
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e, stackTrace) {
      debugPrint('설문 조회 실패: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMessageText() {
    if (_beforeScore == null || _afterScore == null) {
      return '${_userName}님, 정말 수고 많으셨습니다.\n\n'
          '8주간의 Mindrium 교육 프로그램을 끝까지 완주하신 것만으로도 충분히 자랑스러운 일입니다. 이 과정에서 ${_userName}님께서는 불안을 효과적으로 관리할 수 있는 다양한 기법들을 스스로 배우고 실천해오셨습니다.\n\n'
          '때로는 힘들고 지치셨을 수도 있지만, 그럼에도 포기하지 않고 끝까지 함께해주신 ${_userName}님의 노력과 의지가 정말 대단합니다. 이 모든 것은 ${_userName}님 스스로가 선택하고 실천하신 결과입니다.';
    }

    // 점수가 낮아진 경우 (개선)
    if (_scoreChange! < 0) {
      final improvement = _beforeScore! - _afterScore!;
      return '${_userName}님, 정말 축하드립니다!\n\n'
          '8주 전 GAD-7 점수가 ${_beforeScore}점이었는데, 지금은 ${_afterScore}점으로 ${improvement}점이나 낮아졌네요. 이는 ${_userName}님께서 스스로 불안을 마주하고, 배운 기법들을 꾸준히 실천해오신 결과입니다.\n\n'
          '매일의 작은 선택과 노력들이 모여 이렇게 큰 변화를 만들어낸 거예요. ${_userName}님의 인내와 용기가 없었다면 이 성과는 불가능했을 것입니다.\n\n'
          '이 모든 것은 ${_userName}님 스스로가 이루어낸 것입니다. 앞으로도 이 경험을 바탕으로 불안을 더 잘 관리해나가실 수 있을 거예요.';
    }

    // 점수가 높아진 경우 (악화)
    if (_scoreChange! > 0) {
      final increase = _afterScore! - _beforeScore!;
      return '${_userName}님, 8주간 정말 수고 많으셨습니다.\n\n'
          'GAD-7 점수가 ${_beforeScore}점에서 ${_afterScore}점으로 ${increase}점 높아진 것을 보니, 이 기간 동안 ${_userName}님께서 많은 어려움을 겪으셨을 것 같아 마음이 아픕니다.\n\n'
          '하지만 그럼에도 불구하고 ${_userName}님께서는 끝까지 프로그램을 완주하셨고, 불안을 관리하는 다양한 기법들을 스스로 배우고 실천해오셨습니다.\n\n'
          '점수의 변화는 때로는 여러 요인에 의해 일어날 수 있지만, ${_userName}님께서 스스로 선택하고 실천해오신 노력은 결코 무의미하지 않습니다. 이 과정에서 배운 것들이 앞으로 ${_userName}님의 힘이 되어줄 거예요.\n\n'
          '지금의 어려움이 영원하지 않다는 것, 그리고 ${_userName}님 스스로가 변화를 만들어낼 수 있는 힘을 가지고 계시다는 것을 기억해주세요.';
    }

    // 점수 변화가 없는 경우
    return '${_userName}님, 8주간 정말 수고 많으셨습니다.\n\n'
        'GAD-7 점수가 ${_beforeScore}점으로 변화가 없었지만, 이는 결코 실패가 아닙니다. ${_userName}님께서는 이 기간 동안 불안을 효과적으로 관리하는 다양한 기법들을 스스로 배우고, 실천해오셨습니다.\n\n'
        '때로는 변화가 눈에 보이지 않을 수도 있지만, ${_userName}님께서 매일 선택하고 실천하신 작은 노력들은 분명히 ${_userName}님 안에 쌓여가고 있습니다.\n\n'
        '변화는 선형적이지 않아요. 오늘 보이지 않더라도 내일, 모레에는 분명히 나타날 수 있습니다. ${_userName}님께서 스스로 이 과정을 끝까지 완주하신 것만으로도 충분히 자랑스러운 일입니다.\n\n'
        '이 모든 것은 ${_userName}님 스스로가 이루어낸 것이며, 앞으로도 계속해서 ${_userName}님의 힘이 되어줄 거예요.';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ApplyDesign(
        appBarTitle: '8주차 - 불안 평가',
        cardTitle: '불안 평가 비교',
        onBack: () => Navigator.pop(context),
        onNext: null,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return ApplyDesign(
      appBarTitle: '8주차 - 불안 평가',
      cardTitle: '불안 평가 비교',
      onBack: () => Navigator.pop(context),
      onNext:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Week8FinalScreen()),
          ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 축하 이미지
          Image.asset(
            'assets/image/congrats.png',
            height: 160,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 32),
          // 메시지 텍스트
          Text(
            _getMessageText(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 1.5,
              letterSpacing: 0.1,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
