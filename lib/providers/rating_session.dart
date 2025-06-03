import 'package:chefoo/commons.dart';
import 'package:flutter/material.dart';

class RatingSessionProvider extends ChangeNotifier {
  String? restaurantName;
  String? restaurantPhoto;
  String? restaurantId;

  void startSession({
    required String name,
    required String photo,
    required String id,
    required String uid,
  }) async {
    restaurantName = name;
    restaurantPhoto = photo;
    restaurantId = id;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rating_name_$uid', name);
    await prefs.setString('rating_photo_$uid', photo);
    await prefs.setString('rating_id_$uid', id);
  }

  Future<void> clearSession({ required String uid }) async {
    restaurantName = null;
    restaurantPhoto = null;
    restaurantId = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rating_name_$uid');
    await prefs.remove('rating_photo_$uid');
    await prefs.remove('rating_id_$uid');
  }

  Future<void> loadSession({ required String uid }) async {
    final prefs = await SharedPreferences.getInstance();
    restaurantName = prefs.getString('rating_name_$uid');
    restaurantPhoto = prefs.getString('rating_photo_$uid');
    restaurantId = prefs.getString('rating_id_$uid');
    print('[LOAD RATING] $restaurantName');
    notifyListeners();
  }
}
