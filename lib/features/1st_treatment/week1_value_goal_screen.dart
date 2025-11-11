import 'package:flutter/material.dart';
import 'package:gad_app_team/widgets/tutorial_design.dart'; // ✅ 기존 디자인 클래스만 import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gad_app_team/data/user_data_model.dart';
import 'package:gad_app_team/data/user_data_storage.dart';
import 'package:gad_app_team/features/menu/education/education_page.dart';

class Week1ValueGoalScreen extends StatefulWidget {
  const Week1ValueGoalScreen({super.key});

  @override
  State<Week1ValueGoalScreen> createState() => _Week1ValueGoalScreenState();
}

class _Week1ValueGoalScreenState extends State<Week1ValueGoalScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
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
        final data = doc.data();
        setState(() => _userName = data?['name'] ?? '사용자');
      } else {
        setState(() => _userName = '사용자');
      }
    } catch (_) {
      setState(() => _userName = '사용자');
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userData = UserData(
        name: _userName ?? '사용자',
        coreValue: _controller.text.trim(),
        createdAt: DateTime.now(),
      );
      await UserDataStorage.saveUserData(userData);
      if (mounted) _showEducationDialog();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEducationDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('1주차 교육 시작'),
            content: Text('${_userName ?? "사용자"}님, 1주차 불안에 대해 배워보겠습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => const EducationPage(
                            title: '1주차 - 불안에 대한 교육',
                            jsonPrefixes: [
                              'week1_part1_',
                              'week1_part2_',
                              'week1_part3_',
                              'week1_part4_',
                              'week1_part5_',
                              'week1_part6_',
                              'week1_relaxation_',
                            ],
                            isRelax: true,
                          ),
                    ),
                  );
                },
                child: const Text('시작하기'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _userName ?? '사용자';

    // ✅ 디자인 위젯 ApplyDesign 그대로 사용
    return ApplyDesign(
      appBarTitle: '1주차 - 시작하기',
      cardTitle: '$name님, Mindrium에 오신 것을 환영합니다 🌊',
      onBack: () => Navigator.pop(context),
      onNext: _saveUserData,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 프로그램을 통해 불안을 관리하고\n더 나은 삶을 만들어가시길 바랍니다.',
              style: TextStyle(
                fontSize: 14.5,
                color: Color(0xFF333333),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '$name님, 삶에서 가장 중요하게 생각하는\n가치는 무엇인가요?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF224C78),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '예: 가족, 건강, 성장, 자유, 사랑, 평화 등',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '가장 소중한 가치를 적어주세요...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFBFD9FA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF7CB9FF),
                    width: 2,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '가치를 입력해주세요';
                if (v.trim().length < 2) return '가치를 더 자세히 적어주세요';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
