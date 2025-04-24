import 'package:chefoo/screens/login/login_screen.dart';
import 'package:chefoo/screens/welcome_screen.dart';
import 'package:chefoo/screens/widget_screens/widgets_onboarding_screen.dart';
import 'package:chefoo/services/auth/auth_gate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'commons.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        home: AuthGate());
  }
}
