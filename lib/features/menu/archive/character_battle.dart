// File: character_battle.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/features/menu/archive/character_battle_asr.dart';
import 'dart:async'; // 말풍선 타이머용

class PokemonBattleDeletePage extends StatefulWidget {
  final String groupId;
  String? characterName;
  String? characterDescription;
  final VoidCallback? onGoArchive;

  PokemonBattleDeletePage({
    super.key,
    required this.groupId,
    this.characterName,
    this.characterDescription,
    this.onGoArchive,
  });

  @override
  _PokemonBattleDeletePageState createState() => _PokemonBattleDeletePageState();
}

class _PokemonBattleDeletePageState extends State<PokemonBattleDeletePage>
    with TickerProviderStateMixin {
  // Firestore에서 불러온 스킬 리스트
  List<String> _skillsList = [];
  bool _isLoading = true;
  bool _isDefeated = false;

  List<String> _characterEmotions = []; // 여러 감정을 담는 리스트
  int _currentEmotionIndex = 0;         // 현재 표시 중인 감정 인덱스
  bool _isBubbleVisible = true;

  // HP 관련
  int _maxHp = 0;
  int _targetHp = 0;

  // 상태
  bool _isAttacking = false;
  String? _selectedSkill;

  // 애니메이션
  late final AnimationController _shakeController;
  late final AnimationController _scoreController;

  // ✅ 추가: 캐릭터 이름/설명 상태 변수
  String? _characterName;
  String? _characterDescription;

  late final CharacterBattleAsr _voice;
  bool _listening = false;
  String _recognized = '';

  // 칩 shrink와 말풍선 관리
  final Set<int> _shrunkChips = {};
  String? _bubbleText;
  Timer? _bubbleTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: -4,
      upperBound: 4,
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _shakeController.reverse();
      });

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _voice = CharacterBattleAsr();
    _voice.initialize(
      onStatus: (s) {
        if (s == 'notListening' && mounted) setState(() => _listening = false);
      },
      onError: (e) {
        if (mounted) setState(() => _listening = false);
      },
    );

    _loadSkillsFromFirestore();
    _loadCharacterInfo();
    _startEmotionCycle(); // ✅ 추가

  }

  @override
  void dispose() {
    _voice.dispose();
    _bubbleTimer?.cancel();
    _shakeController.dispose();
    _scoreController.dispose();
    super.dispose();
  }



  Future<void> _loadCharacterInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // ──────────────────────────────
      // ① group 정보 (이름 + 설명)
      // ──────────────────────────────
      final groupSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_group')
          .where('group_id', isEqualTo: widget.groupId)
          .limit(1)
          .get();

      if (groupSnapshot.docs.isNotEmpty) {
        final groupData = groupSnapshot.docs.first.data();
        _characterName = groupData['group_title']?.toString() ?? '이름 없음';
        _characterDescription =
            groupData['group_contents']?.toString() ?? '설명 없음';
      }

      // ──────────────────────────────
      // ② group_id 기준으로 감정(consequence_emotion) 불러오기
      // ──────────────────────────────
      final modelSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .where('group_id', isEqualTo: widget.groupId)
          .get();

      // 🧠 대체 생각 불러올 때와 같은 구조로 감정 모으기
      final Set<String> emotions = {};
      for (final doc in modelSnapshot.docs) {
        final data = doc.data();

        // 감정은 단일 문자열 또는 리스트일 수 있으므로 모두 처리
        final dynamic emotionData = data['belief'];

        if (emotionData is String && emotionData.trim().isNotEmpty) {
          emotions.add(emotionData.trim());
        } else if (emotionData is List) {
          for (final e in emotionData) {
            if (e is String && e.trim().isNotEmpty) {
              emotions.add(e.trim());
            }
          }
        }
      }

      setState(() {
        _characterEmotions =
            emotions.isNotEmpty ? emotions.toList() : ['감정 데이터가 없습니다.'];
        _currentEmotionIndex = 0;
      });
    } catch (e) {
      debugPrint('❌ Firestore 감정 불러오기 실패: $e');
      setState(() {
        _characterEmotions = ['데이터를 불러오지 못했습니다.'];
      });
    }
  }

  Future<void> _loadSkillsFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
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

  void _onAttack() {
    if (_isAttacking || _isDefeated || _selectedSkill == null) return;

    setState(() => _isAttacking = true);
    _shakeController.forward(from: 0);
    _scoreController.forward(from: 0); // +10 떠오르기

    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        _targetHp = max(0, _targetHp - 1);
        _skillsList.remove(_selectedSkill);
        _selectedSkill = null;
        _isAttacking = false;
        if (_targetHp == 0) _isDefeated = true;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
      );
    }

    // 에셋 경로는 기존과 동일 사용
    const bgImage = 'assets/image/battle_scene_bg.png';
    final myChar = 'assets/image/men.png';
    final target = 'assets/image/character${widget.groupId}.png';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF222222),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          '불안 격파 챌린지',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset(bgImage, fit: BoxFit.cover)),

          // 1) 상단 안내 배너
          _buildTopBanner(),

          // 2) HP 패널 (제목/설명/HP바)
          _buildHpPanel(),

          // 3) 캐릭터들 (오른쪽 상대, 왼쪽 사용자)
          _buildCharacters(myChar, target),

          // 5) 우측 원형 마이크 버튼
          _buildMicButton(),

          // 6) 하단 스킬 바
         _buildBottomBar(),

          // 7) 승리 오버레이
          if (_isDefeated)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.92),
                child: _buildVictoryScene(),
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────── UI 구성 ─────────────────

  Widget _buildTopBanner() {
  return Positioned(
    top: 16,
    left: 16,
    right: 16,
    child: Container(
      alignment: Alignment.center, // ✅ 텍스트를 컨테이너 중앙 배치
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 65, 79, 79).withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 65, 79, 79).withOpacity(0.4),
            blurRadius: 10, // 흐림 정도
            spreadRadius: 5, // 확산 정도
          ),
        ],
      ),
      child: Text(
        '대체 생각을 말하고\n$_characterName을 물리치세요!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.25,
          fontWeight: FontWeight.w800,
        ),
        textAlign: TextAlign.center, // ✅ 텍스트 줄바꿈 포함 중앙 정렬
      ),
    ),
  );
}

  Widget _buildHpPanel() {
    return Positioned(
      // 기존 top:108 → 캐릭터 기준으로 이동
      top: 190,
      right: 200, // 캐릭터 바로 옆
      child: Container(
        width: 150, // 크기 축소
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _characterName ?? '불안한 캐릭터',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _characterDescription ?? '불안해하고 있습니다',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 6),
            _buildHpBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacters(String myChar, String targetChar) {
    // 살짝 흔들림(타격감)
    final dx = _shakeController.value;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ─────────────── 🧍 상대 캐릭터 (오른쪽 위) ───────────────
        Positioned(
          top: 210,
          right: 24 + dx, // 타격 흔들림 효과
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 💬 말풍선 (감정 표시)
              if (_characterEmotions.isNotEmpty)
                Positioned(
                  top: -60,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeIn,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _isBubbleVisible
                        ? _buildEmotionBubble(_bubbleText ??
                            _characterEmotions[_currentEmotionIndex],
                            key: ValueKey("visible_$_currentEmotionIndex"),
                          )
                        : const SizedBox.shrink(key: ValueKey("hidden")),
                  ),
                ),

              // 🧠 걱정 캐릭터 이미지
              Image.asset(
                targetChar,
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.error,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // ─────────────── 🙋 내 캐릭터 (왼쪽 아래) ───────────────
        Positioned(
          left: 8,
          bottom: 160,
          child: Image.asset(
            myChar,
            height: 220,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionBubble(String text, {Key? key}) {
    return Container(
      key: key,
      constraints: const BoxConstraints(maxWidth: 180, minHeight: 40),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 🩵 타원형 말풍선
          ClipOval(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              color: Colors.white.withOpacity(0.95),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startEmotionCycle() async {
    while (mounted) {
      // 3초간 표시됨
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) break;

      setState(() => _isBubbleVisible = false); // 말풍선 사라짐

      // 사라진 상태 유지 (0.8초 정도)
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) break;

      setState(() {
        // 다음 감정으로 전환
        if (_characterEmotions.isNotEmpty) {
          _currentEmotionIndex =
              (_currentEmotionIndex + 1) % _characterEmotions.length;
        }
        _isBubbleVisible = true; // 다시 나타남
      });
    }
  }


  Widget _buildMicButton() {
    return Positioned(
      bottom: 160,
      right: 40,
      child: GestureDetector(
        onTap: () async {
          if (_isAttacking || _isDefeated) return;

          if (_listening) {
            // 이미 듣고 있다면 중지
            await _voice.stop();
            setState(() => _listening = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('음성인식이 중지되었습니다.'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          // 음성인식 시작
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎙️ 음성인식을 시작합니다. 말을 해보세요!'),
              duration: Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );

          await _onMicPressed(); // ✅ 음성인식 함수 실행
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _listening
                ? const Color(0xFF56E0C6).withOpacity(0.9) // 듣는 중일 땐 밝게
                : const Color.fromARGB(255, 65, 79, 79).withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _listening ? Icons.hearing : Icons.mic,
                color: Colors.white,
                size: 60,
              ),
              const SizedBox(height: 4),
              Text(
                _listening ? '듣는 중...' : '터치하여\n마이크 켜기',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*
          if (_selectedSkill != null && !_isAttacking && !_isDefeated) {
            _onAttack();
          } else {
            String msg = '';
            if (_isDefeated) {
              msg = '이미 불안을 물리쳤습니다!';
            } else if (_isAttacking) {
              msg = '공격 중입니다... 잠시만요!';
            } else {
              msg = '스킬(대체 생각)을 먼저 선택하세요!';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          */
  void _handleVoiceChoice(String utter) {
    final text = utter.trim();
    if (text.isEmpty || _skillsList.isEmpty) return;

    final idx = _chooseBestIndex(_skillsList, text);
    if (idx < 0) return;

    final chosen = _skillsList[idx];
    final score = _similarity(text.toLowerCase(), chosen.toLowerCase());

    // ✅ 유사도 0.4 미만이면 무시
    if (score < 0.4) {
      debugPrint('❌ [무시됨] "$text" vs "$chosen" (유사도 ${score.toStringAsFixed(2)})');
      return;
    }

    debugPrint('✅ [선택됨] "$text" → "$chosen" (유사도 ${score.toStringAsFixed(2)})');

    // 💬 말풍선 표시
    _bubbleTimer?.cancel();
    setState(() {
      _bubbleText = chosen;
      _isBubbleVisible = true;
    });
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _bubbleText = null;
        _isBubbleVisible = false;
      });
    });

    // 🧩 칩 shrink 및 HP 감소
    setState(() {
      _selectedSkill = chosen;
      _shrunkChips.add(idx);
    });

    if (_targetHp > 0) {
      setState(() => _targetHp = _targetHp - 1);
      if (_targetHp == 0) {
        setState(() => _isDefeated = true);
      }
    }
  }

  void _showToast(String msg) {
    if (!mounted || msg.trim().isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar(); // 이전 토스트 제거
    messenger.showSnackBar(
      SnackBar(
        content: Text('음성인식 결과: $msg', maxLines: 2, overflow: TextOverflow.ellipsis),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }



  int _chooseBestIndex(List<String> skills, String utter) {
    final q = utter.toLowerCase();
    double best = -1;
    int bestIdx = -1;
    for (int i = 0; i < skills.length; i++) {
      final s = skills[i].toLowerCase();
      final score = _similarity(q, s);
      if (score > best) { best = score; bestIdx = i; }
    }
    return bestIdx;
  }

  double _similarity(String a, String b) {
    final ta = a.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).toSet();
    final tb = b.split(RegExp(r'\s+')).where((e)=>e.isNotEmpty).toSet();
    if (ta.isEmpty || tb.isEmpty) return (a.contains(b) || b.contains(a)) ? 1.0 : 0.0;
    final inter = ta.intersection(tb).length.toDouble();
    final union = (ta.length + tb.length - inter).toDouble();
    final j = union == 0 ? 0.0 : inter / union;
    final contain = (a.contains(b) || b.contains(a)) ? 0.3 : 0.0;
    return j + contain;
  }

  Future<void> _onMicPressed() async {
    if (_isAttacking || _isDefeated) return;

    setState(() {
      _listening = true;
      _recognized = '';
    });

    await _voice.startListening(
      localeId: 'ko_KR',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onPartial: (t) {
        if (!mounted) return;
        setState(() => _recognized = t);
        // 🔹 실시간 중간 인식 로그 출력
        debugPrint('[🎙️ Partial Recognition] $t');
      },
      onFinal: (t) async {
        if (!mounted) return;
        setState(() {
          _recognized = t;
          _listening = false;
        });

        // ✅ 디버그 콘솔에 최종 인식 결과 출력
        if (t.trim().isNotEmpty) {
          debugPrint('[✅ Final Recognition Result] "$t"');
        } else {
          debugPrint('[⚠️ Final Recognition] Empty result');
        }

        _showToast(t);
        _handleVoiceChoice(t);
      },

    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 50,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 65, 79, 79).withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // ← 전체 중앙 정렬
          children: [
            // 안내 문구 (중앙 정렬)
            const Center(
              child: Text(
                '스킬(대체 생각)을 골라 공격하세요!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _skillsList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  if (_shrunkChips.contains(idx)) {
                    // ✅ 선택된 칩은 shrink 처리
                    return const SizedBox.shrink();
                  }

                  final skill = _skillsList[idx];
                  final selected = skill == _selectedSkill;

                  return ChoiceChip(
                    label: Text(skill, overflow: TextOverflow.ellipsis),
                    selected: selected,
                    onSelected: (v) {
                      if (!_isAttacking && !_isDefeated && v) {
                        setState(() => _selectedSkill = skill);
                      }
                    },
                    labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
                    selectedColor: const Color(0xFF56E0C6),
                    backgroundColor: Colors.white12,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                },
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }


  Widget _buildHpBar() {
    final factor = _targetHp / max(1, _maxHp);
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: factor,
        child: Container(
          decoration: BoxDecoration(
            // 보라색 HP바
            color: const Color(0xFF9C60FF),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
          ),
        ),
      ),
    );
  }

  // 승리 화면
  Widget _buildVictoryScene() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, size: 72, color: Color(0xFFFFD54F)),
          const SizedBox(height: 16),
          const Text(
            '축하합니다!',
            style: TextStyle(
              color: Color(0xFF2CE0B7),
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
            width: 220,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _archiveGroup();
                if (widget.onGoArchive != null) {
                  widget.onGoArchive!.call();
                  return;
                }
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (_) => false,
                  arguments: {'initialIndex': 2},
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

class _SpeechTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.95);
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}