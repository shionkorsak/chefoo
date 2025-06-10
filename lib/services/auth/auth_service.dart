import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
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

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      
      try {
        if (_googleSignIn.currentUser != null) {
          await _googleSignIn.signOut();
        }
      } catch (e) {
        print('Error signing out from Google: $e');
      }
      
      log('User signed out');
    } catch (e) {
      log('Error signing out: $e');
      rethrow;
    }
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

      await user.reauthenticateWithCredential(credential);

      await _googleSignIn.signOut();
      
      await user.delete();
      log("User account deleted.");
    } catch (e) {
      log("Error deleting account: $e");
      rethrow;
    }
  }

  Future<bool> revokeCalendarPermissions() async {
  try {
    final GoogleSignInAccount? currentUser = _googleSignIn.currentUser ?? 
                                           await _googleSignIn.signInSilently();
    if (currentUser == null) {
      print('No signed-in user, cannot revoke calendar permissions');
      return false;
    }
    
    final auth = await currentUser.authentication;
    if (auth.accessToken == null) {
      print('No access token available');
      return false;
    }
    
    final url = Uri.parse('https://oauth2.googleapis.com/revoke');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'token': auth.accessToken!},
    );
    
    if (response.statusCode == 200) {
      print('Successfully revoked OAuth token with Google');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('calendar_access_revoked', true);
      
      return true;
    } else {
      print('Failed to revoke token: ${response.statusCode} ${response.body}');
      return false;
    }
  } catch (e) {
    print('Error revoking calendar permissions: $e');
    return false;
  }
}

Future<bool> signInWithGoogleAndCalendarScope() async {
  try {
    await _googleSignIn.signOut();
    
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      return false;
    }
    
    final auth = await account.authentication;
    if (auth.accessToken == null) {
      return false;
    }
    
    return true;
  } catch (e) {
    print('Error signing in with Google calendar scope: $e');
    return false;
  }
}
}