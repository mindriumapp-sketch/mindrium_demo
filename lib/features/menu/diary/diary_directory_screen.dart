import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/features/menu/menu_screen.dart'; // 또는 실제 경로

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🧩 AbcModel
class AbcModel {
  final String id;
  final String activatingEvent;
  final String belief;
  final String consequence;
  final String groupId;
  final String? diaryDetail;
  final int? sudScore;
  final Timestamp createdAt;

  AbcModel({
    required this.id,
    required this.activatingEvent,
    required this.belief,
    required this.consequence,
    required this.groupId,
    this.diaryDetail,
    this.sudScore,
    required this.createdAt,
  });

  factory AbcModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AbcModel(
      id: doc.id,
      activatingEvent: data['activatingEvent'] as String? ?? '-',
      belief: data['belief'] as String? ?? '-',
      consequence: data['consequence'] as String? ?? '-',
      groupId: data['group_id'] as String? ?? '',
      diaryDetail: data['diaryDetail'] as String?,
      sudScore: data['sud_score'] as int?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

/// ✅ SUD 점수 바 (깔끔하게 개선)
class _SudScoreBar extends StatelessWidget {
  final String uid;
  final String modelId;
  const _SudScoreBar({required this.uid, required this.modelId});

  @override
  Widget build(BuildContext context) {
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_models')
        .doc(modelId)
        .collection('sud_score');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: col.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              backgroundColor: Color(0xFFE3F2FD),
              valueColor: AlwaysStoppedAnimation(Color(0xFF5B9FD3)),
            ),
          );
        }

        int after = 0;
        for (final d in snap.data?.docs ?? []) {
          final v = d.data()['after_sud'];
          if (v is int) after = v;
          if (v is num) after = v.toInt();
        }
        after = after.clamp(0, 10);
        final ratio = after / 10.0;
        final color = Color.lerp(
          const Color(0xFF4CAF50),
          const Color(0xFFF44336),
          ratio,
        )!;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FBFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE3F2FD)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '주관적 불안점수',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0E2C48),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$after / 10',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: ratio,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ✅ 일기 + 알림 목록 (가독성 개선)
class AbcStreamList extends StatelessWidget {
  final String uid;
  final String? selectedGroupId;
  const AbcStreamList({super.key, required this.uid, this.selectedGroupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('abc_models')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF5B9FD3)),
          );
        }

        final items = (snap.data?.docs ?? [])
            .map(AbcModel.fromDoc)
            .where(
              (m) => selectedGroupId == null || m.groupId == selectedGroupId,
        )
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final model = items[i];
            final assetPath = 'assets/image/character${model.groupId}.png';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3F2FD), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFB8DAF5),
                    backgroundImage: AssetImage(assetPath),
                  ),
                  title: Text(
                    model.activatingEvent,
                    style: const TextStyle(
                      color: Color(0xFF0E2C48),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('yyyy.MM.dd HH:mm')
                          .format(model.createdAt.toDate()),
                      style: const TextStyle(
                        color: Color(0xFF1B405C),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  children: [
                    /// SUD 점수 표시
                    _SudScoreBar(uid: uid, modelId: model.id),
                    const SizedBox(height: 12),

                    /// 🔔 알림 펼쳐보기 (테두리 두껍게)
                    _buildSubSection(
                      context: context,
                      icon: Icons.notifications_outlined,
                      title: '알림 설정',
                      borderWidth: 1.8, // 테두리 두껍게
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('abc_models')
                            .doc(model.id)
                            .collection('notification_settings')
                            .snapshots(),
                        builder: (context, notifSnap) {
                          if (notifSnap.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF5B9FD3),
                                ),
                              ),
                            );
                          }

                          final notifs = notifSnap.data?.docs ?? [];
                          if (notifs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: Text(
                                  '설정된 알림이 없습니다',
                                  style: TextStyle(
                                    color: Color(0xFF1B405C),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: notifs.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final notifDoc = entry.value;
                              final data =
                              notifDoc.data() as Map<String, dynamic>;
                              final location = data['location'] ?? '-';
                              final notifyEnter =
                                  data['notifyEnter'] ?? false;
                              final notifyExit = data['notifyExit'] ?? false;
                              final condition = notifyEnter && notifyExit
                                  ? '입장/퇴장'
                                  : notifyEnter
                                  ? '입장 시'
                                  : notifyExit
                                  ? '퇴장 시'
                                  : '매일 반복';
                              final time = data['time'] ?? '-';
                              final rm = data['reminderMinutes'];
                              int? reminderMinutes;
                              if (rm is num) reminderMinutes = rm.toInt();

                              return Container(
                                margin: EdgeInsets.only(
                                  top: idx > 0 ? 8 : 0,
                                  bottom: 8,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FBFF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFF4A8CCB),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(
                                      Icons.location_on_outlined,
                                      '위치',
                                      location,
                                    ),
                                    const SizedBox(height: 6),
                                    _infoRow(
                                      Icons.notifications_active_outlined,
                                      '조건',
                                      condition,
                                    ),
                                    const SizedBox(height: 6),
                                    _infoRow(
                                      Icons.access_time_outlined,
                                      '시간',
                                      time,
                                    ),
                                    if (reminderMinutes != null) ...[
                                      const SizedBox(height: 6),
                                      _infoRow(
                                        Icons.replay_outlined,
                                        '반복',
                                        '$reminderMinutes분',
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 16,
                                          color: Color(0xFF5B9FD3),
                                        ),
                                        label: const Text(
                                          '수정',
                                          style: TextStyle(
                                            color: Color(0xFF5B9FD3),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  NotificationSelectionScreen(
                                                    origin: 'edit',
                                                    abcId: model.id,
                                                    label:
                                                    model.activatingEvent,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),

                    /// 📖 일기 펼쳐보기
                    if (model.diaryDetail != null) ...[
                      const SizedBox(height: 12),
                      _buildSubSection(
                        context: context,
                        icon: Icons.book_outlined,
                        title: '일기 내용',
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE3F2FD)),
                          ),
                          child: Text(
                            model.diaryDetail!,
                            style: const TextStyle(
                              color: Color(0xFF0E2C48),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 서브 섹션 위젯
Widget _buildSubSection({
  required BuildContext context,
  required IconData icon,
  required String title,
  required Widget child,
  double borderWidth = 1.2,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF90CAF9), width: borderWidth), // 👈 색깔 변경!
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(icon, color: const Color(0xFF5B9FD3), size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0E2C48),
            fontSize: 14,
          ),
        ),
        children: [child],
      ),
    ),
  );
}

/// 정보 행 위젯
Widget _infoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF5B9FD3)),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0E2C48),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1B405C),
          ),
        ),
      ),
    ],
  );
}

/// ✅ NotificationDirectoryScreen 본문
class NotificationDirectoryScreen extends StatefulWidget {
  const NotificationDirectoryScreen({super.key});

  @override
  State<NotificationDirectoryScreen> createState() =>
      _NotificationDirectoryScreenState();
}

class _NotificationDirectoryScreenState
    extends State<NotificationDirectoryScreen> {
  String _selectedGroupId = '';
  bool _groupsLoading = true;
  List<Map<String, String>> _groups = [];
  StreamSubscription? _groupSub;

  @override
  void initState() {
    super.initState();
    _subscribeGroups();
  }

  void _subscribeGroups() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    _groupSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('abc_group')
        .snapshots()
        .listen((snap) {
      final newGroups = snap.docs.map((d) {
        final data = d.data();
        final gid = (data['group_id'] ?? '').toString();
        final title = (data['group_title'] ?? gid).toString();
        return {'id': gid, 'title': title};
      }).toList();

      if (mounted) {
        setState(() {
          _groups = newGroups;
          _groupsLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    if (_groupsLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '알림 목록',
        showHome: true,
        confirmOnHome: false,
        confirmOnBack: false,
        onBack: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ContentScreen()),
                (route) => false,
          );
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌊 배경 (HomeScreen과 동일)
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/image/eduhome.png',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xAAFFFFFF), Color(0x66FFFFFF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  /// 🪸 그룹 선택 섹션 (다른 섹션과 비슷한 스타일)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE3F2FD),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        leading: const Icon(
                          Icons.group_outlined,
                          color: Color(0xFF5B9FD3),
                          size: 22,
                        ),
                        title: Text(
                          _selectedGroupId.isEmpty
                              ? '전체 그룹'
                              : _groups
                              .firstWhere(
                                (g) => g['id'] == _selectedGroupId,
                            orElse: () => {'title': '전체 그룹'},
                          )['title']!,
                          style: const TextStyle(
                            color: Color(0xFF0E2C48),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '그룹을 선택하여 필터링',
                            style: TextStyle(
                              color: Color(0xFF1B405C),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        children: [
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 300, // 스크롤 가능한 최대 높이
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  // 전체 그룹 옵션
                                  InkWell(
                                    onTap: () {
                                      setState(() => _selectedGroupId = '');
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: _selectedGroupId.isEmpty
                                            ? const Color(0xFFE3F2FD)
                                            : const Color(0xFFF8FBFF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedGroupId.isEmpty
                                              ? const Color(0xFF5B9FD3)
                                              : const Color(0xFFE3F2FD),
                                          width: _selectedGroupId.isEmpty ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.group_outlined,
                                            color: _selectedGroupId.isEmpty
                                                ? const Color(0xFF5B9FD3)
                                                : const Color(0xFF1B405C),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '전체 그룹',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: _selectedGroupId.isEmpty
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: _selectedGroupId.isEmpty
                                                  ? const Color(0xFF0E2C48)
                                                  : const Color(0xFF1B405C),
                                            ),
                                          ),
                                          const Spacer(),
                                          if (_selectedGroupId.isEmpty)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF5B9FD3),
                                              size: 20,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // 각 그룹 옵션
                                  ..._groups.map((g) {
                                    final isSelected = _selectedGroupId == g['id'];
                                    return InkWell(
                                      onTap: () {
                                        setState(() => _selectedGroupId = g['id']!);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? const Color(0xFFE3F2FD)
                                              : const Color(0xFFF8FBFF),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? const Color(0xFF5B9FD3)
                                                : const Color(0xFFE3F2FD),
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor:
                                              const Color(0xFFB8DAF5),
                                              backgroundImage: AssetImage(
                                                'assets/image/character${g['id']}.png',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                g['title']!,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? const Color(0xFF0E2C48)
                                                      : const Color(0xFF1B405C),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF5B9FD3),
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🪸 일기/알림 리스트
                  Expanded(
                    child: AbcStreamList(
                      uid: uid,
                      selectedGroupId:
                      _selectedGroupId.isEmpty ? null : _selectedGroupId,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}