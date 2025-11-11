import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'abc_group_add_screen.dart';
import '../menu/archive/character_battle.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🌊 완전투명 CustomAppBar 호환 배경 Wrapper
class MindriumBackgroundWrapper extends StatelessWidget {
  final Widget child;
  const MindriumBackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF003B5C), Color(0xFF4EB4E5), Color(0xFFBFF4FF)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 260,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.25), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class AbcGroupScreen extends StatefulWidget {
  final String? label;
  final String? abcId;
  final String? origin;
  const AbcGroupScreen({super.key, this.label, this.abcId, this.origin});

  @override
  State<AbcGroupScreen> createState() => _AbcGroupScreenState();
}

class _AbcGroupScreenState extends State<AbcGroupScreen> {
  /// 현재 펼쳐진 카드 인덱스 (-1 = 모두 접힘)
  int _selectedIndex = -1;

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> group,
    DocumentReference<Map<String, dynamic>> docRef,
  ) {
    final titleCtrl = TextEditingController(text: group['group_title'] ?? '');
    final contentsCtrl = TextEditingController(text: group['group_contents'] ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE9F8FF), Color(0xFFBFEAFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '그룹 편집',
                    style: TextStyle(
                      fontFamily: 'Noto Sans KR',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: Color(0xFF003A64),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: '제목',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentsCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '설명',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('수정'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BA7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await docRef.update({
                        'group_title': titleCtrl.text,
                        'group_contents': contentsCtrl.text,
                      });
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddCard() {
    return GestureDetector(
      onTap: () {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!mounted) return;
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const AbcGroupAddScreen1(),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          );
        });
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8FDFFF), Color(0xFFC4F5FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(173, 216, 230, 0.4),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: Color(0xFF0E4569),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                '그룹 추가',
                style: TextStyle(
                  fontFamily: 'Noto Sans KR',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF0E4569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 드롭다운(펼침) 내용 위젯: 일기 개수/설명 전체/생성일/버튼들
  Widget _ExpandedGroupBody({
  required String uid,
  required String groupId,
  required String fullContents,
  required Timestamp? createdAt,
  required String groupTitle,
  }) {
    final createdStr = (createdAt == null)
        ? '-'
        : '${createdAt.toDate().year}.${createdAt.toDate().month.toString().padLeft(2, '0')}.${createdAt.toDate().day.toString().padLeft(2, '0')}';

    final diariesStream = FirebaseFirestore.instance
        .collection('users').doc(uid)
        .collection('abc_models')
        .where('group_id', isEqualTo: groupId)
        .snapshots();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: diariesStream,
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          final abcIds = docs.map((e) => e.id).toList();

          return FutureBuilder<double?>(
            future: _avgAfterSud(uid, abcIds),
            builder: (context, avgSnap) {
              final hasScore = avgSnap.data != null;
              final avg = (avgSnap.data ?? 0).clamp(0, 10);
              final ratio = hasScore ? avg / 10.0 : 0.0;
              final barColor =
                  Color.lerp(Colors.green, Colors.red, ratio) ?? Colors.red;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 + 점수 텍스트
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '주관적 불안점수 (2점 이하 시 삭제 가능)',
                        style: TextStyle(fontSize: 13.5, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: hasScore ? ratio : 0.0,
                            backgroundColor: Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(barColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${avg.toStringAsFixed(1)}/10',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 생성일 / 일기 n개 >
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('생성일: $createdStr',
                          style: const TextStyle(fontSize: 13, color: Colors.black87)),
                      InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/diary_directory',
                            arguments: {'groupId': groupId},
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '일기 ${docs.length}개',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2D5BFF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right,
                                size: 16, color: Colors.black45),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 불안 삭제 버튼 (평균 ≤ 2.0일 때만 활성)
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53B3B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: hasScore && avg <= 2.0
                      ? () {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => AlertDialog(
                              title: Text('정말 "$groupTitle" 그룹을 삭제하시겠습니까?'),
                              content: const Text('삭제된 그룹은 보관함에서 확인 가능합니다.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('No'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx); // 팝업 닫기
                                    // ✅ app_battle 실행
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PokemonBattleDeletePage(groupId: groupId),
                                      ),
                                    );
                                  },
                                  child: const Text('Yes'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                      child: const Text('불안 삭제'),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int i,
    String uid,
  ) {
    final data = doc.data();
    final groupId = (data['group_id'] ?? '').toString();
    final title = (data['group_title'] ?? '제목 없음').toString();
    final contents = (data['group_contents'] ?? '').toString();
    final createdAt = data['createdAt'] as Timestamp?;

    final selected = _selectedIndex == i;

    return GestureDetector(
      onTap: () {
        setState(() {
          // 같은 카드 다시 탭하면 접힘
          _selectedIndex = selected ? -1 : i;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: selected
                ? [const Color(0xFFD0F2FF), const Color(0xFFB9E8FF)]
                : [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF007BA7) : Colors.white.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color.fromRGBO(0, 123, 167, 0.4)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── 카드 헤더
            Row(
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
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.folder, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Noto Sans KR',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: selected
                              ? const Color(0xFF007BA7)
                              : const Color(0xFF103050),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contents.isEmpty ? ' ' : contents,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Noto Sans KR',
                          fontSize: 13,
                          color: Color(0xFF1B405C),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF004C73), size: 22),
                  onPressed: () => _showEditDialog(context, data, doc.reference),
                ),
              ],
            ),

            // ── 드롭다운 영역
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState:
                  selected ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _ExpandedGroupBody(
                  uid: uid,
                  groupId: groupId,
                  fullContents: contents,
                  createdAt: createdAt,
                  groupTitle: title, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('abc_group')
          .where('archived', isNotEqualTo: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF007BA7)),
          );
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Text(
            '등록된 걱정 그룹이 없습니다.\n상단 메뉴에서 새 그룹을 추가할 수 있습니다.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          );
        }
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildAddCard(),
              const SizedBox(height: 18),
              for (int i = 0; i < docs.length; i++) ...[
                _buildGroupCard(docs[i], i, uid),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }

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
        title: '걱정 그룹 관리',
        showHome: true,
        confirmOnHome: false,
        confirmOnBack: false,
        onBack: () async {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
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

            if (mounted) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/menu');
              }
            }

            await Future.delayed(const Duration(milliseconds: 100));
            if (Navigator.canPop(context)) Navigator.pop(context);
          }
        },
      ),
      body: MindriumBackgroundWrapper(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: MediaQuery.of(context).size.width > 480 ? 420 : double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.2),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildGroupList(uid),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ ADD: 각 그룹의 after_sud 평균을 계산(없으면 null)
  Future<double?> _avgAfterSud(String uid, List<String> abcIds) async {
    if (abcIds.isEmpty) return null;
    final fs = FirebaseFirestore.instance;
    int sum = 0, cnt = 0;

    for (final id in abcIds) {
      final qs = await fs
          .collection('users').doc(uid)
          .collection('abc_models').doc(id)
          .collection('sud_score')
          .get();

      int? after;
      for (final d in qs.docs) {
        final v = d.data()['after_sud'];
        if (v is int) after = v;
        else if (v is num) after = v.toInt();
        if (after != null) break;
      }
      if (after != null) {
        sum += after.clamp(0, 10);
        cnt++;
      }
    }
    if (cnt == 0) return null;
    return sum / cnt;
  }

}
