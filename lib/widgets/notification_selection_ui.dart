import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import '../../data/notification_provider.dart'; // NotificationSetting, RepeatOption

class NotificationSelectionUI extends StatelessWidget {
  final String? label;
  final NotificationSetting? draftTime;
  final NotificationSetting? draftLocation;
  final bool noNotification;
  final RepeatOption repeatOption;
  final Set<int> selectedWeekdays;
  final Duration reminderDuration;
  final VoidCallback onTapTime;
  final VoidCallback onTapLocation;
  final VoidCallback onTapRepeat;
  final VoidCallback onTapReminder;
  final Function(bool) onToggleNone;
  final VoidCallback onSave;

  // 도움말 버튼
  final VoidCallback? onHelp;

  // ✅ 추가: 위치 ‘들어갈 때/나올 때’ 토글 콜백
  final ValueChanged<bool>? onToggleEnter;
  final ValueChanged<bool>? onToggleExit;

  const NotificationSelectionUI({
    super.key,
    required this.label,
    required this.draftTime,
    required this.draftLocation,
    required this.noNotification,
    required this.repeatOption,
    required this.selectedWeekdays,
    required this.reminderDuration,
    required this.onTapTime,
    required this.onTapLocation,
    required this.onTapRepeat,
    required this.onTapReminder,
    required this.onToggleNone,
    required this.onSave,
    this.onHelp,
    this.onToggleEnter,
    this.onToggleExit,
  });

  // 🎨 팔레트
  static const Color oceanBlue = Color(0xFF5DADEC);
  static const Color softMint = Color(0xFFEAF3FF);
  static const Color deepNavy = Color(0xFF141F35);
  static const Color subText = Color(0xFF555C66);
  static const Color borderBlue = Color(0xFFCFE0FF);
  static const Color shadowColor = Color(0x19000000);
  static const Color disableGrey = Color(0xFFD5D9E0);

  @override
  Widget build(BuildContext context) {
    // ⏱ 위치+시간 동시 설정 시(또는 시간만 설정)엔 입장/퇴장 체크 비활성화
    final bool hasTime = (draftTime?.time ?? draftLocation?.time) != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 제목 + 도움말
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: Text(
                        "원하는 알림 방식을 설정해 주세요",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.4,
                          color: deepNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onHelp,
                      icon: const Icon(Icons.help_outline, size: 22, color: deepNavy),
                      splashRadius: 20,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // 선택된 라벨
                if (label != null && label!.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        const Icon(Icons.label_important_outline, color: oceanBlue, size: 22),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '불안의 원인/상황',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w500,
                                  color: deepNavy,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                label!,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: subText,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                const SizedBox(height: 26),

                // ===== [1] 위치 + 시간 (Divider) =====
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: noNotification ? disableGrey : borderBlue,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 위치 행
                      _rowItem(
                        title: "위치",
                        subtitle: _getLocationText(),
                        icon: Icons.place_outlined,
                        onTap: noNotification ? null : onTapLocation,
                        isFirst: true,
                      ),

                      // ▶ ‘들어갈 때/나올 때’ 체크: 위치가 있을 때만 노출
                      if (draftLocation != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: const Text('들어갈 때'),
                                  value: draftLocation!.notifyEnter,
                                  onChanged: (noNotification || hasTime)
                                      ? null
                                      : (v) => onToggleEnter?.call(v ?? false),
                                ),
                              ),
                              Container(width: 1, height: 28, color: Colors.grey.shade300),
                              Expanded(
                                child: CheckboxListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  title: const Text('나올 때'),
                                  value: draftLocation!.notifyExit,
                                  onChanged: (noNotification || hasTime)
                                      ? null
                                      : (v) => onToggleExit?.call(v ?? false),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 위치/체크와 시간 사이 구분선 (아이콘 정렬 보정)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(70, 0, 20, 0),
                        child: Divider(height: 1, color: Color(0xFFE8EDF5)),
                      ),

                      // 시간 행
                      _rowItem(
                        title: "시간",
                        subtitle: _getTimeText(context),
                        icon: Icons.access_time_outlined,
                        onTap: noNotification ? null : onTapTime,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ===== [2] 반복 + 다시 알림 (Divider) =====
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: noNotification ? disableGrey : borderBlue,
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _rowItem(
                        title: "반복",
                        subtitle: _getRepeatText(),
                        icon: Icons.repeat_rounded,
                        onTap: noNotification ? null : onTapRepeat,
                        isFirst: true,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(70, 0, 20, 0),
                        child: Divider(height: 1, color: Color(0xFFE8EDF5)),
                      ),
                      _rowItem(
                        title: "다시 알림",
                        subtitle: _getReminderText(),
                        icon: Icons.notifications_active_outlined,
                        onTap: noNotification ? null : onTapReminder,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 알림 없음
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: noNotification ? oceanBlue : const Color(0xFFE0E6F0),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withOpacity(0.03),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        activeColor: oceanBlue,
                        value: noNotification,
                        onChanged: (v) => onToggleNone(v ?? false),
                      ),
                    ),
                    title: const Text(
                      "알림을 설정하지 않을래요",
                      style: TextStyle(fontSize: 16, color: deepNavy, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 저장 버튼(작은 그림자)
                DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x12000000),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, -1.5),
                      ),
                    ],
                  ),
                  child: PrimaryActionButton(text: "저장하기", onPressed: onSave),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 텍스트 helpers
  String _getLocationText() {
    if (draftLocation?.location == null) return "위치를 선택하지 않았습니다";
    return draftLocation!.location ?? "위치 정보 없음";
  }

  String _getTimeText(BuildContext context) {
    final t = draftTime?.time ?? draftLocation?.time;
    return t != null ? t.format(context) : "시간을 선택하지 않았습니다";
  }

  String _getRepeatText() {
    if (repeatOption == RepeatOption.daily) return "매일";
    const week = ['일', '월', '화', '수', '목', '금', '토'];
    final sorted = [...selectedWeekdays]..sort();
    return sorted.isEmpty ? "반복 안 함" : '매주 ${sorted.map((d) => week[(d - 1) % 7]).join(", ")}';
  }

  String _getReminderText() {
    final h = reminderDuration.inHours;
    final m = reminderDuration.inMinutes % 60;
    if (h == 0 && m == 0) return "안 함";
    if (h > 0 && m > 0) return "$h시간 $m분 후";
    if (h > 0) return "$h시간 후";
    return "$m분 후";
  }

  // ── 카드 내부 한 줄
  Widget _rowItem({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    bool isFirst = false,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 14, 12, 16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: softMint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: oceanBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    ' ',
                    style: TextStyle(fontSize: 0), // (semantic spacing 보정용)
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: deepNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: disabled ? Colors.grey : subText,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (!disabled)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9EA9B8), size: 24),
          ],
        ),
      ),
    );
  }
}
