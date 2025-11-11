import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../common/constants.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/navigation_button.dart';
import '../../data/user_provider.dart';
import '../2nd_treatment/abc_group_add.dart';
import '../2nd_treatment/notification_selection_screen.dart';

/// 🌊 GridItem (공통 구조)
class GridItem {
  final IconData icon;
  final String label;
  final bool isAdd;
  const GridItem({required this.icon, required this.label, this.isAdd = false});
}

/// 📊 시각화 / 피드백 화면
class AbcVisualizationScreen extends StatefulWidget {
  final List<GridItem> activatingEventChips;
  final List<GridItem> beliefChips;
  final List<GridItem> resultChips;
  final List<GridItem> feedbackEmotionChips;
  final List<String> selectedPhysicalChips;
  final List<String> selectedEmotionChips;
  final List<String> selectedBehaviorChips;
  final bool isExampleMode;
  final String? origin;
  final String? abcId;
  final int? beforeSud;

  const AbcVisualizationScreen({
    super.key,
    required this.activatingEventChips,
    required this.beliefChips,
    required this.resultChips,
    required this.feedbackEmotionChips,
    required this.selectedPhysicalChips,
    required this.selectedEmotionChips,
    required this.selectedBehaviorChips,
    required this.isExampleMode,
    this.origin,
    this.abcId,
    this.beforeSud,
  });

  @override
  State<AbcVisualizationScreen> createState() => _AbcVisualizationScreenState();
}

class _AbcVisualizationScreenState extends State<AbcVisualizationScreen> {
  bool _showFeedback = true;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '2주차 - ABC 모델'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (_showFeedback) _buildFeedbackCard(context),
              if (!_showFeedback) _buildAbcFlowDiagram(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: NavigationButtons(
          leftLabel: '이전',
          rightLabel: _showFeedback ? '다음' : (_isSaving ? '저장 중...' : '완료'),
          onBack: () {
            if (!_showFeedback) {
              setState(() => _showFeedback = true);
            } else {
              Navigator.pop(context);
            }
          },
          onNext:
              _isSaving
                  ? null
                  : () {
                    if (_showFeedback) {
                      setState(() => _showFeedback = false);
                    } else {
                      _handleSave(context);
                    }
                  },
        ),
      ),
    );
  }

  /// 💬 피드백 요약문 카드
  Widget _buildFeedbackCard(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    final situation = widget.activatingEventChips
        .map((e) => e.label)
        .join(', ');
    final thought = widget.beliefChips.map((e) => e.label).join(', ');
    final emotion = widget.selectedEmotionChips.join(', ');
    final physical = widget.selectedPhysicalChips.join(', ');
    final behavior = widget.selectedBehaviorChips.join(', ');

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "$userName님, 말씀해주셔서 감사합니다 👏",
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "‘$situation’ 상황에서 ‘$thought’ 생각을 하셨고,\n"
              "‘$emotion’ 감정을 느끼셨습니다.\n\n"
              "그 결과 신체적으로 ‘$physical’ 증상이 나타났고,\n"
              "‘$behavior’ 행동을 하셨습니다.",
              style: const TextStyle(fontSize: 15.5, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "위의 내용을 그림으로 그려볼까요?",
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.indigo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 A→B→C 시각화 다이어그램
  Widget _buildAbcFlowDiagram() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionCard(
          icon: Icons.event_note,
          title: '상황 (A)',
          chips: widget.activatingEventChips,
          color: const Color(0xFFDCE7FE),
        ),
        const Center(
          child: Icon(Icons.arrow_downward, size: 36, color: AppColors.indigo),
        ),
        _buildSectionCard(
          icon: Icons.psychology,
          title: '생각 (B)',
          chips: widget.beliefChips,
          color: const Color(0xFFB1C9EF),
        ),
        const Center(
          child: Icon(Icons.arrow_downward, size: 36, color: AppColors.indigo),
        ),
        _buildSectionCard(
          icon: Icons.emoji_emotions,
          title: '결과 (C)',
          chips: widget.resultChips,
          color: const Color(0xFF95B1EE),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<GridItem> chips,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: AppColors.indigo,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    chips
                        .map(
                          (e) => Chip(
                            label: Text(e.label),
                            avatar: Icon(
                              e.icon,
                              size: 16,
                              color: AppColors.indigo,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(color: AppColors.indigo),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ☁️ Firestore 저장 로직
  Future<void> _handleSave(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("로그인 정보 없음");

      final firestore = FirebaseFirestore.instance;
      final ref = firestore
          .collection('users')
          .doc(user.uid)
          .collection('abc_models');

      // 위치 가져오기 (선택)
      Position? pos;
      try {
        final perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          pos = await Geolocator.getCurrentPosition();
        }
      } catch (_) {}

      final doc = await ref.add({
        'activatingEvent': widget.activatingEventChips
            .map((e) => e.label)
            .join(', '),
        'belief': widget.beliefChips.map((e) => e.label).join(', '),
        'consequence': widget.resultChips.map((e) => e.label).join(', '),
        'consequence_physical': widget.selectedPhysicalChips.join(', '),
        'consequence_emotion': widget.selectedEmotionChips.join(', '),
        'consequence_behavior': widget.selectedBehaviorChips.join(', '),
        'latitude': pos?.latitude,
        'longitude': pos?.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 그룹 추가 여부 묻기
      if (!mounted) return;
      _showGroupDialog(context, doc.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// 🔔 그룹 추가 여부 다이얼로그
  void _showGroupDialog(BuildContext context, String abcId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => AlertDialog(
            title: const Text('걱정 그룹에 추가하시겠습니까?'),
            content: const Text('작성한 ABC 일기를 그룹에 추가하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => NotificationSelectionScreen(
                            abcId: abcId,
                            origin: widget.origin ?? 'etc',
                            label:
                                widget.activatingEventChips.isNotEmpty
                                    ? widget.activatingEventChips.first.label
                                    : '',
                          ),
                    ),
                  );
                },
                child: const Text('아니요'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => AbcGroupAddScreen(
                            abcId: abcId,
                            origin: widget.origin ?? 'etc',
                            label:
                                widget.activatingEventChips.isNotEmpty
                                    ? widget.activatingEventChips.first.label
                                    : '',
                          ),
                    ),
                  );
                },
                child: const Text('예'),
              ),
            ],
          ),
    );
  }
}
