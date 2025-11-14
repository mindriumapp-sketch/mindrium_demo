// lib/widgets/thought_card.dart
import 'package:flutter/material.dart';

/// 피그마 말풍선 타입
enum ThoughtType { helpful, unhelpful }

/// 말풍선 색상 테마
class ThoughtColors {
  // Helpful (불안 직면) - 밝은 민트 블루
  static const Color helpfulBackground = Color(0xFF85CAEF);
  static const Color helpfulIcon = Color(0xFF4CA6E8);

  // Unhelpful (불안 회피) - 부드러운 코랄 피치
  static const Color unhelpfulBackground = Color(0xFFFFADA3);
  static const Color unhelpfulIcon = Color(0xFFDB6F7A);

  // 공통 색상
  static const Color iconBoxBackground = Colors.white;
  static const Color textColor = Colors.white;
  static const Color titleColor = Color(0xFF263C69);
  static const Color dividerColor = Color(0x1A263C69);
  static const Color emptyTextColor = Color(0x59263C69); // 35% opacity
  static const Color cardBackground = Colors.white;
}

/// 말풍선 스타일 설정
class ThoughtBubbleStyle {
  final double height;
  final double radius;
  final double iconBoxSize;
  final double gap;
  final double iconBoxOpacity;
  final double shadowBlur;
  final double shadowOpacity;
  final Offset shadowOffset;

  const ThoughtBubbleStyle({
    this.height = 54,
    this.radius = 28,
    this.iconBoxSize = 32,
    this.gap = 12,
    this.iconBoxOpacity = 0.96,
    this.shadowBlur = 6,
    this.shadowOpacity = 0.08,
    this.shadowOffset = const Offset(0, 3),
  });
}

/// 피그마 스타일 말풍선 단일 아이템
class ThoughtBubble extends StatelessWidget {
  final String text;
  final ThoughtType? type;
  final Color? color;
  final VoidCallback? onTap;
  final ThoughtBubbleStyle style;

  const ThoughtBubble({
    super.key,
    required this.text,
    this.type,
    this.color,
    this.onTap,
    this.style = const ThoughtBubbleStyle(),
  });

  // color가 들어오면 아이콘 박스를 숨기자
  bool get _showIconBox => color == null;

  Color get _backgroundColor {
    if (color != null) return color!;
    return type == ThoughtType.helpful
        ? ThoughtColors.helpfulBackground
        : ThoughtColors.unhelpfulBackground;
  }

  Color get _iconColor {
    return type == ThoughtType.helpful
        ? ThoughtColors.helpfulIcon
        : ThoughtColors.unhelpfulIcon;
  }

  IconData get _icon {
    return type == ThoughtType.helpful
        ? Icons.chat_bubble_rounded
        : Icons.block;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(style.radius),
          onTap: onTap,
          child: Ink(
            height: style.height,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(style.radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(style.shadowOpacity),
                  blurRadius: style.shadowBlur,
                  offset: style.shadowOffset,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_showIconBox) _buildIconBox(),
                  if (_showIconBox) SizedBox(width: style.gap),
                  _buildText(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox() {
    return Container(
      width: style.iconBoxSize,
      height: style.iconBoxSize,
      decoration: BoxDecoration(
        color: ThoughtColors.iconBoxBackground
            .withOpacity(style.iconBoxOpacity),
        borderRadius: BorderRadius.circular(style.iconBoxSize / 2),
      ),
      alignment: Alignment.center,
      child: Icon(
        _icon,
        size: style.iconBoxSize * 0.56,
        color: _iconColor,
      ),
    );
  }

  Widget _buildText() {
    return Expanded(
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ThoughtColors.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.0,
            fontFamily: 'Noto Sans KR',
          ),
        ),
      ),
    );
  }
}

/// 제목 + 구분선 + 말풍선 목록
class ThoughtCard extends StatelessWidget {
  final String title;
  final List<String> pills;
  final ThoughtType thoughtType;

  // 스타일 커스터마이징
  final double titleSize;
  final FontWeight titleWeight;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final double radius;
  final ThoughtBubbleStyle bubbleStyle;

  const ThoughtCard({
    super.key,
    required this.title,
    required this.pills,
    required this.thoughtType,
    this.titleSize = 18,
    this.titleWeight = FontWeight.w600,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
    this.backgroundColor = ThoughtColors.cardBackground,
    this.radius = 20,
    this.bubbleStyle = const ThoughtBubbleStyle(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitle(),
          const SizedBox(height: 12),
          const Divider(height: 1, color: ThoughtColors.dividerColor),
          const SizedBox(height: 12),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: titleSize,
        fontWeight: titleWeight,
        color: ThoughtColors.titleColor,
      ),
    );
  }

  Widget _buildContent() {
    if (pills.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: pills.map((pill) => ThoughtBubble(
        text: pill,
        type: thoughtType,
        style: bubbleStyle,
        onTap: () {
          // TODO: 필요시 팝업/상세 보기 연결
        },
      )).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        '등록된 문장이 없습니다.',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ThoughtColors.emptyTextColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}