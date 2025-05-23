import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/main/main_screen.dart';
import 'package:chefoo/screens/main_test.dart';
import 'package:chefoo/screens/welcome/get_started_screen.dart';
import 'package:chefoo/services/recommendation/ai_recommendation_service.dart';
import 'package:chefoo/widgets/custom_bottom_navigation_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _circleAnimation;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _circleAnimation = Tween<double>(
      begin: 0,
      end: 3.5, // Increased to ensure circle extends beyond screen edges
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
    // Future.delayed(const Duration(milliseconds: 300), () {
    //   _controller.forward().then((_) {
        
        // Future.delayed(const Duration(milliseconds: 500), () {
        //   Navigator.of(context).pushReplacement(
        //     PageRouteBuilder(
        //       pageBuilder: (context, animation, secondaryAnimation) =>
        //           const GetStartedScreen(),
        //       transitionsBuilder:
        //           (context, animation, secondaryAnimation, child) {
        //         return FadeTransition(
        //           opacity: animation,
        //           child: child,
        //         );
        //       },
        //       transitionDuration: const Duration(milliseconds: 500),
        //     ),
        //   );
        // });

    //   });
    // });
  }

  Future<void> handleSplashFlow() async {
    await _controller.forward();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (widget.isLoggedIn) {
      try {
        final placeService = Provider.of<PlaceService>(context, listen: false);
        final locationService = 
          Provider.of<LocationService>(context, listen: false);
        final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
        final aiService = RecommendationService(
          placeService: placeService,
          restaurantProvider: restaurantProvider
        );

        await locationService.getCurrentLocation();
        final position = locationService.currentPosition;
        if (position == null) throw Exception("No location found");

        final List<Place> recommended = await aiService.fetchAndRecommendNearbyPlaces(position, context);
        log('[SplashScreen] recommendedPlaces count: ${recommended.length}');

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => MainScreen(recommendedPlaces: recommended),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } catch (e) {
        log("Splash fetch error: $e");
      }
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const GetStartedScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
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
