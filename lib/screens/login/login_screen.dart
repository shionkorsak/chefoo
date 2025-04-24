import 'package:chefoo/commons.dart';
import 'package:chefoo/widgets/buttons/google_buttons/google_login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: GoogleLoginButton()));
  }
}
