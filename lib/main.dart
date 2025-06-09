import 'dart:async';
import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/get_started.dart';
import 'package:chefoo/providers/main_screen.dart';
import 'package:chefoo/providers/meal_history.dart';
import 'package:chefoo/providers/rating_session.dart';
import 'package:chefoo/providers/recommended.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/screens/splash/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification/notification_service.dart';
import 'firebase_options.dart';

Future<void> initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load();
    await MapsConstants.init();
  } catch (e) {
    print('Error initializing app: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<PlaceService>(
          create: (_) => PlaceService(client: Client()),
        ),
        ChangeNotifierProvider<LocationService>(
          create: (_) => LocationService(),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider()..loadFavorites(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserAccountProvider(),
        ),
        Provider<CalendarService>(
          create: (_) => CalendarService(),
        ),
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<CalendarStateProvider>(
          create: (_) => CalendarStateProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RestaurantProvider()
        ),
        ChangeNotifierProvider<GetStartedProvider>(
          create: (_) => GetStartedProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => MainScreenProvider(),
        ),
        ChangeNotifierProvider(create: (_) => RecommendedProvider()),
        ChangeNotifierProvider(create: (_) => RatingSessionProvider()),
        ChangeNotifierProvider(
          create: (_) => MealHistoryProvider()..fetchMeals(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: lightTheme,
      navigatorKey: navigatorKey,
      home: const SplashScreen(), // All logic is handled here now
    );
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   Future<void> _runPreload(BuildContext context) async {
//     final locationService = Provider.of<LocationService>(context, listen: false);
//     final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

//     locationService.startLocationUpdates(context);
//     LocationHandler.startLocationUpdates(context);

//     // Wait until currentPosition is available
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

//     // Fetch location-based places for preload
//     await preload.PreloadService.preloadData(context, restaurantProvider);
//     print('Places loaded: ${restaurantProvider.places.length}');
//   }

//   // @override
//   // Widget build(BuildContext context) {
//   //   final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
//   //   // location monitoring after app starts
//   //   WidgetsBinding.instance.addPostFrameCallback((_) async {
//   //     final locationService = Provider.of<LocationService>(context, listen: false);
//   //     locationService.startLocationUpdates(context);
      
//   //     locationService.addListener(() {
//   //       if (locationService.currentPosition != null && 
//   //           Provider.of<RestaurantProvider>(context, listen: false).places.isEmpty) {
//   //         print('Location available now, loading places...');
//   //         _loadPlacesForLocation(context, locationService.currentPosition!);
//   //       }
//   //     });
      
//   //     LocationHandler.startLocationUpdates(context);

//   //     if (locationService.currentPosition != null) {
//   //       LocationHandler.fetchNearbyPlaces(context, locationService.currentPosition!);
//   //     }
      
//   //     try {
//   //       await preload.PreloadService.preloadData(context, restaurantProvider);
//   //       print('Places loaded: ${restaurantProvider.places.length}');
//   //     } catch (e) {
//   //       print('Error preloading data: $e');
//   //     }
//   //   });

//   //   return MaterialApp(
//   //       theme: lightTheme,
//   //       navigatorKey: navigatorKey,

//   //       home: AuthGate());
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<void>(
//       future: _runPreload(context),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState != ConnectionState.done) {
//           return MaterialApp(
//             theme: lightTheme,
//             home: const SplashScreen(isLoggedIn: false),
//           );
//         }

//         return MaterialApp(
//           theme: lightTheme,
//           navigatorKey: navigatorKey,
//           home: const AuthGate(),
//         );
//       },
//     );
//   }
  
//   Future<void> _loadPlacesForLocation(BuildContext context, Position position) async {
//     final placeService = Provider.of<PlaceService>(context, listen: false);
//     final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
//     try {
//       final response = await placeService.getNearbyPlaces(
//         lat: position.latitude,
//         lng: position.longitude,
//         radius: 1000,
//         apiKey: MapsConstants.mapsKey,
//       );
      
//       if (response.success && response.data != null) {
//         print('[MAIN]');
//         print('Loaded ${response.data!.length} places at current location');
//         restaurantProvider.setPlaces(response.data!);
//       }
//     } catch (e) {
//       print('Error loading places: $e');
//     }
//   }
// }

// class MyApp extends StatefulWidget {
//   const MyApp({super.key});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> {
//   bool _preloadDone = false;

//   @override
//   void initState() {
//     super.initState();
//     _runPreload();
//   }

//   Future<void> _runPreload() async {
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
//     await Future.delayed(const Duration(milliseconds: 1500)); // Wait for animation

//     if (mounted) setState(() => _preloadDone = true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       theme: lightTheme,
//       navigatorKey: navigatorKey,
//       home: const SplashScreen(), 
//     );
//   }


// }
