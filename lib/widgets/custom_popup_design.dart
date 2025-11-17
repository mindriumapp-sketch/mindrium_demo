import 'package:flutter/material.dart';

class CustomPopupDesign extends StatefulWidget {
  final String title;
  final String highlightText;
  final String message;
  final String positiveText;
  final String? negativeText;
  final VoidCallback onPositivePressed;
  final VoidCallback? onNegativePressed;
  final String? backgroundAsset;
  final String? iconAsset;
  final String memoBgAsset;

  /// ✅ 입력필드 활성화 여부
  final bool enableInput;
  final TextEditingController? controller;
  final String inputHint;

  const CustomPopupDesign({
    super.key,
    required this.title,
    required this.message,
    required this.onPositivePressed,
    this.onNegativePressed,
    this.highlightText = '',
    this.positiveText = '확인',
    this.negativeText = '취소',
    this.backgroundAsset,
    this.iconAsset,
    this.memoBgAsset = 'assets/image/popup2.png',
    this.enableInput = false, // ✅ 기본은 비활성화
    this.controller,
    this.inputHint = '내용을 입력하세요',
  });

  @override
  State<CustomPopupDesign> createState() => _CustomPopupDesignState();
}

class _CustomPopupDesignState extends State<CustomPopupDesign> {
  @override
  Widget build(BuildContext context) {
    final bool singleAction = widget.negativeText == null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 60, 28, 28),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF74D2FF).withOpacity(0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
              image:
                  widget.backgroundAsset != null
                      ? DecorationImage(
                        image: AssetImage(widget.backgroundAsset!),
                        fit: BoxFit.cover,
                        opacity: 0.15,
                      )
                      : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'NotoSansKR',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B3A57),
                  ),
                ),

                if (widget.highlightText.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FoldedMemoTag(
                    text: widget.highlightText,
                    memoBgAsset: widget.memoBgAsset,
                  ),
                  const SizedBox(height: 20),
                ],

                // ✅ 입력 필드 or 메시지
                if (widget.enableInput && widget.controller != null)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF74D2FF),
                        width: 1.3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF74D2FF).withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: widget.controller,
                      maxLines: 1,
                      cursorColor: const Color(0xFF74D2FF),
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 15,
                        color: Color(0xFF356D91),
                      ),
                      decoration: InputDecoration(
                        hintText: widget.inputHint,
                        hintStyle: const TextStyle(
                          color: Color(0xFF9BBFD6),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  )
                else
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 15,
                        color: Color(0xFF356D91),
                        height: 1.5,
                      ),
                      children: [TextSpan(text: widget.message)],
                    ),
                  ),

                const SizedBox(height: 28),

                // ✅ 버튼 영역
                if (singleAction)
                  SizedBox(
                    width: double.infinity,
                    child: _buildButton(
                      label: widget.positiveText,
                      onPressed: widget.onPositivePressed,
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
                            label: widget.negativeText!,
                            onPressed: widget.onNegativePressed ?? () {},
                            isPrimary: false,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: _buildButton(
                            label: widget.positiveText,
                            onPressed: widget.onPositivePressed,
                            isPrimary: true,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 상단 아이콘
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF74D2FF), Color(0xFF99E0FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF74D2FF).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      widget.iconAsset != null
                          ? Image.asset(widget.iconAsset!, fit: BoxFit.cover)
                          : const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 36,
                          ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
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
          side:
              isPrimary
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

class _FoldedMemoTag extends StatelessWidget {
  final String? text;
  final String? memoBgAsset;

  const _FoldedMemoTag({this.text, this.memoBgAsset});

  @override
  Widget build(BuildContext context) {
    if (text == null ||
        text!.isEmpty ||
        memoBgAsset == null ||
        memoBgAsset!.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 288,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              memoBgAsset!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 58,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text!,
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
