import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/blue_white_card.dart';

class TrainingSelect extends StatelessWidget {
  const TrainingSelect({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '훈련 선택'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cardWidth = math.min(560.0, w * 0.90); // 두 박스 공통 너비
            return Stack(
              children: [
                // === 배경: 흰색 100% + 물결 35% ===
                Container(color: Colors.white), // ffffff 100%
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.35, // 물결 35%
                    child: Image.asset(
                      'assets/image/eduhome.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // === 내용 ===
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: BlueWhiteCard(
                      maxWidth: cardWidth,
                      title: '어떤 활동을 진행하시겠어요?',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          Image.asset(
                            'assets/image/pink3.png',
                            height: math.min(180, w * 0.38),
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 24),
                          _BluePillButton(
                            label: '일기 작성',
                            onTap: () {
                              Navigator.pushNamed(
                                context, '/abc',
                                arguments: {'origin': 'training'},
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _BluePillButton(
                            label: '이완 활동',
                            onTap: () {
                              Navigator.pushNamed(
                                context, '/relaxation_education',
                                arguments: {'abcId': null},
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BluePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BluePillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFAED1FF), Color(0xFF75B6FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
    )._withText(label);
  }
}

extension on Widget {
  Widget _withText(String text) => Stack(
        alignment: Alignment.center,
        children: [
          this,
          const IgnorePointer(ignoring: true, child: SizedBox()),
          IgnorePointer(
            ignoring: true,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}
