import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/user_provider.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/diaries_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

// 💡 Mindrium 위젯 디자인들
import 'package:gad_app_team/widgets/memo_sheet_design.dart';
import 'package:gad_app_team/widgets/abc_visualization_design.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';

/// 🌊 GridItem 구조 (공통 유지)
class GridItem {
  final IconData icon;
  final String label;
  final bool isAdd;
  const GridItem({required this.icon, required this.label, this.isAdd = false});
}

/// 📊 시각화 + 피드백 화면
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
  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final DiariesApi _diariesApi = DiariesApi(_apiClient);

  @override
  Widget build(BuildContext context) {
    return MemoFullDesign(
      appBarTitle: '2주차 - ABC 모델',
      child: Column(
        children: [
          if (_showFeedback) _buildFeedbackCard(context),
          if (!_showFeedback) _buildAbcFlowDiagram(),
        ],
      ),
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
      rightLabel:
          _showFeedback
              ? '다음'
              : _isSaving
              ? '저장 중...'
              : '저장',
      memoHeight: MediaQuery.of(context).size.height * 0.67,
    );
  }

  /// 💬 피드백 카드
  Widget _buildFeedbackCard(BuildContext context) {
    final userName = Provider.of<UserProvider>(context, listen: false).userName;
    final situation = widget.activatingEventChips
        .map((e) => e.label)
        .join(', ');
    final thought = widget.beliefChips.map((e) => e.label).join(', ');
    final emotion = widget.selectedEmotionChips.join(', ');
    final physical = widget.selectedPhysicalChips.join(', ');
    final behavior = widget.selectedBehaviorChips.join(', ');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            '글로 정리해보기',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DesignPalette.textBlack,
              fontFamily: 'Noto Sans KR',
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 200,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.black26.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            '$userName님, \n말씀해주셔서 감사합니다 👏\n\n'
            "‘$situation’ 상황에서 \n‘$thought’ 생각을 하셨고,\n‘$emotion’ 감정을 느끼셨습니다.\n\n"
            "그 결과 신체적으로 ‘$physical’ 증상이 나타났고,\n‘$behavior’ 행동을 하셨습니다.",
            style: const TextStyle(
              height: 1.6,
              fontSize: 16,
              color: Colors.black87,
              fontFamily: 'Noto Sans KR',
            ),
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }

  /// 🔵 A→B→C 시각화 다이어그램
  Widget _buildAbcFlowDiagram() {
    final situationText = widget.activatingEventChips
        .map((e) => e.label)
        .join(', ');
    final beliefText = widget.beliefChips.map((e) => e.label).join(', ');
    final resultText = widget.resultChips.map((e) => e.label).join(', ');

    return AbcVisualizationDesign.buildVisualizationLayout(
      situationLabel: '상황 (A)',
      beliefLabel: '생각 (B)',
      resultLabel: '결과 (C)',
      situationText: situationText,
      beliefText: beliefText,
      resultText: resultText,
    );
  }

  // ──────────────────────────────────────────────
  // 🔹 FastAPI 기반 저장 로직
  // ──────────────────────────────────────────────
  Future<void> _handleSave(BuildContext context) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final activatingEvents = widget.activatingEventChips.map((e) => e.label).join(', ');
      final beliefList = widget.beliefChips.map((e) => e.label).toList();
      final emotionList = List<String>.from(widget.selectedEmotionChips);
      final physicalList = List<String>.from(widget.selectedPhysicalChips);
      final behaviorList = List<String>.from(widget.selectedBehaviorChips);

      final access = await _tokens.access;
      if (access == null) {
        throw Exception('로그인이 필요합니다.');
      }

      // 🗺️ 위치 동의 받기
      final bool consent = await _requestLocationConsent(context);

      Position? pos;
      if (consent) {
        try {
          final perm = await Geolocator.requestPermission();
          if (perm == LocationPermission.always ||
              perm == LocationPermission.whileInUse) {
            pos = await Geolocator.getCurrentPosition();
          }
        } catch (e) {
          debugPrint("위치 접근 실패: $e");
        }
      }

      List<Map<String, dynamic>> sudScorePayload = const [];
      if (widget.beforeSud != null) {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        sudScorePayload = [
          {
            'before_sud': widget.beforeSud,
            'after_sud': widget.beforeSud,
            'created_at': nowIso,
            'updated_at': nowIso,
          },
        ];
      }

      final diary = await _diariesApi.createDiary(
        groupId: 1, // 기본 그룹 (캐릭터 1)으로 할당
        activatingEvents: activatingEvents,
        belief: beliefList,
        consequenceE: emotionList,
        consequenceP: physicalList,
        consequenceB: behaviorList,
        sudScores: sudScorePayload,
        alternativeThoughts: const [],
        alarms: const [],
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );

      final createdDiaryId = diary['diaryId']?.toString();
      debugPrint('FastAPI diary 저장 완료: $createdDiaryId');

      if (!mounted) return;
      _showSavedPopup(
        context,
        diaryId: createdDiaryId,
        label: activatingEvents,
      );
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

  // ──────────────────────────────────────────────
  // 📍 위치 정보 동의 팝업 (Mindrium 스타일)
  // ──────────────────────────────────────────────
  Future<bool> _requestLocationConsent(BuildContext context) async {
    bool consent = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return CustomPopupDesign(
          title: '위치 정보 수집 동의',
          message:
              '현재 위치 정보를 함께 저장하여 개인 맞춤형 피드백을 제공하려고 합니다.\n'
              '위치 정보 제공에 동의하시겠습니까?',
          positiveText: '동의함',
          negativeText: '동의 안 함',
          onPositivePressed: () {
            consent = true;
            Navigator.pop(ctx);
          },
          onNegativePressed: () {
            consent = false;
            Navigator.pop(ctx);
          },
          backgroundAsset: 'assets/image/popup_bg.png',
          iconAsset: 'assets/image/jellyfish.png',
        );
      },
    );

    return consent;
  }

  // ──────────────────────────────────────────────
  // ✅ 저장 완료 안내 팝업
  // ──────────────────────────────────────────────
  void _showSavedPopup(BuildContext context, {String? diaryId, String? label}) {
    final resolvedDiaryId = diaryId ?? widget.abcId;
    final resolvedLabel =
        label ?? widget.activatingEventChips.map((e) => e.label).join(', ');

    // 팝업 없이 바로 알림 설정 화면으로 이동
    final args = <String, dynamic>{};
    if (resolvedDiaryId != null && resolvedDiaryId.isNotEmpty) {
      args['abcId'] = resolvedDiaryId;
    }
    if (resolvedLabel.isNotEmpty) {
      args['label'] = resolvedLabel;
    }
    if (widget.origin != null) {
      args['origin'] = widget.origin;
    }

    if (!mounted) return;
    Navigator.pushNamed(
      context,
      '/noti_select',
      arguments: args.isEmpty ? null : args,
    );
  }
}
