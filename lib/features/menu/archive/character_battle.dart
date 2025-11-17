import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gad_app_team/features/menu/archive/character_battle_asr.dart';
import 'dart:async';

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
  
  // ========== 데이터 ==========
  List<String> _skillsList = [];
  List<String> _characterEmotions = [];
  bool _isLoading = true;
  bool _isDefeated = false;

  String? _characterName;
  String? _characterDescription;

  // ========== HP ==========
  int _maxHp = 0;
  int _targetHp = 0;

  // ========== 상태 ==========
  bool _isAttacking = false;
  String? _selectedSkill;
  final Set<int> _shrunkChips = {};

  // ========== 애니메이션 ==========
  late final AnimationController _shakeController;
  late final AnimationController _scoreController;

  // ========== 음성인식 ==========
  late final CharacterBattleAsr _voice;
  bool _listening = false;
  String _recognized = '';
  DateTime? _listenStartedAt;
  Timer? _autoStopTimer;

  // ========== 말풍선 ==========
  int _currentEmotionIndex = 0;
  bool _isBubbleVisible = true;
  String? _bubbleText;
  Timer? _bubbleTimer;

  // 사용자 말풍선 추가
  String? _userBubbleText;
  bool _isUserBubbleVisible = false;
  Timer? _userBubbleTimer;

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
    _initializeVoice();
    _loadSkillsFromFirestore();
    _loadCharacterInfo();
    _startEmotionCycle();
  }

  @override
  void dispose() {
    _voice.dispose();
    _bubbleTimer?.cancel();
    _userBubbleTimer?.cancel();
    _autoStopTimer?.cancel();
    _shakeController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  // ========== 초기화 ==========

  Future<void> _initializeVoice() async {
    debugPrint('🎤 [음성인식] 초기화 시작');

    final success = await _voice.initialize(
      onStatus: (s) {
        if (s == 'notListening' && mounted) {
          setState(() => _listening = false);
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _listening = false);
        }
      },
    );

    if (success) {
      debugPrint('✅ [음성인식] 초기화 성공');
    } else {
      debugPrint('❌ [음성인식] 초기화 실패');
    }
  }

  Future<void> _loadCharacterInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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
        _characterDescription = groupData['group_contents']?.toString() ?? '설명 없음';
      }

      final modelSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('abc_models')
          .where('group_id', isEqualTo: widget.groupId)
          .get();

      final Set<String> emotions = {};
      for (final doc in modelSnapshot.docs) {
        final data = doc.data();
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
        _characterEmotions = emotions.isNotEmpty
            ? emotions.toList()
            : ['감정 데이터가 없습니다'];
        _currentEmotionIndex = 0;
      });
    } catch (e) {
      debugPrint('❌ Firestore 감정 불러오기 실패: $e');
      setState(() {
        _characterEmotions = ['데이터를 불러오지 못했습니다'];
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
        _skillsList = skills.isNotEmpty
            ? skills.toList()
            : ['대체 생각이 없습니다'];
        _maxHp = _skillsList.length;
        _targetHp = _maxHp;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Firestore 불러오기 실패: $e');
      setState(() {
        _skillsList = ['데이터를 불러오지 못했습니다'];
        _maxHp = 1;
        _targetHp = 1;
        _isLoading = false;
      });
    }
  }

  // ========== 음성인식 ==========

  Future<void> _onMicPressed() async {
    debugPrint('🎤 [마이크 클릭]');

    if (_isAttacking || _isDefeated) {
      debugPrint('⚠️ [공격 중 또는 패배]');
      return;
    }

    if (!_voice.isReady) {
      debugPrint('❌ [준비 안됨] 재초기화');
      await _initializeVoice();
      if (!_voice.isReady) {
        _showErrorDialog();
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _listening = true;
      _recognized = '';
    });

    _listenStartedAt = DateTime.now();

    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(const Duration(seconds: 8), () async {
      debugPrint('⏰ [8초 타이머] 자동 종료');
      if (_listening && mounted) {
        await _voice.stop();
        final result = _recognized.trim();
        setState(() => _listening = false);

        if (result.isNotEmpty) {
          _showToast('인식됨: $result');
          _handleVoiceChoice(result);
        } else {
          _showToast('음성이 감지되지 않았습니다');
        }
      }
    });

    try {
      final success = await _voice.startListening(
        localeId: 'ko_KR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        onPartial: (t) {
          if (!mounted) return;
          setState(() => _recognized = t);
        },
        onFinal: (t) async {
          _autoStopTimer?.cancel();

          if (!mounted) return;
          setState(() {
            _recognized = t;
            _listening = false;
          });

          if (t.trim().isNotEmpty) {
            _showToast('인식 완료: $t');
            _handleVoiceChoice(t);
          } else {
            _showToast('음성이 인식되지 않았습니다');
          }
        },
      );

      if (!success) {
        _autoStopTimer?.cancel();
        setState(() => _listening = false);
        _showErrorDialog();
      }
    } catch (e) {
      debugPrint('❌ [예외] $e');
      _autoStopTimer?.cancel();
      setState(() => _listening = false);
      _showErrorDialog();
    }
  }

  void _handleVoiceChoice(String utter) {
    final text = utter.trim();
    if (text.isEmpty || _skillsList.isEmpty) return;

    final idx = CharacterBattleAsr.chooseBestIndex(_skillsList, text);
    if (idx < 0) return;

    final chosen = _skillsList[idx];
    final score = CharacterBattleAsr.similarity(
      text.toLowerCase(),
      chosen.toLowerCase(),
    );

    if (score < 0.3) {
      debugPrint('❌ [낮은 유사도] $score');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ "$text"와(과) 일치하는 스킬을 찾지 못했습니다'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.redAccent.withOpacity(0.9),
        ),
      );
      return;
    }

    debugPrint('✅ [선택] "$text" → "$chosen" ($score)');

    // 사용자 말풍선 표시
    _userBubbleTimer?.cancel();
    setState(() {
      _userBubbleText = chosen;
      _isUserBubbleVisible = true;
    });

    _userBubbleTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _userBubbleText = null;
        _isUserBubbleVisible = false;
      });
    });

    setState(() {
      _selectedSkill = chosen;
    });

    // 2초 후에 칩 제거 및 HP 감소
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _shrunkChips.add(idx);
        if (_targetHp > 0) {
          _targetHp = _targetHp - 1;
          if (_targetHp == 0) _isDefeated = true;
        }
      });
    });
  }

  // ========== UI 헬퍼 ==========

  void _showToast(String msg) {
    if (!mounted || msg.trim().isEmpty) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 2),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 90, left: 16, right: 16),
        backgroundColor: Colors.black.withOpacity(0.85),
      ),
    );
  }

  void _showErrorDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('음성인식 오류'),
        content: const Text(
          '음성인식을 사용할 수 없습니다.\n\n'
          '1. 마이크 권한 확인\n'
          '2. 네트워크 연결 확인\n'
          '3. 실기기에서 테스트\n\n'
          '⚠️ 에뮬레이터는 지원되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _startEmotionCycle() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) break;

      setState(() => _isBubbleVisible = false);

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) break;

      setState(() {
        if (_characterEmotions.isNotEmpty) {
          _currentEmotionIndex =
              (_currentEmotionIndex + 1) % _characterEmotions.length;
        }
        _isBubbleVisible = true;
      });
    }
  }

  // ========== UI 빌드 ==========

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.tealAccent),
        ),
      );
    }

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
          _buildTopBanner(),
          _buildHpPanel(),
          _buildCharacters(myChar, target),
          _buildMicButton(),
          _buildBottomBar(),
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

  Widget _buildTopBanner() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 65, 79, 79).withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '대체 생각을 말하고\n$_characterName을 물리치세요!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            height: 1.25,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildHpPanel() {
    return Positioned(
      top: 190,
      right: 200,
      child: Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.85),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _characterName ?? '불안한 캐릭터',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _characterDescription ?? '불안해하고 있습니다',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 6),
            _buildHpBar(),
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
            color: const Color(0xFF9C60FF),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacters(String myChar, String targetChar) {
    final dx = _shakeController.value;

    return Stack(
      children: [
        // 내 캐릭터와 말풍선
        Positioned(
          left: 8,
          bottom: 160,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 사용자 말풍선 (흰색 배경, 검은색 텍스트)
              if (_isUserBubbleVisible && _userBubbleText != null)
                Positioned(
                  top: -60,
                  left: 80,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildEmotionBubble(
                      _userBubbleText!,
                      key: ValueKey("user_bubble_$_userBubbleText"),
                      // backgroundColor 제거 = 흰색 배경, 검은색 텍스트
                    ),
                  ),
                ),
              // 내 캐릭터 이미지
              Image.asset(myChar, height: 220, fit: BoxFit.contain),
            ],
          ),
        ),
        // 타겟 캐릭터와 말풍선
        Positioned(
          top: 210,
          right: 24 + dx,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 캐릭터 말풍선 (흰색)
              if (_characterEmotions.isNotEmpty)
                Positioned(
                  top: -60,
                  right: 0,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: _isBubbleVisible
                        ? _buildEmotionBubble(
                            _bubbleText ?? _characterEmotions[_currentEmotionIndex],
                            key: ValueKey("visible_$_currentEmotionIndex"),
                          )
                        : const SizedBox.shrink(key: ValueKey("hidden")),
                  ),
                ),
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
      ],
    );
  }

  Widget _buildEmotionBubble(String text, {Key? key, Color? backgroundColor}) {
    return Container(
      key: key,
      constraints: const BoxConstraints(maxWidth: 180, minHeight: 40),
      child: ClipOval(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          color: (backgroundColor ?? Colors.white).withOpacity(0.95),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: backgroundColor != null ? Colors.white : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    return Positioned(
      bottom: 160,
      right: 40,
      child: GestureDetector(
        onTap: () async {
          if (_isAttacking || _isDefeated) return;

          if (_listening) {
            await _voice.stop();
            setState(() => _listening = false);
            return;
          }

          await _onMicPressed();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: _listening
                ? const Color(0xFF56E0C6).withOpacity(0.9)
                : const Color.fromARGB(255, 65, 79, 79).withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white30),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '스킬(대체 생각)을 골라 공격하세요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _skillsList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  if (_shrunkChips.contains(idx)) {
                    return const SizedBox.shrink();
                  }

                  final skill = _skillsList[idx];
                  final selected = skill == _selectedSkill;

                  return ChoiceChip(
                    label: Text(skill),
                    selected: selected,
                    onSelected: (v) {
                      if (!_isAttacking && !_isDefeated && v) {
                        setState(() => _selectedSkill = skill);
                      }
                    },
                    labelStyle: const TextStyle(color: Colors.black, fontSize: 12),
                    selectedColor: const Color(0xFF56E0C6),
                    backgroundColor: Colors.white12,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      debugPrint('✅ [보관함] 그룹 아카이빙 완료');
    } catch (e) {
      debugPrint('❌ [보관함] 아카이빙 실패: $e');
    }
  }
}