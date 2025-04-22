import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_skeleton/commons.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleLoginButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(
          color: AppColors.primary,
          width: 3,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Login with',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(width: 8),
          SvgPicture.asset(
            'assets/svgs/google_icon.svg',
            height: 18,
            width: 18,
          ),
        ],
      ),
    );
  }
}
