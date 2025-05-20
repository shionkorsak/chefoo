import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';

class Tag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final double? fontSize;

  const Tag({
    Key? key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double effectiveFontSize = fontSize ?? AppTextStyles.detail.fontSize!;
    final EdgeInsetsGeometry effectivePadding = EdgeInsets.symmetric(
      horizontal: effectiveFontSize * 1.0,
      vertical: effectiveFontSize * 0.4,
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: effectivePadding,
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.4),
              borderRadius: kRadius30,
            ),
            child: Text(
              label,
              style: AppTextStyles.detail.copyWith(
                color: AppColors.textPrimary,
                fontSize: effectiveFontSize,
              ),
            ),
          ),
          if (selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: kRadius30,
                  border: Border.all(
                    color: AppColors.primary,
                    width: effectiveFontSize * 0.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
