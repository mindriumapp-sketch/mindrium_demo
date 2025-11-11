import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart';
import 'week3_explain_alternative_thoughts.dart';

/// 🌊 3주차 - Self Talk (상상하기 단계)
/// - ApplyDesign으로 Mindrium 스타일 입힘
/// - 시각 디자인은 ApplyDesign이 처리, 여기서는 기능 로직만 유지
class Week3ImaginationScreen extends StatefulWidget {
  const Week3ImaginationScreen({super.key});

  @override
  State<Week3ImaginationScreen> createState() => _Week3ImaginationScreenState();
}

class _Week3ImaginationScreenState extends State<Week3ImaginationScreen> {
  final List<String> _chips = [];

  /// 🪸 입력 다이얼로그
  void _showInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder:
          (_) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 28,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '불안하면 어떤 일이 일어날까요?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: '예: 망신을 당할 것 같아요',
                      border: OutlineInputBorder(),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty) {
                        setState(() => _chips.add(value));
                        Navigator.pop(context);
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('추가'),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ApplyDesign(
      appBarTitle: '3주차 - Self Talk',
      cardTitle: '불안하면 어떤 일이 일어날까요?',
      onBack: () => Navigator.pop(context),
      onNext: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (_, __, ___) =>
                    Week3ExplainAlternativeThoughtsScreen(chips: _chips),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },

      /// 💡 child에는 기능 로직만 유지 (디자인은 ApplyDesign이 담당)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🧠 입력한 문장 리스트
          if (_chips.isEmpty)
            const Text(
              '여기에 입력한 내용이 표시됩니다',
              style: TextStyle(color: Colors.grey, fontSize: 15),
              textAlign: TextAlign.center,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _chips
                      .map(
                        (text) => Text(
                          '• $text',
                          style: const TextStyle(
                            color: Color(0xFF2962F6),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                      .toList(),
            ),
          const SizedBox(height: 24),

          // ✍️ 입력 버튼 (디자인 최소화)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _showInputDialog,
              child: const Text('입력하기', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
