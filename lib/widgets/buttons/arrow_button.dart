import 'package:chefoo/commons.dart';
import 'package:flutter/widgets.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

class ArrowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ArrowButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(IconsaxPlusLinear.arrow_circle_right),
      color: AppColors.secondary,
      iconSize: 24,
    );
  }
}
