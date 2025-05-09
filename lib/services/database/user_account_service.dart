import 'dart:developer';
import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/models/user/health_insight.dart';
import 'package:chefoo/models/user/user_preference.dart';
import 'package:chefoo/models/user/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user/user_account.dart';

//? ONLY CLIENT SIDE, SERVER (AI) WILL BE DONE BY FUNCTIONS
class UserAccountService {
  final _auth = AuthService();
  String? get uid => _auth.getCurrentUser()?.uid;
  final _firestore = FirebaseFirestore.instance;

  Future<UserAccount?> fetchUserAccount() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        print('No user data found for UID: $uid, returning default data.');
      } 

      final data = doc.data()!;
      return UserAccount.fromMap(data);
    } catch (e) {
      print('Error fetching user account: $e');
      return null;
    }
  }

  Future<bool> updateUserPreferences({
    required List<String> dietaryPreferences,
    required List<String> allergies,
  }) async {
    try {
      final currentUid = uid;
      if (currentUid == null) throw Exception('No authenticated user.');
      
      await _firestore.collection('users').doc(currentUid).update({
        'preferences.dietaryPreferences': dietaryPreferences,
        'preferences.allergies': allergies,
      });
      return true;
    } catch (e) {
      log('Failed to update user preferences: $e');
      return false;
    }
  }
}
