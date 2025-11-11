import 'package:flutter/material.dart';


class IconLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Axis direction;

  const IconLabel({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else {
      return Column(
        children: [
          Icon(icon, size: 60, color: color),
          const SizedBox(height: 4),
          Text(label),
        ],
      );
    }
  }
}