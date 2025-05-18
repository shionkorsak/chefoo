import 'dart:developer';
import 'package:chefoo/screens/placeholder/placeholder_screen.dart';
import 'package:chefoo/screens/placeholder/playground.dart';
import 'package:chefoo/screens/splash/splash.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//? To make sure that when user is authenticated the page should be the home page
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            log("User has signed in.");
            return PlaceholderScreen(); //TODO [FRONTEND]: change this to home screen
          } else {
            log("User has not signed in.");
            return SplashScreen(); //TODO: will change this to onboarding screens when frontend has made it
          }
        }
      )
    );
  }
}