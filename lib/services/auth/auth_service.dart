import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
    ],
    signInOption: SignInOption.standard,
  );

  GoogleSignIn get googleSignIn => _googleSignIn;

  User? getCurrentUser() { // Get current user's instance
    return _auth.currentUser;
  }

  String? getCurrentUserUID() {
    return getCurrentUser()?.uid;
  }

  String? getCurrentUserDisplayName() { // Get current user's display name
    return getCurrentUser()?.displayName;
  }

  String? getCurrentUserPhotoURL() { // Get current user's photo URL
    return getCurrentUser()?.photoURL;
  }

  Future<UserCredential> signInWithGoogle() async { // Sign in with Google
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

  Future<void> signOut() async { // To sign out
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
    await _auth.signOut();
    log("fully sign out\n");
  }

  Future<void> deleteAccount() async { // To delete account
    final user = getCurrentUser();
    if (user == null) throw Exception("No user logged in.");

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception("User cancelled re-authentication");

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Reauthenticate
      await user.reauthenticateWithCredential(credential);

      // Sign out from Google
      await _googleSignIn.signOut();
      
      // Delete the account
      await user.delete();
      log("User account deleted.");
    } catch (e) {
      log("Error deleting account: $e");
      rethrow;
    }
  }
}