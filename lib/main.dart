import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
import 'models/restaurant.dart';
import 'constants.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'services/maps.dart';
import 'screens/testScreen.dart'; // Import your testScreen here
import 'screens.dart'; // Import the screens.dart file with the Screens class

import 'commons.dart';

void main() async {
  await MapsConstants.init();
  await initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<PlaceService>(
          create: (_) => PlaceService(
            client: http.Client(),
          ),
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
      initialRoute: Screens.testScreen,  // Set the initial route to Screens.testScreen
      routes: {
        Screens.testScreen: (_) => const TestScreen(),
        //Screens.profile: (_) => const ProfileScreen(),  // Add profile route here when needed
        // You can add more routes here as needed.
      },
    );
  }
}
