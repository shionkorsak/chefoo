import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/styles/colors.dart';

class GlowingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;

  const GlowingButton({Key? key, required this.onPressed, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: kRadius30,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }
}
