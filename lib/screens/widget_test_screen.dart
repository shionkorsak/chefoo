import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/widgets/border_text_field.dart';
import 'package:flutter_skeleton/widgets/buttons/glowing_button.dart';

class WidgetTestScreen extends StatelessWidget {
  const WidgetTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          BorderTextField(label: 'Enter your text here'),
          SizedBox(
            height: 32,
          ),
          GlowingButton(onPressed: () {}, text: 'Get Started'),
        ],
      ),
    )));
  }
}
