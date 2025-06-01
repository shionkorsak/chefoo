import 'package:chefoo/models/restaurant.dart';
import 'package:flutter/material.dart';

class RecommendedProvider with ChangeNotifier {
  List<Place> _recommended = [];
  List<Place> _enriched = [];

  List<Place> get recommended => _recommended;
  List<Place> get enriched => _enriched;

  void setRecommendations({
    required List<Place> recommended,
    required List<Place> enriched,
  }) {
    _recommended = recommended;
    _enriched = enriched;
    notifyListeners();
  }

  void clear() {
    _recommended = [];
    _enriched = [];
    notifyListeners();
  }
}
