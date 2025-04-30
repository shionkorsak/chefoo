import 'package:flutter/material.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_text_button.dart';

class GoogleLoginButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleLoginButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleTextButton(
      text: 'Login with',
      onPressed: onPressed,
    );
  }
}
