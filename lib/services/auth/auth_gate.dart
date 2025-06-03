// ignore_for_file: lines_longer_than_80_chars

import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/splash/splash.dart';
import 'package:chefoo/screens/welcome/get_started_screen.dart';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

//? To make sure that when user is 
//? authenticated the page should be the home page
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(), 
        builder: (context, snapshot) {
          // print('[AUTH] snapshot: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
          // print('[AUTH] snapshot.data: ${snapshot.data}');
          if(snapshot.hasData) {
            log("[AUTH] User has signed in: ${snapshot.data!.uid}");
            return PostAuthLoader(user: snapshot.data!);
          } else {
            log("[AUTH] User has not signed in.");
            return GetStartedScreen(); 
          }
        }
      )
    );
  }
}

class PostAuthLoader extends StatefulWidget {
  final User user;
  PostAuthLoader({super.key, required this.user}) {
    print('[POST-AUTH] Constructor called');
  }

  @override
  State<PostAuthLoader> createState() => _PostAuthLoaderState();
}

class _PostAuthLoaderState extends State<PostAuthLoader> {
  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    try {
      final locationService = Provider.of<LocationService>(context, listen: false);
      final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
      final recommendedProvider = Provider.of<RecommendedProvider>(context, listen: false);
      final recommendationService = RecommendationService(restaurantProvider: restaurantProvider);
      final uid = widget.user.uid;

      Position? position = locationService.currentPosition;
      print('[POST-AUTH] Loading everything');
      if (position == null) {
        log('[POST-AUTH] Cannot load without position');
        return;
      }

      log('[POST-AUTH] Loading from SharedPreference.');
      await recommendedProvider.loadFromPrefs(uid, position);

      final hasCache = recommendedProvider.recommended.isNotEmpty;

      if (!hasCache) {
        log('[POST-AUTH] Fetching new recommendations');
        final result = await recommendationService.fetchRecommendedPlaces(restaurantProvider.places, context);

        recommendedProvider.setRecommendations(
          recommended: result['recommended'] ?? [],
          enriched: result['enriched'] ?? [],
          uid: uid,
          position: position,
        );
      } else {
        log('[POST-AUTH] Using cached recommendations');
      }
      

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainNavigation(showWelcomeDialog: true,)),
      );
    } catch (e) {
      print('[POST-AUTH] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(isLoggedIn: true); 
  }
}
