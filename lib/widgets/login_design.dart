import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';
import 'package:gad_app_team/widgets/input_text_field.dart';
import 'package:gad_app_team/widgets/primary_action_button.dart';

/// 로그인 디자인 위젯
class LoginDesign extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  const LoginDesign({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
    required this.onSignup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          /// 🌊 배경 이미지 (eduhome.png)
          Image.asset(
            'assets/image/eduhome.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),

          /// 🔲 중앙 흰색 블러 박스
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      minHeight: 480,
                    ),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFB2E8FA), // 하늘색 윤곽선
                        width: 3.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        Image.asset(
                          'assets/image/logo.png',
                          height: 120,
                          width: 120,
                        ),
                        const SizedBox(height: 24),
                        InputTextField(
                          controller: emailController,
                          label: '이메일',
                          keyboardType: TextInputType.emailAddress,
                          fillColor: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        InputTextField(
                          controller: passwordController,
                          label: '비밀번호',
                          obscureText: true,
                          fillColor: Colors.white,
                        ),
                        const SizedBox(height: 28),
                        PrimaryActionButton(text: '로그인', onPressed: onLogin),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: onSignup,
                          child: const Text(
                            '회원가입',
                            style: TextStyle(
                              fontFamily: 'Noto Sans KR',
                              color: AppColors.indigo,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
