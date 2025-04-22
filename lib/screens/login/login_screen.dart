import 'package:flutter/material.dart';
import 'package:flutter_skeleton/commons.dart';
import 'package:flutter_skeleton/widgets/google_login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: GoogleLoginButton()));
  }
}
