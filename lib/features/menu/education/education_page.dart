// 🌊 Mindrium EducationPage — MemoSheet + CustomPopup + **하이라이트 박스 적용**
import 'package:flutter/material.dart';
import 'package:gad_app_team/data/education_model.dart';
import 'package:gad_app_team/widgets/memo_sheet_design.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
// import 'package:gad_app_team/utils/edu_progress.dart';

class EducationPage extends StatefulWidget {
  final List<String> jsonPrefixes; // ex. ['week1_', 'week1b_']
  final Widget Function()? nextPageBuilder;
  final String? title;
  final bool isRelax;
  final String? imagePath;

  const EducationPage({
    super.key,
    required this.jsonPrefixes,
    this.nextPageBuilder,
    this.title,
    this.isRelax = false,
    this.imagePath,
  });

  @override
  State<EducationPage> createState() => _EducationPageState();
}

class _EducationPageState extends State<EducationPage> {
  final PageController _pageController = PageController();

  List<EducationContent> contents = [];
  bool isLoading = true;
  int currentIndex = 0;
  int prefixIndex = 0;
  int partIndex = 1;
  bool hasNextPart = true;

  @override
  void initState() {
    super.initState();
    _loadEducationContent();
  }

  /// ✅ 교육 JSON 파일 불러오기
  Future<void> _loadEducationContent() async {
    try {
      setState(() => isLoading = true);

      final prefix = widget.jsonPrefixes[prefixIndex];
      final path = "assets/education_data/$prefix$partIndex.json";
      final data = await EducationDataLoader.loadContents(path);

      final nextPath = "assets/education_data/$prefix${partIndex + 1}.json";
      final hasMoreInCurrentPrefix = await EducationDataLoader.fileExists(
        nextPath,
      );

      setState(() {
        contents = data;
        isLoading = false;
        currentIndex = 0;
        hasNextPart =
            hasMoreInCurrentPrefix ||
            (prefixIndex < widget.jsonPrefixes.length - 1);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    } catch (e) {
      debugPrint("❌ Error loading education content: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ 다음 part 혹은 prefix로 이동
  Future<void> _loadNextPartOrPrefix() async {
    final prefix = widget.jsonPrefixes[prefixIndex];
    final nextPath = "assets/education_data/$prefix${partIndex + 1}.json";
    final hasMore = await EducationDataLoader.fileExists(nextPath);

    if (hasMore) {
      partIndex++;
    } else if (prefixIndex < widget.jsonPrefixes.length - 1) {
      prefixIndex++;
      partIndex = 1;
    } else {
      _showNextDialog();
      return;
    }

    await _loadEducationContent();
  }

  /// ✅ 이전 part로 이동
  void _goToPreviousPart() {
    if (partIndex > 1) {
      partIndex--;
    } else if (prefixIndex > 0) {
      prefixIndex--;
      partIndex = 1;
    } else {
      return;
    }
    _loadEducationContent();
  }

  /// ✅ 다음 단계 다이얼로그 (완료 or Relax 시작)
  void _showNextDialog() {
    if (widget.nextPageBuilder == null) {
      if (!widget.isRelax) {
        _showCompleteDialog();
      } else {
        _showStartDialog();
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.nextPageBuilder!()),
      );
    }
  }

  /// 🪸 교육 완료 다이얼로그 — CustomPopupDesign
  void _showCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CustomPopupDesign(
            title: '교육 완료',
            message: '교육이 완료되었습니다.',
            positiveText: '닫기',
            negativeText: '취소',
            backgroundAsset: null,
            iconAsset: null,
            onNegativePressed: () => Navigator.pop(context),
            onPositivePressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
            },
          ),
    );
  }


  /// 🧘 이완 교육 다이얼로그 — CustomPopupDesign(확인 단일 버튼)
  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CustomPopupDesign(
            title: '이완 음성 안내 시작',
            message: '잠시 후, 이완을 위한 음성 안내가 시작됩니다.\n주변 소리와 음량을 조절해보세요.',
            positiveText: '확인',
            negativeText: null,
            backgroundAsset: null,
            iconAsset: null,
            onPositivePressed: () async {
              //await EduProgress.markWeekDone(1);
              Navigator.pop(context);
              Navigator.pushReplacementNamed(
                context,
                '/relaxation_education',
                arguments: {
                  'taskId': 'edu_0001',
                  'weekNumber': 1,
                  'mp3Asset': 'week1.mp3',
                  'riveAsset': 'week1.riv',
                },
              );
            },
          ),
    );
  }

  // ====== ⬇⬇⬇ 하이라이트 처리 유틸 ======

  // ✅ Week6 스타일의 하이라이트 박스
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
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  /// '** ... **' 토큰을 찾아 TextSpan + WidgetSpan으로 분해
  List<InlineSpan> _buildSpans(String line, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*'); // non-greedy
    int cursor = 0;

    for (final m in regex.allMatches(line)) {
      if (m.start > cursor) {
        spans.add(
          TextSpan(text: line.substring(cursor, m.start), style: baseStyle),
        );
      }
      final highlighted = m.group(1) ?? '';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _highlightedText(highlighted),
        ),
      );
      cursor = m.end;
    }

    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor), style: baseStyle));
    }
    return spans;
  }

  /// 한 문단(문자열)에 줄바꿈이 포함돼 있으면 줄 단위로 RichText를 여러 개 렌더
  Widget _richParagraph(String text, TextStyle baseStyle) {
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          RichText(text: TextSpan(children: _buildSpans(line, baseStyle))),
      ],
    );
  }

  /// 제목에도 **토큰이 있을 수 있으니 같은 처리
  Widget _richTitle(String text) {
    const titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Color(0xFF232323),
      fontFamily: 'Noto Sans KR',
    );
    return RichText(text: TextSpan(children: _buildSpans(text, titleStyle)));
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.title ?? '교육';

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MemoFullDesign(
      appBarTitle: titleText,
      onBack:
          (currentIndex == 0 && partIndex == 1 && prefixIndex == 0)
              ? () {}
              : (currentIndex == 0
                  ? _goToPreviousPart
                  : () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  }),
      onNext:
          (currentIndex == contents.length - 1)
              ? _loadNextPartOrPrefix
              : () {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },

      /// ✨ 메모지 안의 내용
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) => setState(() => currentIndex = index),
          itemCount: contents.length,
          itemBuilder: (context, index) {
            final content = contents[index];
            const bodyStyle = TextStyle(
              color: Color(0xFF232323),
              fontSize: 14,
              fontFamily: 'Noto Sans KR',
              height: 1.4,
              letterSpacing: 0.2,
            );
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _richTitle(content.title),
                  const SizedBox(height: 16),

                  // 문단들
                  for (final paragraph in content.paragraphs)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _richParagraph(paragraph, bodyStyle),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
