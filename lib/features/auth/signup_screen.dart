import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/passwod_field.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/auth_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// 회원가입 화면 - 이메일, 이름, 비밀번호, 마인드리움 코드로 회원가입
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // 코드 검증은 서버에서 수행합니다.

  Future<void> _signup() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final code = codeController.text.trim();

    if ([email, name, password, confirmPassword, code].any((e) => e.isEmpty)) {
      _showError('모든 필드를 입력해주세요.');
      return;
    }

    if (password.length < 6) {
      _showError('비밀번호는 6자리 이상이어야 합니다.');
      return;
    }

    if (password != confirmPassword) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    try {
      final tokens = TokenStorage();
      final client = ApiClient(tokens: tokens);
      final authApi = AuthApi(client, tokens);

      await authApi.signup(email: email, password: password, name: name, code: code);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해 주세요.')),
      );
      Navigator.pushReplacementNamed(context, '/login', arguments: {
        'email': email,
        'password': password,
      });
    } catch (e, stack) {
      _showError('회원가입 실패: $e');
      debugPrint('Signup error: $e');
      debugPrint('Stack: $stack');
    }
  }

  @override
  void didChangeDependencies() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      emailController.text = args['email'] ?? '';
      passwordController.text = args['password'] ?? '';
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey100,
      appBar: AppBar(
        title: const Text('회원가입'),
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          children: [
            InputTextField(
              controller: emailController,
              fillColor: Colors.white,
              label: '이메일',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSizes.space),
            InputTextField(
              controller: nameController,
              label: '이름',
              fillColor: Colors.white,
            ),
            const SizedBox(height: AppSizes.space),
            PasswordTextField(
              controller: passwordController,
              label: '비밀번호',
              isVisible: showPassword,
              toggleVisibility: () {
                setState(() {
                  showPassword = !showPassword;
                });
              },
            ),
            const SizedBox(height: AppSizes.space),
            PasswordTextField(
              controller: confirmPasswordController,
              label: '비밀번호 확인',
              isVisible: showConfirmPassword,
              toggleVisibility: () {
                setState(() {
                  showConfirmPassword = !showConfirmPassword;
                });
              },
            ),
            const SizedBox(height: AppSizes.space),
            InputTextField(
              controller: codeController,
              label: '마인드리움 코드',
              fillColor: Colors.white,
            ),
            const SizedBox(height: AppSizes.space),
            const SizedBox(height: AppSizes.space),
            PrimaryActionButton(text: '회원가입', onPressed: _signup),
          ],
        ),
      ),
    );
  }
}
