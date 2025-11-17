import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gad_app_team/widgets/login_design.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/auth_api.dart';
import 'package:gad_app_team/data/api/users_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// 로그인 화면 (기능 로직만)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('이메일과 비밀번호를 입력해주세요.');
      return;
    }

    final tokens = TokenStorage();
    final client = ApiClient(tokens: tokens);
    final authApi = AuthApi(client, tokens);
    final usersApi = UsersApi(client);

    try {
      await authApi.login(email: email, password: password);
      final me = await usersApi.me();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('uid', me['id'] ?? me['_id'] ?? '');
      await prefs.setString('email', me['email'] ?? email);

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/tutorial',
        arguments: {
          'uid': me['id'] ?? me['_id'],
          'email': me['email'] ?? email,
          'userData': me,
        },
      );
    } catch (e) {
      // 백엔드에서 401 / 400 등을 던지면 여기로 옴.
      _showError('로그인 실패: ${e is Exception ? e.toString() : '오류'}');
      // 사용자 없을 가능성 → 가입 화면 이동 유도
      Navigator.pushNamed(
        context,
        '/terms',
        arguments: {'email': email, 'password': password},
      );
    }
  }

  // Firebase 에러 코드 분기 제거됨

  void _goToSignup() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    Navigator.pushNamed(
      context,
      '/terms',
      arguments: {'email': email, 'password': password},
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginDesign(
      emailController: emailController,
      passwordController: passwordController,
      onLogin: _login,
      onSignup: _goToSignup,
    );
  }
}
