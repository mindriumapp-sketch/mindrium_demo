import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/blue_white_card.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';

/// 🌊 Mindrium 스타일 “적용하기” 화면 공용 위젯 (로그인 구조 기반)
/// - 배경: eduhome.png
/// - 중앙 카드: BlueWhiteCard (스크롤 가능, 중앙 정렬)
/// - 앱바 + 네비게이션 버튼 포함
class ApplyDesign extends StatelessWidget {
  final String appBarTitle; // 앱바 타이틀
  final String cardTitle; // 카드 상단 제목
  final Widget child; // 카드 내부 내용
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const ApplyDesign({
    super.key,
    required this.appBarTitle,
    required this.cardTitle,
    required this.child,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final double maxCardWidth = MediaQuery.of(context).size.width - 48;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: appBarTitle),
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌊 배경 이미지
          Opacity(opacity: 0.65,
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),),

          /// 💠 본문 (로그인 스타일 구조)
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 34,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// 🧾 중앙 카드
                    BlueWhiteCard(
                      maxWidth: maxCardWidth,
                      title: cardTitle,
                      titleStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263C69),
                      ),
                      outerColor: Colors.transparent,
                      outerRadius: 22,
                      outerExpand: EdgeInsets.zero,
                      innerColor: Colors.white,
                      innerRadius: 20,
                      innerPadding: const EdgeInsets.fromLTRB(28, 26, 28, 26),
                      dividerColor: const Color(0xFFE8EDF4),
                      dividerWidth: 240,
                      titleTopGap: 10,
                      child: child,
                    ),

                    const SizedBox(height: 40),

                    /// ⛵ 네비게이션 버튼
                    NavigationButtons(onBack: onBack, onNext: onNext),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

///상황에 따라 쓰이거나 안쓰이는 아이들

/// 🌊 Mindrium 6주차 “불안 완화 결과” 카드 디자인
Widget buildRelieveResultCard({
  required String userName,
  required String mainText,
  required String subText,
  required bool showMainText,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      // 🧜 이름 표시
      Text(
        '$userName님',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF5B3EFF),
          fontFamily: 'Noto Sans KR',
        ),
      ),
      const SizedBox(height: 20),

      // 💠 포인트 구분선
      Container(
        width: 48,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFF5B3EFF).withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 40),

      // ✨ 전환되는 안내문
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: Text(
          showMainText ? mainText : subText,
          key: ValueKey(showMainText),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
            height: 1.6,
            letterSpacing: 0.1,
            fontFamily: 'Noto Sans KR',
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 48),

      // 🪸 시각 포인트 아이콘
      Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF5B3EFF).withOpacity(0.1),
        ),
        child: const Icon(
          Icons.psychology_alt_rounded,
          size: 40,
          color: Color(0xFF5B3EFF),
        ),
      ),
    ],
  );
}

/// 🌊 Mindrium 스타일 2-버튼 선택 위젯 (예: 불안 완화 선택)
class MindriumChoiceButtons extends StatelessWidget {
  final String label1;
  final String label2;
  final Color color1;
  final Color color2;
  final int? selectedValue;
  final void Function(int) onSelect;

  const MindriumChoiceButtons({
    super.key,
    required this.label1,
    required this.label2,
    this.color1 = const Color(0xFFFF5252),
    this.color2 = const Color(0xFF4CAF50),
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildChoiceButton(
            label: label1,
            value: 0,
            color: color1,
            isSelected: selectedValue == 0,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildChoiceButton(
            label: label2,
            value: 10,
            color: color2,
            isSelected: selectedValue == 10,
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton({
    required String label,
    required int value,
    required Color color,
    required bool isSelected,
  }) {
    return ElevatedButton(
      onPressed: () => onSelect(value),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.white,
        foregroundColor: isSelected ? Colors.white : color,
        side: BorderSide(color: color, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Noto Sans KR',
        ),
      ),
    );
  }
}
