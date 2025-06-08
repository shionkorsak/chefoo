import 'package:flutter/material.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/models/user/meal.dart';

class MainScreenProvider with ChangeNotifier {
  List<Place> _recommendations = [];
  List<Place> _recentMeals = [];
  List<Place> _aiGeneratedResults = [];
  List<Meal> _allMeals = [];
  String _aiQuery = '';
  bool _isLoading = false;
  bool _mapNeedsRefresh = false;

  List<Place> get recommendations => _recommendations;
  List<Place> get recentMeals => _recentMeals;
  List<Place> get aiGeneratedResults => _aiGeneratedResults;
  List<Meal> get allMeals => _allMeals;
  String get aiQuery => _aiQuery;
  bool get isLoading => _isLoading;
  bool get mapNeedsRefresh => _mapNeedsRefresh;

  void setRecommendations(List<Place> places) {
    _recommendations = places;
    notifyListeners();
  }

  void setRecentMeals(List<Place> meals) {
    _recentMeals = meals;
    notifyListeners();
  }

  void setAIGeneratedResults(String query, List<Place>? results) {
    _aiQuery = query;
    _aiGeneratedResults = results ?? [];
    notifyListeners();
  }

  void setAllMeals(List<Meal> meals) {
    _allMeals = meals;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void requestMapRefresh() {
    _mapNeedsRefresh = true;
    notifyListeners();
  }

  void clearMapRefreshFlag() {
    _mapNeedsRefresh = false;
  }

  // Example: fetch from backend or cache
  Future<void> loadMockData() async {
    setLoading(true);
    await Future.delayed(const Duration(seconds: 1));
    _recommendations = [
      Place(
        id: '1',
        name: 'Sample Place 1',
        address: '123 Sample Road',
        rating: 4.2,
        distance: 0.5,
        lat: 25.032,
        lng: 121.565,
        pictureUrls: ['sample-photo-1'],
        pictureCategory: 'default',
        tags: ['Tag1'],
        walkingDistance: 200.0,
        reviews: [],
      ),
      Place(
        id: '3',
        name: 'Sample Place 3',
        address: '789 Example Ave',
        rating: 4.5,
        distance: 0.7,
        lat: 25.034,
        lng: 121.567,
        pictureUrls: ['sample-photo-3'],
        pictureCategory: 'default',
        tags: ['Tag3'],
        walkingDistance: 300.0,
        reviews: [],
      ),
    ];
    _recentMeals = [
      Place(
        id: '2',
        name: 'Sample Place 2',
        address: '456 Mock St.',
        rating: 4.0,
        distance: 0.3,
        lat: 25.033,
        lng: 121.566,
        pictureUrls: ['sample-photo-2'],
        pictureCategory: 'default',
        tags: ['Tag2'],
        walkingDistance: 150.0,
        reviews: [],
      ),
      Place(
        id: '4',
        name: 'Sample Place 4',
        address: '987 Demo Blvd',
        rating: 3.8,
        distance: 0.6,
        lat: 25.035,
        lng: 121.568,
        pictureUrls: ['sample-photo-4'],
        pictureCategory: 'default',
        tags: ['Tag4'],
        walkingDistance: 250.0,
        reviews: [],
      ),
    ];
    _aiGeneratedResults = [
      Place(
        id: '5',
        name: 'AI Place 1',
        address: '111 AI Street',
        rating: 4.6,
        distance: 0.4,
        lat: 25.036,
        lng: 121.569,
        pictureUrls: ['sample-photo-ai1'],
        pictureCategory: 'default',
        tags: ['AI Tag1'],
        walkingDistance: 220.0,
        reviews: [],
      ),
      Place(
        id: '6',
        name: 'AI Place 2',
        address: '222 AI Avenue',
        rating: 4.3,
        distance: 0.6,
        lat: 25.037,
        lng: 121.570,
        pictureUrls: ['sample-photo-ai2'],
        pictureCategory: 'default',
        tags: ['AI Tag2'],
        walkingDistance: 280.0,
        reviews: [],
      ),
    ];
    setLoading(false);
  }
}