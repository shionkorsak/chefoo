import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';

class ActionCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const ActionCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor ?? AppColors.primary,
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor ?? AppColors.surface,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}