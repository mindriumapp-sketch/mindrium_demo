import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ✅ 블루 토스트 배너
import 'package:gad_app_team/widgets/blue_banner.dart';
import 'package:gad_app_team/data/user_provider.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController coreValueController = TextEditingController();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool isEditing = false;
  bool isLoading = true;
  bool showPasswordFields = false;

  DateTime? createdAt;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _loadUserDataFromBackend();
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      final data = doc.data();
      if (data != null) {
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        coreValueController.text = data['coreValue'] ?? '';
        if (data['createdAt'] != null) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }
      }
    } catch (e) {
      debugPrint("내 정보 로드 실패: $e");
      // 필요하면 실패 토스트도 사용 가능
      BlueBanner.show(context, '내 정보를 불러오지 못했어요.');
    }
    setState(() => isLoading = false);
  }

  Future<void> _loadUserDataFromBackend() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUserData();

      nameController.text = userProvider.userName;
      emailController.text = userProvider.userEmail;
      createdAt = userProvider.createdAt;
    } catch (e) {
      debugPrint("내 정보(백엔드) 로드 실패: $e");
      if (mounted) {
        BlueBanner.show(context, '내 정보를 불러오지 못했어요.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('현재 계정에서는 빠른 수정 기능을 준비 중입니다.');
      return;
    }
    setState(() => isLoading = true);

    final currentPw = currentPasswordController.text.trim();
    final newPw = newPasswordController.text.trim();
    final confirmPw = confirmPasswordController.text.trim();

    if (showPasswordFields && currentPw.isEmpty) {
      _showSnack('기존 비밀번호를 입력해야 합니다.');
      setState(() => isLoading = false);
      return;
    }

    if (newPw.isNotEmpty && newPw != confirmPw) {
      _showSnack('새 비밀번호가 일치하지 않습니다.');
      setState(() => isLoading = false);
      return;
    }

    try {
      // 🔐 비밀번호 재인증
      if (showPasswordFields) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPw,
        );
        await user.reauthenticateWithCredential(cred);
      }

      // ✏️ 이름/핵심 가치 업데이트
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': nameController.text.trim(),
            'coreValue': coreValueController.text.trim(),
          });

      await user.updateDisplayName(nameController.text.trim());

      // 🔄 비밀번호 변경
      if (showPasswordFields && newPw.isNotEmpty) {
        await user.updatePassword(newPw);
        _showSnack('비밀번호가 변경되었습니다. 다시 로그인해주세요.');
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }

      _showSnack('내 정보가 업데이트되었습니다.');
      setState(() => isEditing = false);
    } catch (e) {
      _showSnack('업데이트 실패: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  int daysBetween(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return da.difference(db).inDays;
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 색상 팔레트
    const Color softWhite = Color(0xE6FFFFFF);
    const Color deepNavy = Color(0xFF004C73);
    const Color skyBlue = Color(0xFF89D4F5);

    final double maxCardWidth = MediaQuery.of(context).size.width - 48;

    final String joinDateText =
        createdAt != null
            ? '가입일: ${DateFormat('yyyy년 MM월 dd일').format(createdAt!)}'
            : '가입일 정보 없음';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '내 정보',
          style: TextStyle(
            color: deepNavy,
            fontWeight: FontWeight.w700,
            fontFamily: 'Noto Sans KR',
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: deepNavy),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/image/eduhome.png',
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.35),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              child: Container(
                width: maxCardWidth,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: softWhite,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40FFFFFF),
                      blurRadius: 30,
                      offset: Offset(0, 0),
                    ),
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    isLoading
                        ? const Center(
                          child: CircularProgressIndicator(color: skyBlue),
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildTextField(
                              controller: nameController,
                              label: '이름',
                              icon: Icons.person_outline,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: emailController,
                              label: '이메일',
                              icon: Icons.email_outlined,
                              enabled: false,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: coreValueController,
                              label: '나의 핵심 가치',
                              icon: Icons.favorite_outline,
                              enabled: isEditing,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    joinDateText,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 13,
                                      fontFamily: 'Noto Sans KR',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            if (showPasswordFields) ...[
                              _buildTextField(
                                controller: currentPasswordController,
                                label: '기존 비밀번호',
                                icon: Icons.lock_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: newPasswordController,
                                label: '새 비밀번호',
                                icon: Icons.lock_reset_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: confirmPasswordController,
                                label: '새 비밀번호 확인',
                                icon: Icons.verified_user_outlined,
                              ),
                              const SizedBox(height: 24),
                            ],

                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed:
                                    isLoading
                                        ? null
                                        : isEditing
                                        ? _updateUserData
                                        : () =>
                                            setState(() => isEditing = true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: skyBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: Text(
                                  isEditing ? '저장하기' : '수정하기',
                                  style: const TextStyle(
                                    fontFamily: 'Noto Sans KR',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                setState(
                                  () =>
                                      showPasswordFields = !showPasswordFields,
                                );
                              },
                              child: Text(
                                showPasswordFields ? '비밀번호 변경 닫기' : '비밀번호 변경',
                                style: const TextStyle(
                                  color: deepNavy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _logout,
                              child: const Text(
                                '로그아웃',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: label.contains('비밀번호'),
      style: const TextStyle(
        fontFamily: 'Noto Sans KR',
        fontSize: 16,
        color: Color(0xFF333333),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Color(0xFF004C73)),
        filled: true,
        fillColor: enabled ? const Color(0xFFF5FBFF) : const Color(0xFFEFF7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9EEFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD9EEFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF89D4F5), width: 1.6),
        ),
      ),
    );
  }
}
