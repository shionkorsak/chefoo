// import 'dart:developer';
// import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import '../models/restaurant.dart';

// class FavoritesProvider extends ChangeNotifier {
//   Set<String> _favoriteIds = {};
//   List<Place> _favorites = [];
//   bool _isLoading = false;

//   // Getters
//   Set<String> get favoriteIds => _favoriteIds;
//   List<Place> get favorites => _favorites;
//   bool get isLoading => _isLoading;
  
//   FavoritesProvider() {
//     _loadFavorites();
//   }
  
//   Future<void> _loadFavorites() async {
//     _isLoading = true;
//     notifyListeners();
    
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final List<String> savedIds = prefs.getStringList('favorite_ids') ?? [];
//       _favoriteIds = Set<String>.from(savedIds);
      
//       _favorites = [];
//       for (String id in _favoriteIds) {
//         final String? placeJson = prefs.getString('place_$id');
//         if (placeJson != null) {
//           try {
//             log(placeJson);
//             final Map<String, dynamic> placeMap = json.decode(placeJson);
//             _favorites.add(Place(
//               id: placeMap['id'],
//               name: placeMap['name'],
//               rating: placeMap['rating'],
//               address: placeMap['address'],
//               distance: placeMap['distance'],
//               tags: List<String>.from(placeMap['tags'] ?? []),
//               lat: placeMap['lat'],
//               lng: placeMap['lng'],
//               phone: placeMap['phone'],
//               reviews: [],
//               pictureUrls: List<String>.from(placeMap['pictureUrls'] ?? []),
//               openingHours: null,
//               isOpenNow: placeMap['isOpenNow'],
//               walkingDistance: placeMap['walkingDistance'] ?? 0.0,
//             ));
//           } catch (e) {
//             print('Error loading place $id: $e');
//           }
//         }
//       }
//     } catch (e) {
//       print('Error loading favorites: $e');
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }
  
//   bool isFavorite(String id) {
//     return _favoriteIds.contains(id);
//   }
  
//   Future<void> toggleFavorite(Place place) async {
//     if (isFavorite(place.id)) {
//       await removeFavorite(place);
//     } else {
//       await addFavorite(place);
//     }
//   }
  
//   Future<void> addFavorite(Place place) async {
//     if (!_favoriteIds.contains(place.id)) {
//       _favoriteIds.add(place.id);
//       _favorites.add(place);
      
//       await _saveFavorites();
//       notifyListeners();
//     }
//   }
  
//   Future<void> removeFavorite(Place place) async {
//     _favoriteIds.remove(place.id);
//     _favorites.removeWhere((p) => p.id == place.id);
    
//     await _saveFavorites();
//     notifyListeners();
//   }
  
//   Future<void> _saveFavorites() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       await prefs.setStringList('favorite_ids', _favoriteIds.toList());
      
//       for (Place place in _favorites) {
//         final Map<String, dynamic> placeMap = {
//           'id': place.id,
//           'name': place.name,
//           'rating': place.rating,
//           'address': place.address,
//           'distance': place.distance,
//           'tags': place.tags,
//           'lat': place.lat,
//           'lng': place.lng,
//           'phone': place.phone,
//           'pictureUrls': place.pictureUrls,
//           'isOpenNow': place.isOpenNow,
//           'walkingDistance': place.walkingDistance,
//         };
        
//         await prefs.setString('place_${place.id}', json.encode(placeMap));
//       }
//     } catch (e) {
//       print('Error saving favorites: $e');
//     }
//   }
// }

import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../services/database/favorite_service.dart';

class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _service = FavoritesService();
  List<Place> _favorites = [];
  bool _isLoading = false;

  List<Place> get favorites => _favorites;
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();
    try {
      _favorites = await _service.fetchFavorites();
    } catch (e) {
      print('Error loading favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(String id) {
    return _favorites.any((p) => p.id == id);
  }

  Future<void> toggleFavorite(Place place) async {
    if (isFavorite(place.id)) {
      await _service.removeFavorite(place.id);
      _favorites.removeWhere((p) => p.id == place.id);
    } else {
      await _service.addFavorite(place);
      _favorites.add(place);
    }
    notifyListeners();
  }
}