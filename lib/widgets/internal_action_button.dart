import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class InternalActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const InternalActionButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.backgroundColor = Colors.indigo, 
    this.textColor = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.borderRadius)),
        fixedSize: const Size(144, 48),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor),
      ),
    );
  }
}