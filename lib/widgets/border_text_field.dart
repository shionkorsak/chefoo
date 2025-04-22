import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';

class BorderTextField extends StatelessWidget {
  final String label;
  final ValueChanged<String>? onChanged;

  const BorderTextField({
    Key? key,
    required this.label,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      cursorColor: AppColors.textPrimary,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(),
        ),
        enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textSecondary),
            borderRadius: kRadius10),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.textSecondary),
            borderRadius: kRadius10),
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textSecondary),
      ),
      onChanged: onChanged,
    );
  }
}
