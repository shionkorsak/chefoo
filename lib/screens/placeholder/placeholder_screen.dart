import 'package:chefoo/commons.dart';
import 'package:chefoo/screens/login/login_screen.dart';
import 'package:chefoo/screens/widget_screens/widgets_onboarding_screen.dart';
import 'package:chefoo/services/auth/auth_service.dart';

class PlaceholderScreen extends StatelessWidget {
  PlaceholderScreen({super.key});
  final authService = AuthService();

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
                  builder: (BuildContext context) => LoginScreen()
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
                  builder: (BuildContext context) => WidgetsOnboardingScreen()
                )
              );
            },
            child: Text("Delete account"),
          ),
          SizedBox(height: 30),

        ],
      ),);
  }
}
