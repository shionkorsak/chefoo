import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/calendar_screen.dart';
import 'package:chefoo/screens/login/login_screen.dart';
import 'package:chefoo/screens/placeholder/playground.dart';
import 'package:chefoo/screens/splash/splash.dart';
import 'package:chefoo/screens/testScreen.dart';
import 'package:chefoo/screens/tests/widget_test_screen2.dart';
import 'package:chefoo/services/auth/auth_service.dart';

class PlaceholderScreen extends StatelessWidget {
  PlaceholderScreen({super.key});
  // TODO: do this when you want to get user's data
  final authService = AuthService(); // Auth instance

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(60),
      alignment: Alignment.center,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: Color.fromARGB(255, 0, 0, 0),
            backgroundImage: NetworkImage(
              authService.getCurrentUserPhotoURL() ?? 
              'https://commons.wikimedia.org/wiki/File:Profile_avatar_placeholder_large.png'),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async {
              await authService.signOut();

              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (BuildContext context) => SplashScreen(isLoggedIn: false,)
                )
              );
            },
            child: Text("Sign out as ${authService.getCurrentUserDisplayName()}")
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () async { 
              await authService.deleteAccount();
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (BuildContext context) => SplashScreen(isLoggedIn: false,)
                )
              );
            },
            child: Text("Delete account"),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (BuildContext context) => UserProfileScreen()));
            }, 
            child: Text("New Update Preference")),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                // MaterialPageRoute(builder: (BuildContext context) => TestScreen()));
                MaterialPageRoute(builder: (BuildContext context) => WidgetTestScreen2()));
            }, 
            child: Text("Maps")),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (BuildContext context) => CalendarScreen()));
            }, 
            child: Text("Calendar Events")),
        ],
      ),);
  }
}
