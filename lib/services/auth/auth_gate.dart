import 'dart:developer';
import 'package:chefoo/screens/login/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../screens/placeholder/placeholder_screen.dart';

class AuthGate extends StatelessWidget {
  //? To make sure that when user is authenticated the page should be the home page
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            log("Has logged in.");
            return PlaceholderScreen(); //TODO [FRONTEND]: change this to home screen
          } else {
            log("Has not logged in.");
            return const LoginScreen(); //TODO: will change this to onboarding screens when frontend has made it
          }
        }
      )
    );
  }
}