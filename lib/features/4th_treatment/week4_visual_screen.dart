import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

class Week4VisualScreen extends StatefulWidget {
  final List<String> previousChips;
  final List<String> alternativeChips;
  final String? abcId;
  const Week4VisualScreen({
    super.key,
    required this.previousChips,
    required this.alternativeChips,
    this.abcId,
  });

  @override
  State<Week4VisualScreen> createState() => _Week4VisualScreenState();
}

class _Week4VisualScreenState extends State<Week4VisualScreen> {
  final List<String> _unhelpfulThoughts = [];
  final List<String> _helpfulThoughts = [];
  final List<String> _remainingThoughts = [];

  @override
  void initState() {
    super.initState();
    // 모든 생각들을 남은 생각 목록에 추가
    _remainingThoughts.addAll(widget.previousChips);
    _remainingThoughts.addAll(widget.alternativeChips);
  }

  void _moveToUnhelpful(String thought) {
    setState(() {
      _remainingThoughts.remove(thought);
      if (!_unhelpfulThoughts.contains(thought)) {
        _unhelpfulThoughts.add(thought);
      }
    });
  }

  void _moveToHelpful(String thought) {
    setState(() {
      _remainingThoughts.remove(thought);
      if (!_helpfulThoughts.contains(thought)) {
        _helpfulThoughts.add(thought);
      }
    });
  }

  void _showColorMismatchDialog(String thought, bool isOriginal) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isOriginal
                            ? const Color(0xFFFFF1F1)
                            : const Color(0xFFE6F9ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOriginal
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color:
                        isOriginal
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF388E3C),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '다시 생각해보세요',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isOriginal
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF388E3C),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isOriginal
                            ? const Color(0xFFFFF1F1)
                            : const Color(0xFFE6F9ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isOriginal
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF388E3C),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    thought,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          isOriginal
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF388E3C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isOriginal
                      ? "이 생각은 붉은색 생각입니다.\n이전 생각 주머니에 넣어주세요."
                      : "이 생각은 초록색 생각입니다.\n이후 생각 주머니에 넣어주세요.",
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isOriginal
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF388E3C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          ),
    );
  }

  void _moveBackToRemaining(String thought, String from) {
    setState(() {
      if (from == 'unhelpful') {
        _unhelpfulThoughts.remove(thought);
      } else if (from == 'helpful') {
        _helpfulThoughts.remove(thought);
      }
      if (!_remainingThoughts.contains(thought)) {
        _remainingThoughts.add(thought);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: const CustomAppBar(title: '4주차 - 인지 왜곡 찾기'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // 상단: 모든 생각들을 칩으로 표시
              Expanded(
                flex: 3,
                child: Card(
                  color: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 헤더 섹션
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.psychology,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '생각 뭉치',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    '생각을 드래그해서 주머니에 넣어보세요',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF666666),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // 생각 카운터
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '남은 생각: ${_remainingThoughts.length}개',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF555555),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 드래그 영역
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFF8F9FF), Color(0xFFF0F2FF)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE8E8FF),
                                width: 1.5,
                              ),
                            ),
                            child:
                                _remainingThoughts.isEmpty
                                    ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF4CAF50),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            '완료!',
                                            style: TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          const Text(
                                            '모든 생각을 분류했습니다',
                                            style: TextStyle(
                                              color: Color(0xFF666666),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : SingleChildScrollView(
                                      padding: const EdgeInsets.all(16),
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children:
                                            _remainingThoughts.map((thought) {
                                              final isOriginal = widget
                                                  .previousChips
                                                  .contains(thought);
                                              return Draggable<String>(
                                                data: thought,
                                                feedback: Material(
                                                  elevation: 12,
                                                  shadowColor: Colors.black
                                                      .withValues(alpha: 0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(18),
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 200,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 14,
                                                          vertical: 10,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          isOriginal
                                                              ? const Color(
                                                                0xFFFFF1F1,
                                                              )
                                                              : const Color(
                                                                0xFFE6F9ED,
                                                              ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            18,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              isOriginal
                                                                  ? const Color(
                                                                    0xFFD32F2F,
                                                                  ).withValues(
                                                                    alpha: 0.3,
                                                                  )
                                                                  : const Color(
                                                                    0xFF388E3C,
                                                                  ).withValues(
                                                                    alpha: 0.3,
                                                                  ),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      thought,
                                                      style: TextStyle(
                                                        color:
                                                            isOriginal
                                                                ? const Color(
                                                                  0xFFD32F2F,
                                                                )
                                                                : const Color(
                                                                  0xFF388E3C,
                                                                ),
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 200,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[300],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    thought,
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        maxWidth: 200,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 10,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isOriginal
                                                            ? const Color(
                                                              0xFFFFF1F1,
                                                            )
                                                            : const Color(
                                                              0xFFE6F9ED,
                                                            ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          isOriginal
                                                              ? const Color(
                                                                0xFFD32F2F,
                                                              )
                                                              : const Color(
                                                                0xFF388E3C,
                                                              ),
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.05,
                                                            ),
                                                        blurRadius: 4,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Text(
                                                    thought,
                                                    style: TextStyle(
                                                      color:
                                                          isOriginal
                                                              ? const Color(
                                                                0xFFD32F2F,
                                                              )
                                                              : const Color(
                                                                0xFF388E3C,
                                                              ),
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 하단: 두 개의 주머니
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    // 도움이 되지 않는 생각 주머니
                    Expanded(
                      child: DragTarget<String>(
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          final thought = details.data;
                          final isOriginal = widget.previousChips.contains(
                            thought,
                          );
                          if (isOriginal) {
                            // 붉은색 생각을 붉은색 주머니에 넣는 것은 올바름
                            _moveToUnhelpful(thought);
                          } else {
                            // 초록색 생각을 붉은색 주머니에 넣으려고 하면 경고
                            _showColorMismatchDialog(thought, false);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Card(
                            color: const Color(0xFFFFF1F1),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: Colors.red[400],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          '이전 생각',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFD32F2F),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.red[200]!,
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child:
                                          _unhelpfulThoughts.isEmpty
                                              ? const Center(
                                                child: Text(
                                                  '여기에 드래그하세요',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              )
                                              : SingleChildScrollView(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children:
                                                      _unhelpfulThoughts.map((
                                                        thought,
                                                      ) {
                                                        return GestureDetector(
                                                          onTap:
                                                              () =>
                                                                  _moveBackToRemaining(
                                                                    thought,
                                                                    'unhelpful',
                                                                  ),
                                                          child: Container(
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 150,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFFFF1F1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    const Color(
                                                                      0xFFD32F2F,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              thought,
                                                              style: const TextStyle(
                                                                color: Color(
                                                                  0xFFD32F2F,
                                                                ),
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 2,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 도움이 되는 생각 주머니
                    Expanded(
                      child: DragTarget<String>(
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          final thought = details.data;
                          final isOriginal = widget.previousChips.contains(
                            thought,
                          );
                          if (!isOriginal) {
                            // 초록색 생각을 초록색 주머니에 넣는 것은 올바름
                            _moveToHelpful(thought);
                          } else {
                            // 붉은색 생각을 초록색 주머니에 넣으려고 하면 경고
                            _showColorMismatchDialog(thought, true);
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Card(
                            color: const Color(0xFFE6F9ED),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green[400],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      const Expanded(
                                        child: Text(
                                          '이후 생각',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF388E3C),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.green[200]!,
                                          width: 2,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child:
                                          _helpfulThoughts.isEmpty
                                              ? const Center(
                                                child: Text(
                                                  '여기에 드래그하세요',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              )
                                              : SingleChildScrollView(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children:
                                                      _helpfulThoughts.map((
                                                        thought,
                                                      ) {
                                                        return GestureDetector(
                                                          onTap:
                                                              () =>
                                                                  _moveBackToRemaining(
                                                                    thought,
                                                                    'helpful',
                                                                  ),
                                                          child: Container(
                                                            constraints:
                                                                const BoxConstraints(
                                                                  maxWidth: 150,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFE6F9ED,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    const Color(
                                                                      0xFF388E3C,
                                                                    ),
                                                                width: 1,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              thought,
                                                              style: const TextStyle(
                                                                color: Color(
                                                                  0xFF388E3C,
                                                                ),
                                                                fontSize: 11,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              maxLines: 2,
                                                            ),
                                                          ),
                                                        );
                                                      }).toList(),
                                                ),
                                              ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          onBack: () => Navigator.pop(context),
          onNext:
              _remainingThoughts.isEmpty
                  ? () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder:
                          (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text('수고하셨습니다!'),
                            content: const Text(
                              '오늘은 내 생각을 구분하고, 도움이 되는 생각으로 바꿔보는 연습을 잘 마쳤어요!',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // 다이얼로그 닫기
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/',
                                    (route) => false,
                                  ); // 홈으로 이동
                                },
                                child: const Text('확인'),
                              ),
                            ],
                          ),
                    );
                  }
                  : null,
        ),
      ),
    );
  }
}
