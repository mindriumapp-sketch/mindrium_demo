import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

/// 비밀번호 입력용 텍스트 필드 위젯 (토글 가능)
class PasswordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isVisible;
  final VoidCallback toggleVisibility;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.isVisible,
    required this.toggleVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.all(AppSizes.padding),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide(color: AppColors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          borderSide: BorderSide(color: AppColors.black12),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey.shade600,
          ),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}