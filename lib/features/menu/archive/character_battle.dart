// File: character_battle.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PokemonBattleDeletePage extends StatefulWidget {
  final String groupId;

  const PokemonBattleDeletePage({super.key, required this.groupId});

  @override
  _PokemonBattleDeletePageState createState() =>
      _PokemonBattleDeletePageState();
}

class _PokemonBattleDeletePageState extends State<PokemonBattleDeletePage>
    with TickerProviderStateMixin {
  // Firestore에서 불러온 스킬 리스트
  List<String> _skillsList = [];
  bool _isLoading = true;
  bool _isDefeated = false;

  // HP 관련
  int _maxHp = 0;
  int _targetHp = 0;

  // 상태
  bool _isAttacking = false;
  String? _selectedSkill;

  // 애니메이션
  late final AnimationController _shakeController;
  late final AnimationController _scoreController;

  // ───────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: -4,
      upperBound: 4,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
    });

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _loadSkillsFromFirestore();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────
  Future<void> _loadSkillsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('abc_models')
              .where('group_id', isEqualTo: widget.groupId)
              .get();

      final Set<String> skills = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final List<dynamic>? alternatives = data['alternative_thoughts'];
        if (alternatives != null) {
          for (final item in alternatives) {
            if (item is String && item.trim().isNotEmpty) {
              skills.add(item.trim());
            }
          }
        }
      }

      setState(() {
        _skillsList = skills.isNotEmpty ? skills.toList() : ['대체 생각이 없습니다.'];
        _maxHp = _skillsList.length;
        _targetHp = _maxHp;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Firestore 불러오기 실패: $e');
      setState(() {
        _skillsList = ['데이터를 불러오지 못했습니다.'];
        _maxHp = 1;
        _targetHp = 1;
        _isLoading = false;
      });
    }
  }

  // ───────────────────────────────────────────────────────────
  void _onAttack() {
    if (_selectedSkill == null || _isAttacking || _isDefeated) return;

    setState(() => _isAttacking = true);
    _shakeController.forward(from: 0);
    _scoreController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _targetHp = max(0, _targetHp - 1);
        _skillsList.remove(_selectedSkill);
        _selectedSkill = null;
        _isAttacking = false;

        if (_targetHp == 0) {
          _isDefeated = true;
          _archiveGroup();
        }
      });
    });
  }

  Future<void> _archiveGroup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_group');
      final qs = await col.where('group_id', isEqualTo: widget.groupId).get();

      for (final doc in qs.docs) {
        await doc.reference.update({
          'archived': true,
          'archived_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('❌ 그룹 archived 처리 실패: $e');
    }
  }

  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
      );
    }

    const bgImage = 'assets/image/delete.png';
    final myChar  = 'assets/image/men.png';
    final target  = 'assets/image/character${widget.groupId}.png';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF222222),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '불안 격파 챌린지',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          // 바다 배경
          Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.cover)),

          // 상단 검은 배너 + 안내문 (예시 UI의 어두운 바)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 44,
              color: const Color(0xFF2A2A2A).withOpacity(0.92),
              alignment: Alignment.center,
              child: const Text(
                '대체 생각으로 불안을 물리치세요!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // 전투 장면 구성 (사람/캐릭터/하단 패널)
          _buildBattleScene(myChar, target),
        ],
      ),
    );
  }



  Widget _buildBattleScene(String myChar, String targetChar) {
  return Stack(
    children: [
      // 🐳 불안 캐릭터 - 오른쪽 위
      Positioned(
        top: 64, // 상단 배너 아래로
        right: 18,
        child: Column(
          children: [
            Image.asset(
              targetChar,
              height: 170,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.error, size: 100, color: Colors.white),
            ),
          ],
        ),
      ),

      // 👤 사람 캐릭터 - 왼쪽 아래
      Positioned(
        left: 18,
        bottom: 168, // 하단 패널 위로
        child: Image.asset(
          myChar,
          height: 200,
          fit: BoxFit.contain,
        ),
      ),

      // 🌑 하단 암색 패널 (HP/스킬칩/공격)
      Positioned(
        left: 10,
        right: 10,
        bottom: 10,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A).withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HP 라벨
              Text(
                'HP: $_targetHp/$_maxHp',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // HP 바 (민트색)
              _buildHpBar(),
              const SizedBox(height: 10),

              // 안내 텍스트
              const Text(
                '스킬(대체 생각)을 골라 공격하세요!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),

              // 스킬 칩 (수평 스크롤)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _skillsList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final skill = _skillsList[idx];
                    final selected = skill == _selectedSkill;
                    return ChoiceChip(
                      label: Text(
                        skill,
                        overflow: TextOverflow.ellipsis,
                      ),
                      selected: selected,
                      onSelected: (v) {
                        if (!_isAttacking && !_isDefeated && v) {
                          setState(() => _selectedSkill = skill);
                        }
                      },

                      labelStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                      ),
                      selectedColor: const Color(0xFF56E0C6), // 민트
                      backgroundColor: Colors.white12,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // 공격 버튼 (전체 폭, 어두운 회색)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedSkill != null && !_isAttacking && !_isDefeated)
                      ? _onAttack
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A4A4A),
                    disabledBackgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('공격', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


  Widget _buildHpBar() {
    return Container(
      width: 200,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: _targetHp / max(1, _maxHp),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // 승리 화면: 트로피 + 축하문구 + 보관함으로 이동 버튼
  Widget _buildVictoryScene() {
    return Container(
      color: Colors.black, // 예시처럼 검은 배경
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 72, color: Color(0xFFFFD54F)),
          const SizedBox(height: 16),
          const Text(
            '축하합니다!',
            style: TextStyle(
              color: Color(0xFF2CE0B7), // 민트-그린
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '당신의 불안이 보관함으로 이동되었습니다.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () {
                // 보관함 화면으로 이동 (필요시 경로만 바꿔)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/archive_sea',
                  (_) => false,
                );
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('보관함으로 이동'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2CE0B7),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
