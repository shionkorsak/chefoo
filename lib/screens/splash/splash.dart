import 'dart:async';

import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/main/main_screen.dart';
import 'package:chefoo/screens/welcome/get_started_screen.dart';
import 'package:chefoo/services/database/location_handler.dart';
import 'package:chefoo/services/preload_service.dart' as preload;
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final bool isReloading;
  final Function? onReloadComplete;
  
  const SplashScreen({
    Key? key, 
    this.isReloading = false,
    this.onReloadComplete,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _logoOpacity;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startApp();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0, end: 3.5).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  Future<void> _startApp() async {
    final locationService =
        Provider.of<LocationService>(context, listen: false);
    final restaurantProvider =
        Provider.of<RestaurantProvider>(context, listen: false);
    final recommendedProvider =
        Provider.of<RecommendedProvider>(context, listen: false);

    locationService.startLocationUpdates(context);
    LocationHandler.startLocationUpdates(context);

    if (locationService.currentPosition == null) {
      final completer = Completer<void>();
      late VoidCallback listener;
      listener = () {
        if (locationService.currentPosition != null) {
          locationService.removeListener(listener);
          completer.complete();
        }
      };
      locationService.addListener(listener);
      await completer.future;
    }

    await preload.PreloadService.preloadData(context, restaurantProvider);
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _navigateTo(const GetStartedScreen());
    } else {
      final uid = user.uid;
      final position = locationService.currentPosition;

      if (position != null) {
        await recommendedProvider.cleanupOldEntries(uid);
        await recommendedProvider.loadFromPrefs(uid, position);

        if (recommendedProvider.recommended.isEmpty) {
          final recommendationService = RecommendationService(
            restaurantProvider: restaurantProvider,
            placeService: Provider.of<PlaceService>(context, listen: false),
          );

          final result =
              await recommendationService.fetchRecommendedFromProvider(
            lat: position.latitude,
            lng: position.longitude,
          );

          await recommendedProvider.setRecommendations(
            recommended: result['recommended'] ?? [],
            enriched: result['enriched'] ?? [],
            uid: uid,
            position: position,
            radius: 1000.0,
          );

          print('[REC] Setted recommendations.');
        }
      }

      if (widget.isReloading) {
        if (widget.onReloadComplete != null) {
          widget.onReloadComplete!();
        }
        
        _navigateTo(MainNavigation(showWelcomeDialog: false));
      } else {
        _navigateTo(MainNavigation(showWelcomeDialog: false));
      }
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: curved, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final largerSize = size.width > size.height ? size.width : size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: OverflowBox(
              maxWidth: largerSize * 4,
              maxHeight: largerSize * 4,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: largerSize * _circleAnimation.value,
                    height: largerSize * _circleAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _logoOpacity,
              child: Hero(
                tag: 'logo_hero',
                child: SvgPicture.asset(
                  'assets/svgs/Logo-3.svg',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
