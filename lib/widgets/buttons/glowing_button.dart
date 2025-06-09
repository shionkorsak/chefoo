import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';
import 'package:chefoo/styles/colors.dart';

class GlowingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? textColor;
  final Color? backgroundColor;
  final Color? glowColor;
  final bool isEnabled;

  const GlowingButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.textColor,
    this.backgroundColor,
    this.glowColor,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: kRadius30,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.primary).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled
              ? (backgroundColor ?? AppColors.primary)
              : Colors.grey,
        ),
        onPressed: isEnabled ? onPressed : null,
        child: Text(
          text,
          style: TextStyle(color: textColor ?? AppColors.surface),
        ),
      ),
    );
  }
}
