import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';

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

/// ✅ SUD 점수 바
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
          return const LinearProgressIndicator(minHeight: 8);
        }

        int after = 0;
        for (final d in snap.data?.docs ?? []) {
          final v = d.data()['after_sud'];
          if (v is int) after = v;
          if (v is num) after = v.toInt();
        }
        after = after.clamp(0, 10);
        final ratio = after / 10.0;
        final color = Color.lerp(Colors.green, Colors.red, ratio)!;

        return Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: ratio,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$after/10',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// ✅ 일기 + 알림 목록
class AbcStreamList extends StatelessWidget {
  final String uid;
  final String? selectedGroupId;
  const AbcStreamList({super.key, required this.uid, this.selectedGroupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('abc_models')
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final items =
            (snap.data?.docs ?? [])
                .map(AbcModel.fromDoc)
                .where(
                  (m) =>
                      selectedGroupId == null || m.groupId == selectedGroupId,
                )
                .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final model = items[i];
            final assetPath = 'assets/image/character${model.groupId}.png';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                backgroundColor: Colors.transparent,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.5),
                  backgroundImage: AssetImage(assetPath),
                ),
                title: Text(
                  model.activatingEvent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'yyyy.MM.dd HH:mm',
                        ).format(model.createdAt.toDate()),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const Text(
                        '주관적 불안점수',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SudScoreBar(uid: uid, modelId: model.id),
                  const SizedBox(height: 10),

                  /// 🔔 알림 펼쳐보기
                  ExpansionTile(
                    collapsedIconColor: Colors.white70,
                    iconColor: Colors.white,
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.white,
                    ),
                    title: const Text(
                      '알림 펼쳐보기',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
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
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          }

                          final notifs = notifSnap.data?.docs ?? [];
                          if (notifs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                '설정된 알림이 없습니다.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notifs.length,
                            separatorBuilder:
                                (_, __) => const Divider(color: Colors.white30),
                            itemBuilder: (c, idx) {
                              final data =
                                  notifs[idx].data() as Map<String, dynamic>;
                              final location = data['location'] ?? '-';
                              final notifyEnter = data['notifyEnter'] ?? false;
                              final notifyExit = data['notifyExit'] ?? false;
                              final condition =
                                  notifyEnter && notifyExit
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
                              final reminderText =
                                  reminderMinutes == null
                                      ? '반복 없음'
                                      : '반복 ($reminderMinutes분)';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '위치: $location',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    '조건: $condition',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    '시간: $time',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    reminderText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        '수정',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (_) =>
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
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),

                  /// 📖 일기 펼쳐보기
                  if (model.diaryDetail != null)
                    ExpansionTile(
                      collapsedIconColor: Colors.white70,
                      iconColor: Colors.white,
                      leading: const Icon(Icons.book, color: Colors.white),
                      title: const Text(
                        '일기 펼쳐보기',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            model.diaryDetail!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
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
          final newGroups =
              snap.docs.map((d) {
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
        onBack: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (_) => AlertDialog(
                  backgroundColor: Colors.white.withOpacity(0.95),
                  title: const Text('종료하시겠습니까?'),
                  content: const Text('이 화면을 종료하고 이전 화면으로 돌아갑니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('나가기'),
                    ),
                  ],
                ),
          );

          if (shouldExit == true) {
            // ✅ 검은화면 방지용 임시 오버레이 추가
            final overlayContext = navigatorKey.currentState?.overlay?.context;
            if (overlayContext != null) {
              showGeneralDialog(
                context: overlayContext,
                barrierColor: Colors.transparent,
                barrierDismissible: false,
                transitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => const SizedBox.shrink(),
              );
            }

            // ✅ 실제 뒤로가기
            if (mounted) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/menu');
              }
            }

            // ✅ 오버레이 제거 (한 프레임 뒤 닫기)
            await Future.delayed(const Duration(milliseconds: 100));
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF003B5C),
                  Color(0xFF4EB4E5),
                  Color(0xFFBFF4FF),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          IgnorePointer(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  /// 🪸 그룹 선택 드롭다운
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value:
                            _selectedGroupId.isEmpty ? null : _selectedGroupId,
                        hint: const Row(
                          children: [
                            Icon(Icons.group, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              '전체 그룹',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        dropdownColor: Colors.white,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Row(
                              children: [
                                Icon(Icons.group, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  '전체 그룹',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          ..._groups.map(
                            (g) => DropdownMenuItem<String>(
                              value: g['id']!,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: AssetImage(
                                      'assets/image/character${g['id']}.png',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    g['title']!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        onChanged:
                            (val) =>
                                setState(() => _selectedGroupId = val ?? ''),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

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
