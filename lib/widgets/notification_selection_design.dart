// 🪸 Mindrium NotificationSelectionDesign — TreatmentDesign 구조 호환 버전
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/tap_design.dart';

class NotificationSelectionDesign extends StatelessWidget {
  // ===== 전달받는 데이터/콜백 =====
  final dynamic draftTime;
  final dynamic draftLocation;
  final bool noNotification;
  final bool isSaving;

  final VoidCallback onShowHelp;
  final VoidCallback onSave;
  final VoidCallback onSelectLocation;
  final ValueChanged<bool> onToggleNoNotification;

  // ===== 텍스트 =====
  final String titleText;
  final String subtitleText;
  final String labelText;
  final String locationText;
  final String timeText;
  final String disableText;
  final String saveButtonText;

  const NotificationSelectionDesign({
    super.key,
    required this.draftTime,
    required this.draftLocation,
    required this.noNotification,
    required this.isSaving,
    required this.onShowHelp,
    required this.onSave,
    required this.onSelectLocation,
    required this.onToggleNoNotification,
    required this.titleText,
    required this.subtitleText,
    required this.labelText,
    required this.locationText,
    required this.timeText,
    required this.disableText,
    required this.saveButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return TreatmentDesign(
      appBarTitle: titleText,
      weekContents: [
        {'title': titleText, 'subtitle': subtitleText},
      ],
      weekScreens: [
        _NotificationSelectionBody(
          draftTime: draftTime,
          draftLocation: draftLocation,
          noNotification: noNotification,
          isSaving: isSaving,
          onShowHelp: onShowHelp,
          onSave: onSave,
          onSelectLocation: onSelectLocation,
          onToggleNoNotification: onToggleNoNotification,
          locationText: locationText,
          timeText: timeText,
          disableText: disableText,
          saveButtonText: saveButtonText,
        ),
      ],
    );
  }
}

/// 🌊 실제 본문 컨텐츠 영역
class _NotificationSelectionBody extends StatelessWidget {
  final dynamic draftTime;
  final dynamic draftLocation;
  final bool noNotification;
  final bool isSaving;

  final VoidCallback onShowHelp;
  final VoidCallback onSave;
  final VoidCallback onSelectLocation;
  final ValueChanged<bool> onToggleNoNotification;

  final String locationText;
  final String timeText;
  final String disableText;
  final String saveButtonText;

  const _NotificationSelectionBody({
    required this.draftTime,
    required this.draftLocation,
    required this.noNotification,
    required this.isSaving,
    required this.onShowHelp,
    required this.onSave,
    required this.onSelectLocation,
    required this.onToggleNoNotification,
    required this.locationText,
    required this.timeText,
    required this.disableText,
    required this.saveButtonText,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// ❓ 도움말 버튼 (앱바 외부)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: onShowHelp,
              ),
            ),
            const SizedBox(height: 8),

            /// 📍 위치 카드
            _optionCard(
              title: locationText,
              subtitle:
                  draftLocation != null ? (draftLocation.location ?? '') : '',
              onTap: onSelectLocation,
            ),

            /// 🕓 시간 카드
            _optionCard(
              title: timeText,
              subtitle: draftTime != null ? draftTime.toString() : '',
              onTap: () {
                // 시간 선택 콜백은 필요 시 외부에서 연결
              },
            ),

            const SizedBox(height: 20),

            /// 🔕 알림 미설정 체크박스
            Row(
              children: [
                Checkbox(
                  value: noNotification,
                  onChanged: (v) => onToggleNoNotification(v ?? false),
                  activeColor: Colors.white,
                  checkColor: Colors.black,
                ),
                Expanded(
                  child: Text(
                    disableText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            /// 💾 저장 버튼
            PrimaryActionButton(
              text: saveButtonText,
              onPressed: isSaving ? null : onSave,
            ),
          ],
        ),
      ),
    );
  }

  /// 💠 공통 카드 스타일
  Widget _optionCard({
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
