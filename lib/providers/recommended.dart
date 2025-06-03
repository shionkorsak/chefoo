import 'dart:convert';

import 'package:chefoo/commons.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:flutter/material.dart';

class RecommendedProvider with ChangeNotifier {
  static const _recommendedKey = 'recommended_places';

  List<Place> _recommended = [];
  List<Place> _enriched = [];

  List<Place> get recommended => _recommended;
  List<Place> get enriched => _enriched;

  void setRecommendations({
    required List<Place> recommended,
    required List<Place> enriched,
    required String uid,
    required Position position
  }) async {
    _recommended = recommended;
    _enriched = enriched;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${uid}_recommended', jsonEncode(recommended.map((e) => e.toJson()).toList()));
    await prefs.setString('${uid}_enriched', jsonEncode(enriched.map((e) => e.toJson()).toList()));
    await prefs.setDouble('${uid}_lat', position.latitude);
    await prefs.setDouble('${uid}_lng', position.longitude);
    await prefs.setInt('${uid}_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  void clear(String uid) async {
    _recommended = [];
    _enriched = [];
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    for (var key in ['recommended', 'enriched', 'lat', 'lng', 'timestamp']) {
      await prefs.remove('${uid}_$key');
    }
  }

  Future<void> loadFromPrefs(String uid, Position currentPosition) async {
    final prefs = await SharedPreferences.getInstance();

    final lastLat = prefs.getDouble('${uid}_lat');
    final lastLng = prefs.getDouble('${uid}_lng');
    final timestamp = prefs.getInt('${uid}_timestamp');

    final isTooOld = timestamp == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) > Duration(hours: 6);

    if (lastLat == null || lastLng == null || isTooOld) {
      print('[REC] Invalid location or cache too old.');
      return;
    }

    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      lastLat,
      lastLng,
    );

    if (distance > 1000.0) {
      print('[REC] Cache location too far (${distance.toStringAsFixed(2)}m)');
      return;
    }

    final recommendedJson = prefs.getString('${uid}_recommended');
    final enrichedJson = prefs.getString('${uid}_enriched');

    print('recommended: $recommendedJson');
    
    if (recommendedJson != null) {
      _recommended = (jsonDecode(recommendedJson) as List)
          .map((e) => Place.fromJson(e))
          .toList();
    }

    if (enrichedJson != null) {
      _enriched = (jsonDecode(enrichedJson) as List)
          .map((e) => Place.fromJson(e))
          .toList();
    }

    print('[REC] Loaded valid cached recommendations.');
    notifyListeners();
  }
}
