import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class InputTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool enabled;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final Color fillColor;
  final Function(String)? onChanged;

  const InputTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.fillColor = Colors.transparent,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          style: const TextStyle(fontSize: AppSizes.fontSize),
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText, // hintText 적용
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.all(AppSizes.padding),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: const BorderSide(color: AppColors.black12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: const BorderSide(color: AppColors.black12),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: const BorderSide(color: AppColors.black12),
            ),
          ),
        ),
      ],
    );
  }
}
