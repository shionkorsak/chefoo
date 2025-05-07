import 'package:flutter/foundation.dart';
import '../models/restaurant.dart';

class RestaurantProvider with ChangeNotifier {
  List<Place> _places = [];
  Place? _selectedPlace;
  bool _isLoading = false;
  String? _error;

  List<Place> get places => _places;
  Place? get selectedPlace => _selectedPlace;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setPlaces(List<Place> newPlaces) {
    _places = newPlaces;
    _error = null;
    notifyListeners();
  }

  void setSelectedPlace(Place? place) {
    _selectedPlace = place;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearPlaces() {
    _places = [];
    _selectedPlace = null;
    _error = null;
    notifyListeners();
  }
}