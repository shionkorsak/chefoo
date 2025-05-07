import 'package:chefoo/screens.dart';
import 'package:chefoo/services/auth/auth_service.dart';
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
      onPressed: () async { 
        final auth = AuthService();
         try {
          await auth.signInWithGoogle(); // Wait for sign-in
          print("logged in");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PlaceholderScreen()),
          );
        } catch (e) {
          print("Error logging in: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed. Please try again.')),
          );
        };
      }
    );
  }
}
