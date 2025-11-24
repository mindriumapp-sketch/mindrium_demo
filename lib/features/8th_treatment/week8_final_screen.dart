import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/custom_popup_design.dart';
import 'package:gad_app_team/widgets/navigation_button.dart';
import 'package:gad_app_team/widgets/round_card.dart';
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/week8_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

class Week8FinalScreen extends StatefulWidget {
  const Week8FinalScreen({super.key});

  @override
  State<Week8FinalScreen> createState() => _Week8FinalScreenState();
}

class _Week8FinalScreenState extends State<Week8FinalScreen> {
  late final ApiClient _apiClient;
  late final Week8Api _week8Api;
  bool _isSavingCompletion = false;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(tokens: TokenStorage());
    _week8Api = Week8Api(_apiClient);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 💡 배경색은 Stack에서 처리
      extendBodyBehindAppBar: true,

      appBar: const CustomAppBar(title: '8주차 - 인지 재구성'),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌊 Mindrium 공통 배경 (ApplyDesign 스타일)
          Container(
            color: Colors.white,
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/image/eduhome.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 40,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ───────── 결과 카드 (Week5 스타일 적용)
                          RoundCard(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 36,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 🎉 축하/결과 이미지
                                Image.asset(
                                  'assets/image/congrats.png', // 필요 시 nice.png로 교체 가능 (로직 영향 없음)
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 22),

                                // 🔢 결과 텍스트
                                Text(
                                  '수고하셨습니다!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    height: 1.4,
                                    color: Colors.black87,
                                    fontFamily: 'Noto Sans KR',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '8주간의 여정을 완주하셨습니다!\n앞으로도 꾸준히 자신을 돌보세요!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.4,
                                    color: Colors.black87,
                                    fontFamily: 'Noto Sans KR',
                                  ),
                                ),
                              ]
                            )
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                // ⛵ 네비게이션 버튼 (기존 로직 그대로 유지)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: NavigationButtons(
                    onBack: () => Navigator.pop(context),
                    onNext: () => _showStartDialog(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🧘 이완 교육 다이얼로그 — CustomPopupDesign(확인 단일 버튼)
  void _showStartDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CustomPopupDesign(
        title: '이완 음성 안내 시작',
        message:
        '잠시 후, 이완을 위한 음성 안내가 시작됩니다.\n주변 소리와 음량을 조절해보세요.',
        positiveText: '확인',
        negativeText: null,
        backgroundAsset: null,
        iconAsset: null,
        onPositivePressed: () async {
          if (_isSavingCompletion) return;
          setState(() => _isSavingCompletion = true);
          
          try {
            await _week8Api.updateCompletion(true);
            if (!mounted) return;
            
            Navigator.pop(context);
            Navigator.pushReplacementNamed(
              context,
              '/relaxation_education',
              arguments: {
                'taskId': 'week8_education',
                'weekNumber': 8,
                'mp3Asset': 'week8.mp3',
                'riveAsset': 'week8.riv',
              },
            );
          } catch (e) {
            if (!mounted) return;
            BlueBanner.show(context, '8주차 완료 상태 저장에 실패했습니다: $e');
            setState(() => _isSavingCompletion = false);
          }
        },
      ),
    );
  }
}
