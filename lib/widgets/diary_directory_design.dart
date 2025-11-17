import 'package:flutter/material.dart';

/// 💧 Mindrium 스타일 디자인 구성요소 모음
class DiaryArchiveDropdown extends StatelessWidget {
  final String selectedGroupId;
  final List<Map<String, String>> groups;
  final ValueChanged<String?> onChanged;

  const DiaryArchiveDropdown({
    super.key,
    required this.selectedGroupId,
    required this.groups,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedGroupId.isEmpty ? null : selectedGroupId,
          hint: const Text('전체 그룹'),
          items: [
            const DropdownMenuItem(value: '', child: Text('전체 그룹')),
            ...groups.map(
              (g) => DropdownMenuItem<String>(
                value: g['id'],
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: AssetImage(
                        'assets/image/character${g['id']}.png',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(g['title'] ?? ''),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// 📘 일기 카드 스타일
class DiaryArchiveCard extends StatelessWidget {
  final String avatarPath;
  final String title;
  final String dateText;
  final String belief;
  final Widget sudBar;
  final String? diaryDetail;
  final Widget notificationsBuilder;

  const DiaryArchiveCard({
    super.key,
    required this.avatarPath,
    required this.title,
    required this.dateText,
    required this.belief,
    required this.sudBar,
    this.diaryDetail,
    required this.notificationsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withOpacity(0.9),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(backgroundImage: AssetImage(avatarPath)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          dateText,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Text(
            '💭 신념: $belief',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            '주관적 불안 점수',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          sudBar,
          if (diaryDetail != null) ...[
            const Divider(),
            Text(
              '📔 $diaryDetail',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
          const Divider(),
          notificationsBuilder,
        ],
      ),
    );
  }
}
