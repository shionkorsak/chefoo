import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/widgets/buttons/glowing_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: GlowingButton(onPressed: () {}, text: 'Get Started')));
  }
}
