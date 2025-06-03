// ignore_for_file: lines_longer_than_80_chars

import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/splash/splash.dart';
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
          if(snapshot.hasData) {
            log("[AUTH] User has signed in.");
            return PostAuthLoader(user: snapshot.data!);
          } else {
            log("[AUTH] User has not signed in.");
            return SplashScreen(isLoggedIn: false); 
          }
        }
      )
    );
  }
}

class PostAuthLoader extends StatefulWidget {
  final User user;
  const PostAuthLoader({super.key, required this.user});

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
      final restaurantProvider =
          Provider.of<RestaurantProvider>(context, listen: false);
      final recommendedProvider =
          Provider.of<RecommendedProvider>(context, listen: false);
      final ratingSessionProvider =
          Provider.of<RatingSessionProvider>(context, listen: false);

      print('[RATING] Load last sessions.');
      await ratingSessionProvider.loadSession(uid: widget.user.uid);

      final recommendationService = RecommendationService(
        restaurantProvider: restaurantProvider,
      );

      print('[RECOMMENDATION] Waiting for restaurant\'s provider.');
      await recommendationService.waitForPlacesReady(restaurantProvider);
      print('[RECOMMENDATION] Fetching recommendation');
      final result = await recommendationService.fetchRecommendedPlaces(
        restaurantProvider.places,
        context,
      );

      recommendedProvider.setRecommendations(
        recommended: result['recommended'] ?? [],
        enriched: result['enriched'] ?? [],
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainNavigation(showWelcomeDialog: true,)),
      );
    } catch (e) {
      print('[POST AUTH] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen(isLoggedIn: true); 
  }
}
