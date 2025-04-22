import 'package:flutter_skeleton/screens/login/login_screen.dart';
import 'package:flutter_skeleton/screens/welcome_screen.dart';
import 'package:flutter_skeleton/screens/widget_screens/widgets_onboarding.dart';

import 'commons.dart';

void main() async {
  await initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: lightTheme,
        navigatorKey: navigatorKey,

        ///Screen names used from file screens.dart

        // routes: {Screens.profile: (_) => const ProfileScreen()},
        home: WidgetTestScreen());
  }
}
