import 'package:flutter/material.dart';
import 'package:flutter_skeleton/widgets/buttons/google_buttons/google_text_button.dart';

class GoogleImportButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const GoogleImportButton({
    Key? key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleTextButton(
      text: 'Import from',
      onPressed: () {},
    );
  }
}
