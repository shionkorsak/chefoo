import 'package:flutter/material.dart';

class RatingSessionProvider extends ChangeNotifier {
  String? restaurantName;
  String? restaurantPhoto;
  String? restaurantId;

  void startSession({
    required String name,
    required String photo,
    required String id,
  }) {
    restaurantName = name;
    restaurantPhoto = photo;
    restaurantId = id;
    notifyListeners();
  }

  void clearSession() {
    restaurantName = null;
    restaurantPhoto = null;
    restaurantId = null;
    notifyListeners();
  }
}
