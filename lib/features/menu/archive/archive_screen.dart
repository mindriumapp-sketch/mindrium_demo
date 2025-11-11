import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/2nd_treatment/notification_selection_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다.')));
    }
    final uid = user.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: CustomAppBar(
        title: '걱정 물고기 보관함',
        showHome: true,
        confirmOnHome: false,
        confirmOnBack: false,
        onBack: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
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
            // ✅ 검은화면 방지용 임시 오버레이 생성
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

            // ✅ 실제 뒤로가기 수행
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/menu');
            }

            // ✅ 오버레이 제거 (살짝 지연 후 닫기)
            await Future.delayed(const Duration(milliseconds: 100));
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        },
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌊 Ocean gradient background
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

          /// 🌫️ Semi-transparent background image
          IgnorePointer(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),

          /// ☀️ Top light beam
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

          /// 📜 Main content
          SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('abc_models')
                      .snapshots(),
              builder: (ctxAll, allSnap) {
                if (allSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF64C8F2)),
                  );
                }

                final diaryDocs =
                    allSnap.data?.docs
                        .where(
                          (d) =>
                              (d.data()['group_id'] as String?)?.isNotEmpty ==
                              true,
                        )
                        .toList() ??
                    [];

                // group_id별로 분류
                final Map<
                  String,
                  List<QueryDocumentSnapshot<Map<String, dynamic>>>
                >
                diariesByGroup = {};
                for (var d in diaryDocs) {
                  final gid = d.data()['group_id'] as String;
                  diariesByGroup.putIfAbsent(gid, () => []).add(d);
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('abc_group')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                  builder: (ctxGrp, grpSnap) {
                    if (grpSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF64C8F2),
                        ),
                      );
                    }

                    final archivedDocs =
                        grpSnap.data?.docs
                            .where((d) => d.data()['archived'] == true)
                            .toList() ??
                        [];

                    if (archivedDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          '보관된 걱정 그룹이 없습니다 🪸',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    archivedDocs.sort((a, b) {
                      final aTs =
                          (a.data()['archived_at'] as Timestamp?)?.toDate() ??
                          DateTime(0);
                      final bTs =
                          (b.data()['archived_at'] as Timestamp?)?.toDate() ??
                          DateTime(0);
                      return bTs.compareTo(aTs);
                    });

                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width:
                                  MediaQuery.of(context).size.width > 480
                                      ? 420
                                      : double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    '보관된 걱정 그룹',
                                    style: TextStyle(
                                      fontFamily: 'Noto Sans KR',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF002E4F),
                                      shadows: [
                                        Shadow(
                                          offset: Offset(0, 2),
                                          blurRadius: 6,
                                          color: Colors.white54,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  for (final doc in archivedDocs)
                                    _buildArchiveCard(
                                      context,
                                      doc,
                                      diariesByGroup,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🪸 Mindrium-style archive card
  Widget _buildArchiveCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
    diariesByGroup,
  ) {
    final data = doc.data();
    final groupId = data['group_id']?.toString() ?? '';
    final title = data['group_title']?.toString() ?? '(제목 없음)';
    final contents = data['group_contents']?.toString() ?? '';
    final timestamp = data['archived_at'] as Timestamp?;
    final archivedAt = timestamp?.toDate() ?? DateTime.now();
    final archivedStr = DateFormat('yyyy.MM.dd HH:mm').format(archivedAt);
    final count = diariesByGroup[groupId]?.length ?? 0;

    return GestureDetector(
      onTap: () {
        Future.delayed(const Duration(milliseconds: 120), () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const NotificationSelectionScreen(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD0F2FF), Color(0xFFB9E8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white.withOpacity(0.6),
              child: ClipOval(
                child: Image.asset(
                  'assets/image/character$groupId.png',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          const Icon(Icons.folder, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans KR',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003B5C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    contents,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Noto Sans KR',
                      fontSize: 13.5,
                      color: Color(0xFF1B405C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '보관일시: $archivedStr',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF345A73),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '일기 $count개',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF007BA7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF007BA7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
