import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/users_api.dart';
import 'package:gad_app_team/data/api/user_data_api.dart';
import 'package:gad_app_team/data/api/auth_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

// ✅ 블루 토스트 배너
import 'package:gad_app_team/widgets/blue_banner.dart';

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

  final TokenStorage _tokens = TokenStorage();
  late final ApiClient _apiClient = ApiClient(tokens: _tokens);
  late final UsersApi _usersApi = UsersApi(_apiClient);
  late final UserDataApi _userDataApi = UserDataApi(_apiClient);
  late final AuthApi _authApi = AuthApi(_apiClient, _tokens);

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
    try {
      final me = await _usersApi.me();
      nameController.text = (me['name'] as String?)?.trim() ?? '';
      emailController.text = (me['email'] as String?)?.trim() ?? '';
      final createdAtRaw = me['createdAt'] ?? me['created_at'];
      if (createdAtRaw is String) {
        createdAt = DateTime.tryParse(createdAtRaw);
      }
      final coreValue = await _userDataApi.getCoreValue();
      coreValueController.text = (coreValue?['core_value'] as String?) ?? '';
    } catch (e) {
      debugPrint("내 정보 로드 실패: $e");
      if (mounted) {
        BlueBanner.show(context, '내 정보를 불러오지 못했어요.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateUserData() async {
    setState(() => isLoading = true);

    final currentPw = currentPasswordController.text.trim();
    final newPw = newPasswordController.text.trim();
    final confirmPw = confirmPasswordController.text.trim();
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final coreValue = coreValueController.text.trim();

    if (name.isEmpty) {
      _showSnack('이름을 입력해주세요.');
      setState(() => isLoading = false);
      return;
    }

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
      await _usersApi.updateMe({'name': name});
      // 2025-11-13 핵심 가치는 MongoDB API로 분리 저장
      if (coreValue.isEmpty) {
        await _userDataApi.deleteCoreValue();
      } else {
        await _userDataApi.updateCoreValue(coreValue);
      }

      if (showPasswordFields && newPw.isNotEmpty) {
        await _changePassword(email: email, currentPw: currentPw, newPw: newPw);
        _showSnack('비밀번호가 변경되었습니다. 다시 로그인해주세요.');
        await _logout();
        return;
      }

      _showSnack('내 정보가 업데이트되었습니다.');
      setState(() {
        isEditing = false;
        showPasswordFields = false;
      });
    } catch (e) {
      _showSnack('업데이트 실패: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _logout() async {
    await _tokens.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('uid');
    await prefs.remove('email');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _changePassword({
    required String email,
    required String currentPw,
    required String newPw,
  }) async {
    // 2025-11-13 MongoDB 백엔드 비밀번호 변경 흐름
    await _authApi.login(email: email, password: currentPw);
    final token = await _authApi.requestPasswordResetToken(email);
    if (token == null || token.isEmpty) {
      throw Exception('비밀번호 변경 토큰을 가져오지 못했습니다.');
    }
    await _authApi.resetPasswordWithToken(token: token, newPassword: newPw);
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
                              child: Text(
                                joinDateText,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                  fontFamily: 'Noto Sans KR',
                                ),
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
