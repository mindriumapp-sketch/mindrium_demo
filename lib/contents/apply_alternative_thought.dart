import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';
import 'package:gad_app_team/features/4th_treatment/week4_alternative_thoughts.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';

/// 💡 Firestore의 'belief' 필드(B 리스트)를 불러와 선택 후 다음 단계로 이동하는 화면
class ApplyAlternativeThoughtScreen extends StatefulWidget {
  const ApplyAlternativeThoughtScreen({super.key});

  @override
  State<ApplyAlternativeThoughtScreen> createState() =>
      _ApplyAlternativeThoughtScreenState();
}

class _ApplyAlternativeThoughtScreenState
    extends State<ApplyAlternativeThoughtScreen> {
  bool _loading = false;
  String? _error;
  List<String> _bList = const [];
  String? _abcId;
  int _beforeSud = 0;
  int? _selectedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    _abcId = args['abcId'] as String?;
    _beforeSud = (args['beforeSud'] as int?) ?? 0;
    if (_bList.isEmpty && !_loading) _fetchBeliefs();
  }

  /// 🔹 Firestore에서 'belief' 리스트 로드
  Future<void> _fetchBeliefs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid =
          FirebaseAuth.instance.currentUser?.uid ?? prefs.getString('uid');
      if (uid == null || uid.isEmpty) {
        throw Exception('사용자 식별자를 찾을 수 없습니다.');
      }

      final firestore = FirebaseFirestore.instance;
      List<String> list;

      if (_abcId != null && _abcId!.isNotEmpty) {
        final doc =
            await firestore
                .collection('users')
                .doc(uid)
                .collection('abc_models')
                .doc(_abcId)
                .get();

        final data = doc.data();
        if (!doc.exists || data == null) throw Exception('해당 ABC를 찾을 수 없습니다.');
        list = _parseBeliefList(data['belief']);
        _abcId = doc.id;

        if (list.isEmpty) {
          final groupId = (data['group_id'] ?? data['groupId'])?.toString();
          if (groupId != null && groupId.isNotEmpty) {
            list = await _loadGroupBeliefs(firestore, uid, groupId);
          }
        }
        if (list.isEmpty) list = await _loadAllBeliefs(firestore, uid);
      } else {
        list = await _loadAllBeliefs(firestore, uid);
        if (list.isEmpty) throw Exception('저장된 일기를 찾을 수 없습니다.');
        _abcId = await _latestAbcId(firestore, uid);
      }

      if (mounted) {
        setState(() {
          _bList = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<List<String>> _loadGroupBeliefs(
    FirebaseFirestore firestore,
    String uid,
    String groupId,
  ) async {
    final qs =
        await firestore
            .collection('users')
            .doc(uid)
            .collection('abc_models')
            .where('group_id', isEqualTo: groupId)
            .get();

    final seen = <String>{};
    final acc = <String>[];
    for (final doc in qs.docs) {
      final items = _parseBeliefList(doc.data()['belief']);
      for (final item in items) {
        if (seen.add(item)) acc.add(item);
      }
    }
    return acc;
  }

  Future<List<String>> _loadAllBeliefs(
    FirebaseFirestore firestore,
    String uid,
  ) async {
    final snapshot =
        await firestore
            .collection('users')
            .doc(uid)
            .collection('abc_models')
            .orderBy('createdAt', descending: true)
            .get();

    final seen = <String>{};
    final acc = <String>[];
    for (final doc in snapshot.docs) {
      final items = _parseBeliefList(doc.data()['belief']);
      for (final item in items) {
        if (seen.add(item)) acc.add(item);
      }
    }
    return acc;
  }

  Future<String?> _latestAbcId(FirebaseFirestore firestore, String uid) async {
    final snapshot =
        await firestore
            .collection('users')
            .doc(uid)
            .collection('abc_models')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();
    return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
  }

  List<String> _parseBeliefList(dynamic belief) {
    if (belief == null) return const [];
    if (belief is List) {
      return belief
          .map((e) => e?.toString() ?? '')
          .where((s) => s.trim().isNotEmpty)
          .toList();
    }
    if (belief is String) {
      final parts =
          belief
              .split(RegExp(r'[,\n;]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      return parts.isEmpty ? [belief] : parts;
    }
    return [belief.toString()];
  }

  void _onSelect(String b) {
    final all = _bList;
    final remaining = List<String>.from(all)..remove(b);
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final diary = args['diary'];
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: RouteSettings(arguments: {'origin': 'apply', 'diary': diary}),
        builder:
            (_) => Week4AlternativeThoughtsScreen(
              previousChips: [b],
              beforeSud: _beforeSud,
              remainingBList: remaining,
              allBList: all,
              originalBList: all,
              abcId: _abcId,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.read<UserProvider>().userName;

    return InnerBtnCardScreen(
      appBarTitle: '도움이 되는 생각 찾기',
      title: '$userName님,\n어떤 생각을 대상으로 찾아볼까요?',
      primaryText: '도움이 되는 생각을 찾아볼게요!',
      onPrimary:
          (_selectedIndex != null && _bList.isNotEmpty)
              ? () {
                final b = _bList[_selectedIndex!];
                _onSelect(b);
              }
              : () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('생각을 선택해주세요.')));
              },
      // ✅ 리스트 렌더링 복구 (Flexible + shrinkWrap)
      child:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
              : _bList.isEmpty
              ? const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '저장된 생각(B)이 없습니다.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
              )
              : Flexible(
                // 👇 ListView가 안 보이던 문제 해결
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _bList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = _bList[index];
                    final selected = _selectedIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color:
                              selected
                                  ? const Color(0xFF47A6FF).withOpacity(0.15)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected
                                    ? const Color(0xFF47A6FF)
                                    : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 15.5,
                            color:
                                selected
                                    ? const Color(0xFF0B5394)
                                    : Colors.black87,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                            fontFamily: 'Noto Sans KR',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
