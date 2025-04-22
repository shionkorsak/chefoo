import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'services/location.dart';
import 'services/maps.dart';
import 'providers/restaurant.dart';
import 'screens/testScreen.dart';
import 'screens.dart';
import 'commons.dart';

Future<void> initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
}

class BaseLayout extends StatefulWidget {
  final Widget child;
  final String title;

  const BaseLayout({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  @override
  void initState() {
    super.initState();
    Provider.of<LocationService>(context, listen: false).getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<LocationService>(context, listen: false)
                  .getCurrentLocation();
            },
          ),
        ],
      ),
      body: Consumer<LocationService>(
        builder: (context, locationService, child) {
          if (locationService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (locationService.error != null) {
            return Center(child: Text(locationService.error!));
          }
          
          return widget.child;
        },
      ),
    );
  }
}

void main() async {
  await MapsConstants.init();
  await initializeApp();

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
      initialRoute: Screens.testScreen,
      routes: {
        Screens.testScreen: (_) => TestScreen(),
      },
    );
  }
}
