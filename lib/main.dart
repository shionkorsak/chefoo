import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/services/auth/auth_gate.dart';
import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:chefoo/screens/login/login_screen.dart';
import 'package:chefoo/screens/testScreen.dart';
import 'package:chefoo/screens/tests/widget_test_screen.dart';
import 'package:chefoo/screens/tests/widget_test_screen2.dart';
import 'package:chefoo/screens/welcome/get_started.dart';
import 'package:chefoo/screens/welcome/get_started_screen.dart';
import 'package:chefoo/screens/welcome_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:chefoo/screens/settings/account_settings.dart';
import 'package:chefoo/services/database/location_handler.dart';
import 'package:chefoo/providers/calendar_state.dart';
import 'package:chefoo/services/preload_service.dart';

import 'package:chefoo/screens/splash/splash.dart';
import 'commons.dart';
import 'package:chefoo/services/preload_service.dart' as preload;

import 'package:chefoo/screens/rating/rating_screen.dart';
import 'package:chefoo/screens/map_view.dart';

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
          create: (_) => FavoritesProvider(),
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
          create: (_) => RestaurantProvider(),
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
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
    // location monitoring after app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      locationService.startLocationUpdates(context);
    
      try {
        preload.PreloadService.preloadData(context, restaurantProvider);
      } catch (e) {
        print('Error preloading data: $e');
      }
    });

    return MaterialApp(
        theme: lightTheme,
        navigatorKey: navigatorKey,
        //home: AuthGate());

        ///Screen names used from file screens.dart

        // routes: {Screens.profile: (_) => const ProfileScreen()},
        // home: GetStarted());
        // home: WidgetTestScreen());
        // home: WidgetTestScreen2());
        // home: TestScreen());
        home: GetStartedScreen());
        // home: const SplashScreen());
        // home: SettingsScreen());
        // home: RatingScreen());
        // home: MapViewScreen());
    // this testScreen is only to visualize google maps info
    // which we are importing, and related widgets
  }
}

