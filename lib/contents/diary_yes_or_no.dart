// 🔹 Mindrium: 걱정 일기 진행 분기 화면 (DiaryYesOrNo 개선 최종 버전)
// ‘아니오’ 클릭 시 로딩중 표시 + Firestore 병렬 처리 + 위치 timeout 안전 처리

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gad_app_team/features/2nd_treatment/abc_group_add.dart';
import 'package:gad_app_team/widgets/inner_btn_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class DiaryYesOrNo extends StatelessWidget {
  const DiaryYesOrNo({super.key});

  Future<void> _handleNo(BuildContext context, Map args, dynamic diary) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // 🔸 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white, // 배경 흰색 유지
      builder:
          (_) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 로고 이미지 (노란 로딩 대신 표시)
                Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),

                // 🔹 텍스트
                const Text(
                  '로딩 중입니다. 잠시만 기다려주세요...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Noto Sans KR',
                  ),
                ),
              ],
            ),
          ),
    );

    Position? pos;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        // ⏱ 위치 요청 (5초 timeout 적용)
        try {
          pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low,
            ),
          ).timeout(const Duration(seconds: 5));
        } on TimeoutException {
          pos = null; // 시간 초과 시 null로 처리
        }
      }
    } catch (_) {
      // 위치 실패는 무시
      pos = null;
    }

    final firestore = FirebaseFirestore.instance;

    final data = {
      'activatingEvent': null,
      'belief': null,
      'consequence': null,
      'createdAt': FieldValue.serverTimestamp(),
      if (pos != null) 'latitude': pos.latitude,
      if (pos != null) 'longitude': pos.longitude,
    };

    try {
      // 🔹 문서 ID 미리 생성
      final docRef =
          firestore.collection('users').doc(uid).collection('abc_models').doc();

      // 🔹 Firestore 병렬 처리로 시간 단축
      await Future.wait([
        docRef.set(data),
        docRef.collection('sud_score').add({
          'before_sud': args['beforeSud'] ?? 0,
          'createdAt': FieldValue.serverTimestamp(),
        }),
      ]);

      if (context.mounted) {
        Navigator.pop(context); // ✅ 로딩창 닫기
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => AbcGroupAddScreen(
                  origin: 'apply',
                  abcId: docRef.id,
                  diary: diary,
                ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // 로딩창 닫기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터 저장 중 오류가 발생했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final dynamic diary = args['diary'];

    return InnerBtnCardScreen(
      appBarTitle: '걱정 일기 진행',
      title: '걱정 일기를 새로 \n작성하시겠어요?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/image/pink3.png',
            height: math.min(180, MediaQuery.of(context).size.width * 0.38),
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          const Text(
            '예를 누르면 걱정일기 작성 페이지로 넘어가요!\n'
            '아니오를 누르면 걱정그룹 추가 페이지로 넘어가요!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w200,
              color: Color(0xFF626262),
              height: 1.8,
              wordSpacing: 1.2,
            ),
          ),
        ],
      ),
      primaryText: '예',
      onPrimary: () {
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
      secondaryText: '아니오',
      onSecondary: () => _handleNo(context, args, diary),
      backgroundAsset: 'assets/image/eduhome.png',
    );
  }
}
