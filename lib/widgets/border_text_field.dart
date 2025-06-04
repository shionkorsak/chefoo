import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';

class BorderTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? labelColor;
  final Color? cursorColor;

  const BorderTextField({
    Key? key,
    required this.label,
    this.controller,
    this.onChanged,
    this.borderColor,
    this.focusedBorderColor,
    this.labelColor,
    this.cursorColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      cursorColor: cursorColor ?? AppColors.textPrimary,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor ?? AppColors.textSecondary),
          borderRadius: kRadius10,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              BorderSide(color: focusedBorderColor ?? AppColors.textSecondary),
          borderRadius: kRadius10,
        ),
        labelText: label,
        labelStyle: TextStyle(color: labelColor ?? AppColors.textSecondary),
      ),
      onChanged: onChanged,
    );
  }
}
