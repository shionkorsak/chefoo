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
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  Future<void> _startApp() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final recommendedProvider = Provider.of<RecommendedProvider>(context, listen: false);

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
          final recommendationService = RecommendationService(restaurantProvider: restaurantProvider);
          await recommendationService.waitForPlacesReady(restaurantProvider);

          final Map<String, Place> uniquePlaces = {};
                            
          for (var place in restaurantProvider.routePlaces) {
            uniquePlaces[place.id] = place;
          }
          
          for (var place in restaurantProvider.places) {
            uniquePlaces[place.id] = place;
          }
          
          final List<Place> combinedPlaces = uniquePlaces.values.toList();
          
          final result = await recommendationService.fetchRecommendedPlaces(combinedPlaces, context);

          await recommendedProvider.setRecommendations(
            recommended: result['recommended'] ?? [],
            enriched: result['enriched'] ?? [],
            uid: uid,
            position: position,
          );
        }
      }

      _navigateTo(MainNavigation(showWelcomeDialog: false));
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => page,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
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


// // class SplashScreen extends StatefulWidget {
// //   final bool isLoggedIn;
// //   const SplashScreen({
// //     super.key, 
// //     required this.isLoggedIn, 
// //   });

// //   @override
// //   State<SplashScreen> createState() => _SplashScreenState();
// // }

// // class _SplashScreenState extends State<SplashScreen>
// //     with SingleTickerProviderStateMixin {
// //   late AnimationController _controller;
// //   late Animation<double> _circleAnimation;
// //   late Animation<double> _logoOpacity;
// //   StreamSubscription<Position>? _locationSub;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _controller = AnimationController(
// //       duration: const Duration(milliseconds: 1500),
// //       vsync: this,
// //     );

// //     _circleAnimation = Tween<double>(
// //       begin: 0,
// //       end: 3.5,
// //     ).animate(CurvedAnimation(
// //       parent: _controller,
// //       curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
// //     ));

// //     _logoOpacity = Tween<double>(
// //       begin: 0.0,
// //       end: 1.0,
// //     ).animate(CurvedAnimation(
// //       parent: _controller,
// //       curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
// //     ));

// //     Future.delayed(const Duration(milliseconds: 300), handleSplashFlow);
// //     _controller.forward();
// //   }
  
// //   Future<void> handleSplashFlow() async {
// //     await Future.delayed(const Duration(milliseconds: 500));

// //     if (!mounted) return;

// //     if (!widget.isLoggedIn) {
// //       print('[SPLASH] Go to get started.');
// //       _goToGetStarted();
// //       return;
// //     }
// //   }

// //     // Future<void> handleSplashFlow() async {
// //     //     final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
// //     //     final recommendationService = RecommendationService(restaurantProvider: restaurantProvider);
        
// //     //     await _controller.forward();
// //     //     await Future.delayed(const Duration(milliseconds: 500));

// //     //     if (!mounted) return;

// //     //     if (!widget.isLoggedIn) {
// //     //         _goToGetStarted();
// //     //         return;
// //     //     }

// //     //     try {
// //     //         if (!mounted) return;

// //     //         await recommendationService.waitForPlacesReady(restaurantProvider);

// //     //         final result = await recommendationService.fetchRecommendedPlaces(
// //     //           restaurantProvider.places,
// //     //           context,
// //     //         );

// //     //         final recommendedProvider =
// //     //             Provider.of<RecommendedProvider>(context, listen: false);

// //     //         recommendedProvider.setRecommendations(
// //     //           recommended: result['recommended'] ?? [],
// //     //           enriched: result['enriched'] ?? [],
// //     //         );
// //     //         _goToMainScreen();
// //     //     } catch (e) {
// //     //         print("[SplashScreen] Error during preload: $e");
// //     //         if (mounted) {
// //     //         _showRetryDialog("Something went wrong while preparing your experience.");
// //     //         }
// //     //     }
// //     // }

// //   void _goToMainScreen() {
// //     Navigator.of(context).pushReplacement(
// //       PageRouteBuilder(
// //         pageBuilder: (_, animation, __) => MainNavigation(showWelcomeDialog: true,),
// //         transitionsBuilder: (_, animation, __, child) =>
// //             FadeTransition(opacity: animation, child: child),
// //         transitionDuration: const Duration(milliseconds: 500),
// //       ),
// //     );
// //   }

// //   void _goToGetStarted() {
// //     Navigator.of(context).pushReplacement(
// //       PageRouteBuilder(
// //         pageBuilder: (_, animation, __) => const GetStartedScreen(),
// //         transitionsBuilder: (_, animation, __, child) =>
// //             FadeTransition(opacity: animation, child: child),
// //         transitionDuration: const Duration(milliseconds: 500),
// //       ),
// //     );
// //   }


// //   void _showRetryDialog(String message) {
// //     showDialog(
// //       context: context,
// //       builder: (_) => AlertDialog(
// //         title: const Text("Oops"),
// //         content: Text(message),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               Navigator.of(context).pop();
// //               // handleSplashFlow();
// //             },
// //             child: const Text("Retry"),
// //           ),
// //           TextButton(
// //             onPressed: () {
// //               Navigator.of(context).pop();
// //               Navigator.of(context).pushReplacement(
// //                 MaterialPageRoute(builder: (_) => const GetStartedScreen()),
// //               );
// //             },
// //             child: const Text("Skip"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }


// //   @override
// //   void dispose() {
// //     _locationSub?.cancel();
// //     _controller.dispose();
// //     super.dispose();
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     final size = MediaQuery.of(context).size;
// //     final largerSize = size.width > size.height ? size.width : size.height;

// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       body: Stack(
// //         children: [
// //           Center(
// //             child: OverflowBox(
// //               maxWidth: largerSize * 4,
// //               maxHeight: largerSize * 4,
// //               child: AnimatedBuilder(
// //                 animation: _controller,
// //                 builder: (context, child) {
// //                   return Container(
// //                     width: largerSize * _circleAnimation.value,
// //                     height: largerSize * _circleAnimation.value,
// //                     decoration: BoxDecoration(
// //                       shape: BoxShape.circle,
// //                       color: AppColors.background,
// //                     ),
// //                   );
// //                 },
// //               ),
// //             ),
// //           ),
// //           Center(
// //             child: FadeTransition(
// //               opacity: _logoOpacity,
// //               child: Hero(
// //                 tag: 'logo_hero',
// //                 child: SvgPicture.asset(
// //                   'assets/svgs/Logo-3.svg',
// //                   height: 120,
// //                   fit: BoxFit.contain,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }
// // }


// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _circleAnimation;
//   late Animation<double> _logoOpacity;
//   bool _hasNavigated = false;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     );

//     _circleAnimation = Tween<double>(begin: 0, end: 3.5).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)),
//     );

//     _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
//     );

//     _controller.forward();

//     _startApp();
//   }

//   Future<void> _startApp() async {
//     final locationService = Provider.of<LocationService>(context, listen: false);
//     final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

//     locationService.startLocationUpdates(context);
//     LocationHandler.startLocationUpdates(context);

//     if (locationService.currentPosition == null) {
//       final completer = Completer<void>();
//       late VoidCallback listener;
//       listener = () {
//         if (locationService.currentPosition != null) {
//           locationService.removeListener(listener);
//           completer.complete();
//         }
//       };
//       locationService.addListener(listener);
//       await completer.future;
//     }

//     await preload.PreloadService.preloadData(context, restaurantProvider);
//     await Future.delayed(const Duration(milliseconds: 1500)); // Let animation play

//     if (!mounted || _hasNavigated) return;

//     _hasNavigated = true;

//     final user = FirebaseAuth.instance.currentUser;

//     Navigator.of(context).pushReplacement(
//       PageRouteBuilder(
//         pageBuilder: (_, animation, __) =>
//             user == null ? const GetStartedScreen() : PostAuthLoader(user: user),
//         transitionsBuilder: (_, animation, __, child) {
//           final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
//           return FadeTransition(opacity: curved, child: child);
//         },
//         transitionDuration: const Duration(milliseconds: 500),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final largerSize = size.width > size.height ? size.width : size.height;

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Stack(
//         children: [
//           Center(
//             child: OverflowBox(
//               maxWidth: largerSize * 4,
//               maxHeight: largerSize * 4,
//               child: AnimatedBuilder(
//                 animation: _controller,
//                 builder: (context, child) {
//                   return Container(
//                     width: largerSize * _circleAnimation.value,
//                     height: largerSize * _circleAnimation.value,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: AppColors.background,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           Center(
//             child: FadeTransition(
//               opacity: _logoOpacity,
//               child: Hero(
//                 tag: 'logo_hero',
//                 child: SvgPicture.asset(
//                   'assets/svgs/Logo-3.svg',
//                   height: 120,
//                   fit: BoxFit.contain,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }