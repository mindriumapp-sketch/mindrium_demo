import 'package:flutter/material.dart';

class BehaviorConfirmDialog extends StatelessWidget {
  final String titleText;
  final String highlightText;
  final String messageText;
  final String negativeText;
  final String positiveText;
  final VoidCallback onNegativePressed;
  final VoidCallback onPositivePressed;

  final String badgeBgAsset;
  final String memoBgAsset;

  const BehaviorConfirmDialog({
    super.key,
    required this.titleText,
    required this.highlightText,
    required this.messageText,
    required this.onNegativePressed,
    required this.onPositivePressed,
    this.negativeText = '아니요',
    this.positiveText = '예',
    this.badgeBgAsset = 'assets/image/popup1.png',
    this.memoBgAsset = 'assets/image/popup2.png',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 메인 카드
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 60), // 배지 공간 확보
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32), // 상단 여유 증가
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263C69),
                  ),
                ),
                const SizedBox(height: 12),

                // 메모 띠 (popup2)
                _FoldedMemoTag(
                  text: highlightText,
                  memoBgAsset: memoBgAsset,
                ),

                const SizedBox(height: 22),
                Text(
                  messageText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),

                // 버튼 두 개
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onNegativePressed,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          negativeText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF263C69),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onPositivePressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5DADEC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          positiveText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 상단 원형 배지
          Positioned(
            top: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 배경용 흰 원 (popup과 자연스럽게 이어짐)
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                Image.asset(
                  badgeBgAsset,
                  width: 105,
                  height: 105,
                  fit: BoxFit.cover,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 메모띠 (popup2) 
class _FoldedMemoTag extends StatelessWidget {
  final String text;
  final String memoBgAsset;

  const _FoldedMemoTag({
    required this.text,
    required this.memoBgAsset,
  });

  @override
  Widget build(BuildContext context) {
    // memoBgAsset이 비어있으면 아예 표시하지 않음
    if (memoBgAsset.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 288, // 피그마 기준
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              memoBgAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 58,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12), // 좌우 패딩 줄임
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF263C69),
              ),
            ),
          ),
        ],
      ),
    );
  }
}