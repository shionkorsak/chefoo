import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/restaurant.dart';

class RestaurantProvider with ChangeNotifier {
  List<Place> _places = [];
  List<Place> _routePlaces = [];
  Place? _selectedPlace;
  bool _isLoading = false;
  String? _error;
  bool _routePlacesLoaded = false;
  Map<String, List<Place>> _routePlacesCache = {};

  List<Place> get places => _places;
  List<Place> get routePlaces => _routePlaces;
  Place? get selectedPlace => _selectedPlace;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get routePlacesLoaded => _routePlacesLoaded;

  void setPlaces(List<Place> places) {
    _places = places;
    _savePlacesToPrefs();
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

  void addPlaces(List<Place> newPlaces) {
    final oldCount = _places.length;

    final Map<String, Place> uniquePlaces = {};
    
    for (var place in _places) {
      uniquePlaces[place.id] = place;
    }
    
    for (var place in newPlaces) {
      uniquePlaces[place.id] = place;
    }
    
    _places = uniquePlaces.values.toList();
    _savePlacesToPrefs();

    print('Places list updated: ${oldCount} -> ${_places.length} (+${_places.length - oldCount} new)');
    notifyListeners();
  }

  void setRoutePlaces(List<Place> places, String routeKey) {
    _routePlaces = places;
    _routePlacesCache[routeKey] = places;
    
    print('Adding ${places.length} route places to main places list');
    addPlaces(places);
    
    notifyListeners();
  }

  void setRoutePlacesLoaded(bool loaded) {
    _routePlacesLoaded = loaded;
    notifyListeners();
  }

  void clearRoutePlaces() {
    _routePlaces = [];
    notifyListeners();
  }

  Future<void> _savePlacesToPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String placesJson = jsonEncode(_places.map((p) => p.toJson()).toList());
      await prefs.setString('nearby_places', placesJson);
      print('Saved ${_places.length} places to SharedPreferences');
    } catch (e) {
      print('Error saving places to SharedPreferences: $e');
    }
  }

  Future<void> _loadPlacesFromPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? placesJson = prefs.getString('nearby_places');
      if (placesJson != null) {
        final List<dynamic> decodedPlaces = jsonDecode(placesJson);
        _places = decodedPlaces.map((json) => Place.fromJson(json)).toList();
        print('Loaded ${_places.length} places from SharedPreferences');
      }
      notifyListeners();
    } catch (e) {
      print('Error loading places from SharedPreferences: $e');
    }
  }

  
}