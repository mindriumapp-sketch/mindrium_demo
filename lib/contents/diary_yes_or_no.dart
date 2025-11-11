import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_group_add.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';
import 'package:gad_app_team/widgets/blue_white_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DiaryYesOrNo extends StatelessWidget {
  const DiaryYesOrNo({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final dynamic diary = args['diary'];

    return Scaffold(
      appBar: const CustomAppBar(title: '걱정 일기 진행'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final cardWidth = math.min(560.0, w * 0.90);

            return Stack(
              children: [
                // === 배경: 흰색 100% + 물결 35% ===
                const ColoredBox(color: Colors.white),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset(
                        'assets/image/eduhome.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ),

                // === 내용(카드 중앙 정렬) ===
                Center(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: BlueWhiteCard(
                      maxWidth: cardWidth,
                      title: '걱정 일기를 새로 작성 하시겠어요?',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),
                          // === 이미지 ===
                          Image.asset('assets/image/pink3.png',
                            height: math.min(180, w * 0.38),
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 16),

                          // === 새 일기 → ABC 시작 ===
                          _BluePillButton(
                            label: '예',
                            onTap: () {
                              // 기존 라우팅 로직 그대로
                              Navigator.pushNamed(
                                context,
                                '/abc',
                                arguments: {
                                  'origin': 'apply',
                                  'abcId': null,
                                  if (diary != null) 'diary': diary,
                                  'beforeSud': args['beforeSud'],
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // === 아니오(그룹 추가 화면으로) ===
                          _BluePillButton(
                            label: '아니오',
                            onTap: () async {
                              // ✅ 기존 백엔드 로직 그대로 (저장 후 그룹 추가 화면 이동)
                              final uid = FirebaseAuth.instance.currentUser?.uid;
                              if (uid == null) return;

                              Position? pos;
                              try {
                                var perm = await Geolocator.checkPermission();
                                if (perm == LocationPermission.denied) {
                                  perm = await Geolocator.requestPermission();
                                }
                                if (perm == LocationPermission.always ||
                                    perm == LocationPermission.whileInUse) {
                                  pos = await Geolocator.getCurrentPosition(
                                    locationSettings: const LocationSettings(
                                      accuracy: LocationAccuracy.low,
                                    ),
                                  );
                                }
                              } catch (_) {
                                /* 위치 권한 거부 시 그냥 넘어감 */
                              }

                              final data = {
                                'activatingEvent': null,
                                'belief': null,
                                'consequence': null,
                                'createdAt': FieldValue.serverTimestamp(),
                                if (pos != null) 'latitude': pos.latitude,
                                if (pos != null) 'longitude': pos.longitude,
                              };

                              final docRef = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('abc_models')
                                  .add(data);

                              final data2 = {
                                'before_sud': args['beforeSud'] ?? 0,
                                'createdAt': FieldValue.serverTimestamp(),
                              };

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(uid)
                                  .collection('abc_models')
                                  .doc(docRef.id)
                                  .collection('sud_score')
                                  .add(data2);

                              if (!context.mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AbcGroupAddScreen(
                                    origin: 'apply',
                                    abcId: docRef.id,
                                    diary: diary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// TrainingSelect에서 쓰던 버튼과 동일한 비주얼
class _BluePillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BluePillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFAED1FF), Color(0xFF75B6FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
    )._withText(label);
  }
}

// 버튼 텍스트를 겹쳐 넣는 동일한 기법
extension on Widget {
  Widget _withText(String text) => Stack(
        alignment: Alignment.center,
        children: [
          this,
          const IgnorePointer(ignoring: true, child: SizedBox()),
          IgnorePointer(
            ignoring: true,
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}
