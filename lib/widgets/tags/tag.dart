import 'package:flutter/material.dart';
import 'package:chefoo/commons.dart';

class Tag extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const Tag({
    Key? key,
    required this.label,
    this.selected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: kRadius30,
            ),
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          if (selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: kRadius30,
                  border: Border.all(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
