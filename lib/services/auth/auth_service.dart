import 'dart:developer';
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

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName
  }) async {
    try {
      final UserCredential userCredential =
        await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

        await userCredential.user?.updateDisplayName(displayName);
        await userCredential.user?.reload();
        log("User signed up with $email and $displayName");

        return userCredential;
    } on FirebaseAuthException catch (e) {
      log("Sign up error: ${e.message}", name: "AuthService", error: e);
      rethrow;
    }
  }

  Future<UserCredential> signInWithEmail ({
    required String email,
    required String password
  }) async {
    try {
      final UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
          email: email, password: password);
        log("User signed in with email.", name: "AuthService");
        return userCredential;
    } on FirebaseAuthException catch (e) {
        log("Sign in error: ${e.message}", name: "AuthService", error: e);
        rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();
    await _auth.signOut();
    log("fully sign out\n");
  }

  Future<void> deleteAccount() async {
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