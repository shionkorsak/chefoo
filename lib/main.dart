import 'package:chefoo/providers/favorites.dart';
import 'package:chefoo/screens/login/login_screen.dart';
import 'package:chefoo/screens/testScreen.dart';
import 'package:chefoo/screens/welcome/get_started.dart';
import 'package:chefoo/screens/welcome_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LocationService>(context, listen: false)
          .startLocationUpdates(context);
    });

    return MaterialApp(
        theme: lightTheme,
        navigatorKey: navigatorKey,

        ///Screen names used from file screens.dart

        // routes: {Screens.profile: (_) => const ProfileScreen()},
        //home: GetStarted());
        //home: WidgetTestScreen());
        home: TestScreen());
          // this testScreen is only to visualize google maps info
          // which we are importing, and related widgets
  }
}
