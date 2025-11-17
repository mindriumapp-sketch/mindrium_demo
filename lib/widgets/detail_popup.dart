// lib/widgets/detail_popup.dart
import 'package:flutter/material.dart';

class DetailPopup extends StatelessWidget {
  final String title;
  final Widget child;                      // ✅ 여기만 다름: message 대신 child
  final String positiveText;
  final String? negativeText;              // nullable
  final VoidCallback onPositivePressed;
  final VoidCallback? onNegativePressed;   // nullable
  final String? backgroundAsset;
  final String? iconAsset;

  const DetailPopup({
    super.key,
    required this.title,
    required this.child,
    required this.onPositivePressed,
    this.onNegativePressed,
    this.positiveText = '확인',
    this.negativeText = '취소',
    this.backgroundAsset,
    this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    final bool singleAction = negativeText == null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF74D2FF).withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
              image: backgroundAsset != null
                  ? DecorationImage(
                image: AssetImage(backgroundAsset!),
                fit: BoxFit.cover,
                opacity: 0.15,
              )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 타이틀
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF626262),
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ 메시지 대신 child
                child,

                const SizedBox(height: 28),

                // 버튼 영역
                if (singleAction)
                  SizedBox(
                    width: double.infinity,
                    child: _buildButton(
                      context,
                      label: positiveText,
                      onPressed: onPositivePressed,
                      isPrimary: true,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildButton(
                            context,
                            label: negativeText!,
                            onPressed: onNegativePressed ?? () {},
                            isPrimary: false,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildButton(
                            context,
                            label: positiveText,
                            onPressed: onPositivePressed,
                            isPrimary: true,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // // 상단 아이콘
          // Positioned(
          //   top: -40,
          //   left: 0,
          //   right: 0,
          //   child: Center(
          //     child: Container(
          //       width: 80,
          //       height: 80,
          //       decoration: BoxDecoration(
          //         shape: BoxShape.circle,
          //         gradient: const LinearGradient(
          //           colors: [Color(0xFF74D2FF), Color(0xFF99E0FF)],
          //         ),
          //         boxShadow: [
          //           BoxShadow(
          //             color: const Color(0xFF74D2FF).withOpacity(0.4),
          //             blurRadius: 12,
          //             offset: const Offset(0, 4),
          //           ),
          //         ],
          //       ),
          //       child: ClipOval(
          //         child: iconAsset != null
          //             ? Image.asset(iconAsset!, fit: BoxFit.cover)
          //             : const Icon(
          //           Icons.auto_awesome,
          //           color: Colors.white,
          //           size: 36,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, {
        required String label,
        required VoidCallback onPressed,
        required bool isPrimary,
      }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: isPrimary ? const Color(0xFF74D2FF) : Colors.white,
        foregroundColor: isPrimary ? Colors.white : const Color(0xFF356D91),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isPrimary
              ? BorderSide.none
              : const BorderSide(color: Color(0xFF74D2FF), width: 1.2),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'NotoSansKR',
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
