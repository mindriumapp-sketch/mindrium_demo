import 'package:flutter/material.dart';

/// 🎨 디자인 전용 위젯 (텍스트, 폰트, 색상, 레이아웃만 담당)
class AbcPracticeDesign extends StatelessWidget {
  final String titleText;
  final String descriptionText;
  final Widget navigationButtons;

  const AbcPracticeDesign({
    super.key,
    required this.titleText,
    required this.descriptionText,
    required this.navigationButtons,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          const Icon(Icons.edit, size: 72, color: Color(0xFF3F51B5)),
          const SizedBox(height: 32),
          Text(
            titleText,
            style: const TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            descriptionText,
            style: const TextStyle(
              fontFamily: 'Noto Sans KR',
              fontSize: 20,
              color: Colors.black87,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          navigationButtons,
        ],
      ),
    );
  }
}
