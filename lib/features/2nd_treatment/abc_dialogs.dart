import 'package:flutter/material.dart';
import '../../common/constants.dart';

/// 💬 ABC 입력 단계 공용 다이얼로그 유틸
class AbcDialogs {
  /// 🩵 A단계 (상황 추가)
  static Future<String?> showAddSituationDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _buildDialog(
            context: context,
            title: '어떤 상황에서 불안하셨나요?',
            hint: '예: 자전거 타기',
            suffix1: '(이)라는 상황에서',
            suffix2: '불안을 느꼈습니다.',
            controller: controller,
          ),
    );
  }

  /// 💭 B단계 (생각 추가)
  static Future<String?> showAddThoughtDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _buildDialog(
            context: context,
            title: '그 상황에서 어떤 생각이 들었나요?',
            hint: '예: 비난받을까 두려움',
            suffix1: '(이)라는',
            suffix2: '생각을 하였습니다.',
            controller: controller,
          ),
    );
  }

  /// ❤️ C1단계 (신체 증상 추가)
  static Future<String?> showAddPhysicalDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _buildDialog(
            context: context,
            title: '어떤 신체 증상이 나타났나요?',
            hint: '예: 가슴 두근거림',
            suffix1: '(이)라는',
            suffix2: '신체증상이 나타났습니다.',
            controller: controller,
          ),
    );
  }

  /// 💧 C2단계 (감정 추가)
  static Future<String?> showAddEmotionDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _buildDialog(
            context: context,
            title: '어떤 감정이 들었나요?',
            hint: '예: 두려움',
            suffix1: '(이)라는',
            suffix2: '감정을 느꼈습니다.',
            controller: controller,
          ),
    );
  }

  /// 🚶 C3단계 (행동 추가)
  static Future<String?> showAddBehaviorDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => _buildDialog(
            context: context,
            title: '어떤 행동을 하셨나요?',
            hint: '예: 자전거 끌고가기',
            suffix1: '(이)라는',
            suffix2: '행동을 하였습니다.',
            controller: controller,
          ),
    );
  }

  /// 공통 다이얼로그 빌더
  static Widget _buildDialog({
    required BuildContext context,
    required String title,
    required String hint,
    required String suffix1,
    required String suffix2,
    required TextEditingController controller,
  }) {
    return Dialog(
      backgroundColor: AppColors.indigo50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.shade100),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 80,
                        maxWidth: 180,
                      ),
                      child: TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: hint,
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        autofocus: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      suffix1,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suffix2,
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                Navigator.pop(context, text.isNotEmpty ? text : null);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}
