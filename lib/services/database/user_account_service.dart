import 'dart:developer';
import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/models/user/health_insight.dart';
import 'package:chefoo/models/user/user_preference.dart';
import 'package:chefoo/models/user/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user/user_account.dart';
import 'package:cloud_functions/cloud_functions.dart';

class UserAccountService {
  final _auth = AuthService();
  String? get uid => _auth.getCurrentUserUID();
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
      final callable = 
        FirebaseFunctions.instance.httpsCallable('updateClientPreferences');

      final response = await callable.call({
        'dietaryPreferences': dietaryPreferences,
        'allergies': allergies,
      });

      // Optional: check response payload
      if (response.data['success'] == true) {
        return true;
      } else {
        throw Exception(response.data['message'] ?? 'Unknown error from cloud function.');
      }
    } catch (e) {
      print('Failed to update user preferences: $e');
      return false;
    }
  }

  
}
