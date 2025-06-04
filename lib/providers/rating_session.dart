import 'package:chefoo/commons.dart';
import 'package:flutter/material.dart';

class RatingSessionProvider extends ChangeNotifier {
  String? restaurantId;
  String? restaurantName;
  String? restaurantPhoto;
  List<String> restaurantTags = [];

  void startSession({
    required String id,
    required String name,
    required String photo,
    required List<String> tags,
    required String uid,
  }) async {
    restaurantId = id;
    restaurantName = name;
    restaurantPhoto = photo;
    restaurantTags = tags;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rating_id_$uid', id);
    await prefs.setString('rating_name_$uid', name);
    await prefs.setString('rating_photo_$uid', photo);
    await prefs.setStringList('rating_tags_$uid', tags);
    print('[RATE] Name: $name, ID: $id, Tags: $tags, Picture: $photo');
  }

  Future<void> clearSession({required String uid}) async {
    restaurantId = null;
    restaurantName = null;
    restaurantPhoto = null;
    restaurantTags = [];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('rating_id_$uid');
    await prefs.remove('rating_name_$uid');
    await prefs.remove('rating_photo_$uid');
    await prefs.remove('rating_tags_$uid');
    print('[RATE] Rating session cleared.');
  }

  Future<void> loadSession({required String uid}) async {
    final prefs = await SharedPreferences.getInstance();
    restaurantId = prefs.getString('rating_id_$uid');
    restaurantName = prefs.getString('rating_name_$uid');
    restaurantPhoto = prefs.getString('rating_photo_$uid');
    restaurantTags = prefs.getStringList('rating_tags_$uid') ?? [];
    notifyListeners();
    print('[RATE] Loaded session.');
  }
}
