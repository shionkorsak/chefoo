import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    signInOption: SignInOption.standard,
  );

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  String? getCurrentUserDisplayName() {
    return getCurrentUser()?.displayName;
  }

  String? getCurrentUserPhotoURL() {
    return getCurrentUser()?.photoURL;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.signOut();

    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) throw Exception("User cancelled sign-in");
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
    await _auth.signOut();
    print("fully sign out\n");
  }

  Future<void> deleteAccount() async {
    final user = getCurrentUser();
    if (user == null) throw Exception("No user logged in.");

    // Re-authenticate for credentials in case of security breach
    final googleUser = await _googleSignIn.signIn();
    final googleAuth = await googleUser!.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken
    );

    await user.reauthenticateWithCredential(credential);
    await _googleSignIn.signOut();
    await user.delete();
  }
}