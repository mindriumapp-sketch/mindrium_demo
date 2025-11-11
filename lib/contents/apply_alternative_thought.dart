import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/4th_treatment/week4_alternative_thoughts.dart';
import 'package:provider/provider.dart';
import 'package:gad_app_team/data/user_provider.dart';

/// DB에 저장된 B(생각) 리스트를 불러와 사용자가 선택하면
/// Week4AlternativeThoughtsScreen으로 이동하는 화면
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
    if (_bList.isEmpty && !_loading) {
      _fetchBeliefs();
    }
  }

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
        if (!doc.exists || data == null) {
          throw Exception('해당 ABC를 찾을 수 없습니다.');
        }
        list = _parseBeliefList(data['belief']);
        _abcId = doc.id;

        if (list.isEmpty) {
          final dynamic rawGroup = data['group_id'] ?? data['groupId'];
          final groupId = rawGroup?.toString();
          if (groupId != null && groupId.isNotEmpty) {
            list = await _loadGroupBeliefs(firestore, uid, groupId);
          }
        }

        if (list.isEmpty) {
          list = await _loadAllBeliefs(firestore, uid);
        }
      } else {
        list = await _loadAllBeliefs(firestore, uid);
        if (list.isEmpty) {
          throw Exception('저장된 일기를 찾을 수 없습니다.');
        }
        _abcId = await _latestAbcId(firestore, uid);
      }
      setState(() {
        _bList = list;
        _loading = false;
      });
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
      final data = doc.data();
      final items = _parseBeliefList(data['belief']);
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
      final data = doc.data();
      final items = _parseBeliefList(data['belief']);
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
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.id;
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
      final s = belief.trim();
      if (s.isEmpty) return const [];
      final parts =
          s
              .split(RegExp(r'[,\n;]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
      return parts.isEmpty ? [s] : parts;
    }
    final s = belief.toString().trim();
    return s.isEmpty ? const [] : [s];
  }

  void _onSelect(String b) {
    final all = _bList;
    final remaining = List<String>.from(all)..remove(b);
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final dynamic diary = args['diary'];
    debugPrint('[apply_alt_thought] abcId=$_abcId, diary=$diary');
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
    return Scaffold(
      appBar: const CustomAppBar(title: '도움이 되는 생각 찾기'),
      backgroundColor: const Color(0xFFFBF8FF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                    : Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28.0,
                          vertical: 32.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$userName님',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5B3EFF),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 48,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF5B3EFF,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              '어떤 생각을 대상으로 도움이 되는 생각을 찾아볼까요?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_bList.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text('저장된 생각(B)이 없습니다.'),
                              )
                            else
                              Flexible(
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: _bList.length,
                                  separatorBuilder:
                                      (_, __) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final b = _bList[index];
                                    final selected = _selectedIndex == index;
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color:
                                              selected
                                                  ? const Color(0xFF2962F6)
                                                  : Colors.grey.shade300,
                                          width: selected ? 2 : 1,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        value: selected,
                                        onChanged: (v) {
                                          setState(() {
                                            _selectedIndex =
                                                v == true ? index : null;
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        title: Text(b),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed:
                                    (_selectedIndex != null &&
                                            _bList.isNotEmpty)
                                        ? () {
                                          final b = _bList[_selectedIndex!];
                                          _onSelect(b);
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2962F6),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  '도움이 되는 생각을 찾아볼게요!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}
