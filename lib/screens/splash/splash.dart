import 'dart:async';

import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/screens/main/main_screen.dart';
import 'package:chefoo/screens/welcome/get_started_screen.dart';
import 'package:chefoo/services/preload_service.dart' as preload;
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({
    super.key, 
    required this.isLoggedIn, 
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _logoOpacity;
  StreamSubscription<Position>? _locationSub;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _circleAnimation = Tween<double>(
      begin: 0,
      end: 3.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
    ));

    Future.delayed(const Duration(milliseconds: 300), handleSplashFlow);
  }

    Future<void> handleSplashFlow() async {
        final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
        final recommendationService = RecommendationService(restaurantProvider: restaurantProvider);
        
        await _controller.forward();
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        if (!widget.isLoggedIn) {
            _goToGetStarted();
            return;
        }

        try {
            // final success = await preload.PreloadService.preloadData(context, restaurantProvider);
            if (!mounted) return;

            final result = await recommendationService.fetchRecommendedPlaces(
              restaurantProvider.places,
              context,
            );

            final recommendedProvider =
                Provider.of<RecommendedProvider>(context, listen: false);

            recommendedProvider.setRecommendations(
              recommended: result['recommended'] ?? [],
              enriched: result['enriched'] ?? [],
            );

            // if (!success) {
            // _showRetryDialog("Failed to load nearby restaurants. Please check your connection and try again.");
            // return;
            // }

            _goToMainScreen();
        } catch (e) {
            print("[SplashScreen] Error during preload: $e");
            if (mounted) {
            _showRetryDialog("Something went wrong while preparing your experience.");
            }
        }
    }

  /*
  Future<bool> _waitForRecommendations(RestaurantProvider provider, {int retries = 10, Duration delay = const Duration(milliseconds: 300)}) async {
    for (int i = 0; i < retries; i++) {
      if (provider.recommendedPlaces.isNotEmpty) {
        print('[SplashScreen] Recommended places are ready.');
        return true;
      }
      print('[SplashScreen] Waiting for recommended places... attempt ${i + 1}');
      await Future.delayed(delay);
    }
    return false;
  }
  */

  void _goToMainScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => MainNavigation(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _goToGetStarted() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const GetStartedScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }


  void _showRetryDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Oops"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              handleSplashFlow();
            },
            child: const Text("Retry"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const GetStartedScreen()),
              );
            },
            child: const Text("Skip"),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _locationSub?.cancel();
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
