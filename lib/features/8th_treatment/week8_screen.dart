import 'package:flutter/material.dart';
import 'package:gad_app_team/features/value_start.dart';
import 'package:gad_app_team/features/8th_treatment/week8_roadmap_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/widgets/custom_appbar.dart';

class Week8Screen extends StatefulWidget {
  const Week8Screen({super.key});

  @override
  State<Week8Screen> createState() => _Week8ScreenState();
}

class _Week8ScreenState extends State<Week8Screen> {
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          final data = doc.data();
          if (mounted) {
            setState(() {
              _userName = data?['name'] as String?;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('사용자 이름 로드 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekDescription =
        _userName != null
            ? '$_userName님의 8주간 여정을 진심으로 축하드립니다. Mindrium 교육 프로그램을 모두 완료하셨습니다. 이제 불안을 효과적으로 관리할 수 있는 다양한 기법들을 익히셨습니다.\n지금까지 달려온 과정을 미처 인식하지 못할 수도 있지만, 이 모든 성과는 오직 $_userName님께서 스스로 이루어낸 것입니다.'
            : '8주간의 여정을 진심으로 축하드립니다. Mindrium 교육 프로그램을 모두 완료하셨습니다. 이제 불안을 효과적으로 관리할 수 있는 다양한 기법들을 익히셨습니다. 지금까지 달려온 과정을 미처 인식하지 못할 수도 있지만, 이 모든 성과는 오직 당신께서 스스로 이루어낸 것입니다.';

    return ValueStartScreen(
      weekNumber: 8,
      weekTitle: 'Mindrium 교육 프로그램을\n모두 완료하셨습니다!',
      weekDescription: weekDescription,
      nextPageBuilder: () => const Week8RoadmapScreen(),
    );
  }
}

// 8주차 완료 화면 (임시)
class Week8CompletionScreen extends StatelessWidget {
  const Week8CompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '프로그램 완료'),
      body: const Center(
        child: Text(
          '8주차 프로그램이 완료되었습니다!\n축하합니다!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
