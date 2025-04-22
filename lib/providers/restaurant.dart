import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';

class RestaurantProvider with ChangeNotifier {
  List<Place> _places = [];
  Place? _selectedPlace;

  List<Place> get places => _places;
  Place? get selectedPlace => _selectedPlace;

  void setPlaces(List<Place> newPlaces) {
    _places = newPlaces;
    notifyListeners();
  }

  void setSelectedPlace(Place? place) {
    _selectedPlace = place;
    notifyListeners();
  }

  void clearPlaces() {
    _places = [];
    _selectedPlace = null;
    notifyListeners();
  }
}