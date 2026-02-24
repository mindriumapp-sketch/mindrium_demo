import 'package:flutter/material.dart';

// import 'package:gad_app_team/utils/text_line_material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';
import 'package:gad_app_team/widgets/passwod_field.dart';
import 'package:gad_app_team/data/api/api_client.dart';
import 'package:gad_app_team/data/api/auth_api.dart';
import 'package:gad_app_team/data/storage/token_storage.dart';

/// 회원가입 화면 - 이메일, 이름, 전화번호, 비밀번호, 마인드리움 코드(6자리)로 회원가입
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static final RegExp _passwordRegex =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,20}$');
  static const String _passwordPolicyMessage =
      '비밀번호는 8~20자이며, 영문자/숫자/특수문자를 각각 1자 이상 포함해야 합니다.';

  // (추가) mindrium_code는 숫자 6자리
  static final RegExp _codeRegex = RegExp(r'^\d{6}$');

  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController(); // (추가) 전화번호
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final codeController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signup() async {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim(); // (추가)
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final code = codeController.text.trim();

    // (변경) phone 필수
    if ([email, name, phone, password, confirmPassword, code]
        .any((e) => e.isEmpty)) {
      _showError('모든 필드를 입력해주세요.');
      return;
    }

    if (!_passwordRegex.hasMatch(password)) {
      _showError(_passwordPolicyMessage);
      return;
    }

    if (password != confirmPassword) {
      _showError('비밀번호가 일치하지 않습니다.');
      return;
    }

    // (추가) 마인드리움 코드는 숫자 6자리만 허용(서버에서도 검증함)
    if (!_codeRegex.hasMatch(code)) {
      _showError('마인드리움 코드는 숫자 6자리여야 합니다.');
      return;
    }

    try {
      final tokens = TokenStorage();
      final client = ApiClient(tokens: tokens);
      final authApi = AuthApi(client, tokens);

      await authApi.signup(
        email: email,
        password: password,
        name: name,
        phone: phone,
        code: code,
      );

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
            onPressed: () => Navigator.pop(context),
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

            // (추가) 전화번호
            InputTextField(
              controller: phoneController,
              label: '전화번호',
              fillColor: Colors.white,
              keyboardType: TextInputType.phone,
              hintText: '예) 01012345678 또는 010-1234-5678',
            ),

            const SizedBox(height: AppSizes.space),
            _buildPasswordPolicy(),
            const SizedBox(height: AppSizes.space),
            PasswordTextField(
              controller: passwordController,
              label: '비밀번호',
              isVisible: showPassword,
              toggleVisibility: () {
                setState(() => showPassword = !showPassword);
              },
            ),
            const SizedBox(height: AppSizes.space),
            PasswordTextField(
              controller: confirmPasswordController,
              label: '비밀번호 확인',
              isVisible: showConfirmPassword,
              toggleVisibility: () {
                setState(() => showConfirmPassword = !showConfirmPassword);
              },
            ),
            const SizedBox(height: AppSizes.space),

            // (변경) 마인드리움 코드: 숫자 6자리
            InputTextField(
              controller: codeController,
              label: '마인드리움 코드(6자리)',
              fillColor: Colors.white,
              keyboardType: TextInputType.number,
              hintText: '예) 111111',
            ),

            const SizedBox(height: AppSizes.space),
            PrimaryActionButton(text: '회원가입', onPressed: _signup),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordPolicy() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '비밀번호 정책',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 6),
          Text('• 8~20자 길이', style: TextStyle(color: Colors.black87)),
          Text('• 영문자, 숫자, 특수문자를 각각 1자 이상 포함',
              style: TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }
}
