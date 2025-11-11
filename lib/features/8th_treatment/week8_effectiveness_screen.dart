import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/features/8th_treatment/week8_schedule_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/behavior_confirm_dialog.dart';
import 'package:gad_app_team/widgets/eduhome_bg.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 모델
class CalendarEvent {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> behaviors;
  final DateTime createdAt;

  CalendarEvent({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.behaviors,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'behaviors': behaviors,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
    id: json['id'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    behaviors: List<String>.from(json['behaviors']),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// 화면
class Week8EffectivenessScreen extends StatefulWidget {
  final List<String> checkedBehaviors;

  const Week8EffectivenessScreen({super.key, required this.checkedBehaviors});

  @override
  State<Week8EffectivenessScreen> createState() =>
      _Week8EffectivenessScreenState();
}

class _Week8EffectivenessScreenState extends State<Week8EffectivenessScreen> {
  // 컬러 상수
  static const bluePrimary = Color(0xFF5DADEC); // 진행바/비활성 텝(반전 후)
  static const pinkPrimary = Color(0xFFFDB0B5); // 아니오 버튼
  static const chipBorderBlue = Color(0xFF6DBEF2);
  static const checkedChipFill = Color(0xFFDDEEFF);

  final List<String> _checkedBehaviors = [];
  final Set<String> _removedBehaviors = {};
  int _currentBehaviorIndex = 0;

  // 단계(0: 효과성, 1: 유지)
  int _step = 0;
  bool? _wasEffective;
  bool? _willContinue;

  // 탭(0: 효과성 평가, 1: 체크된 계획)
  int _activeTab = 0;

  bool _loading = true;
  String? _userName;
  String? _userCoreValue;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _checkedBehaviors
      ..clear()
      ..addAll(widget.checkedBehaviors);
    await _loadUser();
    setState(() => _loading = false);
  }

  Future<void> _loadUser() async {
    try {
      final u = FirebaseAuth.instance.currentUser;
      if (u == null) return;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      if (!doc.exists) return;
      final d = doc.data();
      _userName = d?['name'] as String?;
      _userCoreValue = d?['coreValue'] as String?;
    } catch (_) {}
  }

  String get _currentBehavior => _checkedBehaviors[_currentBehaviorIndex];
  bool get _canNext =>
      _step == 0 ? _wasEffective != null : _willContinue != null;

  void _onNext() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_willContinue == false) {
      _removedBehaviors.add(_currentBehavior);
    }
    if (_currentBehaviorIndex < _checkedBehaviors.length - 1) {
      setState(() {
        _currentBehaviorIndex++;
        _step = 0;
        _wasEffective = null;
        _willContinue = null;
      });
    } else {
      _showDone();
    }
  }

  void _onBack() {
    if (_step == 1) {
      setState(() {
        _step = 0;
        _wasEffective = null;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _showDone() {
    final keep =
        _checkedBehaviors.where((b) => !_removedBehaviors.contains(b)).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => BehaviorConfirmDialog(
            titleText: '평가 완료',
            highlightText: keep.isEmpty ? '유지할 행동 없음' : '유지할 행동',
            messageText:
                keep.isEmpty ? '유지할 행동이 없습니다.' : '유지할 행동: ${keep.join(", ")}',
            negativeText: '닫기',
            positiveText: '다음',
            onNegativePressed: () {
              Navigator.pop(context);
            },
            onPositivePressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Week8ScheduleScreen(behaviorsToKeep: keep),
                ),
              );
            },
            badgeBgAsset: 'assets/image/popup1.png',
            memoBgAsset: '',
          ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // ✅ 로딩 중 처리
    if (_loading || _checkedBehaviors.isEmpty) {
      return EduhomeBg(
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          appBar: CustomAppBar(title: '8주차 - 효과성 평가'),
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final twoThird = width * (2 / 3);

    // ✅ 메인 화면
    return EduhomeBg(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: const CustomAppBar(title: '8주차 - 효과성 평가'),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 진행 표시줄
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.88,
                    child: Row(
                      children: [
                        Text(
                          '${_currentBehaviorIndex + 1} / ${_checkedBehaviors.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value:
                                (_currentBehaviorIndex + 1) /
                                _checkedBehaviors.length,
                            minHeight: 4,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation(
                              bluePrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 탭 + 카드
                _tabsAboveCard(),
                const SizedBox(height: 18),

                // Jellyfish 안내
                if (_activeTab == 0) _jellyfishNote(),
                const SizedBox(height: 18),

                // 예/아니오 버튼 (2/3 폭)
                if (_activeTab == 0) ...[
                  Center(
                    child: SizedBox(
                      width: twoThird,
                      height: 72,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_step == 0) {
                              _wasEffective = true;
                            } else {
                              _willContinue = true;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: bluePrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                        child: const Text(
                          '예',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: twoThird,
                      height: 72,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_step == 0) {
                              _wasEffective = false;
                            } else {
                              _willContinue = false;
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pinkPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                        child: const Text(
                          '아니오',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // 네비게이션 버튼
                NavigationButtons(
                  leftLabel: '이전',
                  rightLabel: '다음',
                  onBack: _onBack,
                  onNext: _canNext ? _onNext : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabsAboveCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 탭 줄 (→ 50px 이동)
        Padding(
          padding: const EdgeInsets.only(left: 50.0),
          child: _TabsRow(
            isActiveLeft: _activeTab == 0,
            onTapLeft: () => setState(() => _activeTab = 0),
            isActiveRight: _activeTab == 1,
            onTapRight: () => setState(() => _activeTab = 1),
          ),
        ),
        const SizedBox(height: 0),
        Center(
          child: FractionallySizedBox(
            widthFactor: 0.88,
            child: _activeTab == 0 ? _questionCard() : _checkedListCard(),
          ),
        ),
      ],
    );
  }

  // “효과가 있었나요?” 카드
  Widget _questionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 239, height: 52),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: chipBorderBlue, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: chipBorderBlue.withOpacity(0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _currentBehavior,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '효과가 있었나요?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A202C),
            ),
          ),
        ],
      ),
    );
  }

  // 체크된 계획 카드
  Widget _checkedListCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children:
            _checkedBehaviors.map((b) {
              final removed = _removedBehaviors.contains(b);
              return ConstrainedBox(
                constraints: const BoxConstraints.tightFor(
                  width: 239,
                  height: 52,
                ),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: removed ? Colors.grey[300] : checkedChipFill,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: chipBorderBlue, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: chipBorderBlue.withOpacity(0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    b,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: removed ? Colors.black54 : const Color(0xFF2D3748),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  // 중앙 말풍선 + 해파리
  Widget _jellyfishNote() {
    final desc =
        _userName != null && _userCoreValue != null
            ? '$_userName님의 불안을 줄이고, 소중히 여기는 가치 \n"$_userCoreValue"를 향상하는 데 도움이 되셨습니까?'
            : '이 행동이 불안을 줄이고 소중히 여기는 가치를 향상하는 데 도움이 되셨습니까?';
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bluePrimary.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5568),
                height: 1.3,
              ),
            ),
          ),
          const Positioned(left: -50, top: 20, child: _JellyfishIcon()),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
class _TabsRow extends StatelessWidget {
  final bool isActiveLeft;
  final VoidCallback onTapLeft;
  final bool isActiveRight;
  final VoidCallback onTapRight;

  const _TabsRow({
    required this.isActiveLeft,
    required this.onTapLeft,
    required this.isActiveRight,
    required this.onTapRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tab(label: '효과성 평가', active: isActiveLeft, onTap: onTapLeft),
        _tab(label: '체크된 계획', active: isActiveRight, onTap: onTapRight),
      ],
    );
  }

  Widget _tab({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    const br = BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(0),
      bottomRight: Radius.circular(0),
    );

    final Color borderColor = _Week8EffectivenessScreenState.bluePrimary;
    final Color bg =
        active ? Colors.white : _Week8EffectivenessScreenState.bluePrimary;
    final Color textColor =
        active ? _Week8EffectivenessScreenState.bluePrimary : Colors.white;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: br,
        side: BorderSide(color: borderColor, width: 1),
      ),
      elevation: active ? 2 : 1,
      shadowColor: Colors.black.withOpacity(active ? 0.18 : 0.08),
      child: InkWell(
        borderRadius: br,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _JellyfishIcon extends StatelessWidget {
  const _JellyfishIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/image/jellyfish.png',
      width: 80,
      height: 80,
      fit: BoxFit.contain,
    );
  }
}
