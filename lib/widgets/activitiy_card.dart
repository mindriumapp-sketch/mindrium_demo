import 'package:flutter/material.dart';
import 'package:gad_app_team/common/constants.dart';

class ActivityCard extends StatelessWidget {
  final IconData? icon;
  final double iconSize;
  final String title;
  final String subtitle;
  final bool showSubtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final List<BoxShadow>? boxShadow;
  final FontWeight titleFontWeight;
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final Color? backgroundColor;
  final Widget? trailing;
  final Widget? leading;

  const ActivityCard({
    super.key,
    this.icon,
    required this.title,
    this.subtitle = '',
    this.showSubtitle = true,
    this.iconSize = 28,
    this.onTap,
    this.enabled = false,
    this.boxShadow,
    this.titleFontWeight = FontWeight.normal, // 기본값 설정
    this.margin,
    this.showShadow = true,
    this.backgroundColor,
    this.trailing,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = enabled ? AppColors.indigo : Colors.grey;
    final Color textColor = enabled ? Colors.black : Colors.grey;
    final Color surface =
        backgroundColor ?? (enabled ? Colors.white : Colors.grey.shade300);
    final Widget? leadingWidget =
        leading ??
        (icon != null ? Icon(icon, color: iconColor, size: iconSize) : null);
    final Widget trailingWidget =
        trailing ??
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: enabled ? AppColors.indigo : Colors.grey,
        );

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: margin ?? EdgeInsets.symmetric(horizontal: AppSizes.margin),
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          boxShadow:
              showShadow
                  ? (boxShadow ??
                      const [
                        BoxShadow(color: AppColors.black12, blurRadius: 6),
                      ])
                  : null,
        ),
        child: Row(
          children: [
            if (leadingWidget != null) ...[
              leadingWidget,
              const SizedBox(width: AppSizes.space),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: titleFontWeight, // 선택 가능
                      color: textColor,
                    ),
                  ),
                  if (showSubtitle && subtitle.isNotEmpty)
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            trailingWidget,
          ],
        ),
      ),
    );
  }
}
