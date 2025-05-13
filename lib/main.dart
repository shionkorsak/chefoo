import 'package:chefoo/commons.dart';
import 'package:chefoo/providers/user_account.dart';
import 'package:chefoo/services/auth/auth_gate.dart';
import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/services/calendar_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:chefoo/providers/favorites.dart';
import 'package:chefoo/screens/login/login_screen.dart';
import 'package:chefoo/screens/testScreen.dart';
import 'package:chefoo/screens/tests/widget_test_screen.dart';
import 'package:chefoo/screens/welcome/get_started.dart';
import 'package:chefoo/screens/welcome_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:chefoo/services/database/location_handler.dart';
import 'package:chefoo/providers/calendar_state.dart';
import 'package:chefoo/services/preload_service.dart';

import 'commons.dart';

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
  try {
    await initializeApp();
  } catch (e) {
    print(
        'Error in main: $e'); // we should leave this here in case my sutff throws error, sorry
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<PlaceService>(
          create: (_) => PlaceService(client: http.Client()),
        ),
        ChangeNotifierProvider<LocationService>(
          create: (_) => LocationService(),
        ),
        ChangeNotifierProvider<RestaurantProvider>(
          create: (_) => RestaurantProvider(),
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
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // location monitoring after app starts
    // dont touch pls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final locationService = Provider.of<LocationService>(context, listen: false);
      locationService.startLocationUpdates(context);
      
      PreloadService.preloadData(context);
    });

    return MaterialApp(
        theme: lightTheme,
        navigatorKey: navigatorKey,

        home: AuthGate()); //? To authenticate the user's authentication state

        ///Screen names used from file screens.dart

        // routes: {Screens.profile: (_) => const ProfileScreen()},
        //home: GetStarted());

        //! home: TestScreen());
          // this testScreen is only to visualize google maps info
          // which we are importing, and related widgets
        // home: WidgetTestScreen());

        // home: WidgetTestScreen());
  }
}