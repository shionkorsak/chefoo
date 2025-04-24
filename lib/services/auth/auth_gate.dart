import 'package:chefoo/screens/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../screens/placeholder/placeholder_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            print("Has logged in.");
            return PlaceholderScreen(); //TODO [FRONTEND]: change this to home screen
          } else {
            print("Has not logged in.");
            return const LoginScreen(); //TODO: will change this to onboarding screens when frontend has made it
          }
        }
      )
    );
  }
}