import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';
import 'maps.dart';

class PlaceDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlaceService _placeService;
  
  PlaceDatabase({PlaceService? placeService}) 
    : _placeService = placeService ?? PlaceService(client: http.Client());
  
  String? get _userId => _auth.currentUser?.uid;
  
  bool get isUserLoggedIn => _userId != null;
  
  Future<void> saveFavorite(String placeId) async {
    if (!isUserLoggedIn) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(placeId)
          .set({
            'placeId': placeId,
            'timestamp': DateTime.now().toIso8601String(),
          });
      print('Added place to favorites: $placeId');
    } catch (e) {
      print('Error saving favorite: $e');
      rethrow;
    }
  }
  
  Future<void> removeFavorite(String placeId) async {
    if (!isUserLoggedIn) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(placeId)
          .delete();
      print('Removed place from favorites: $placeId');
    } catch (e) {
      print('Error removing favorite: $e');
      rethrow;
    }
  }
  
  Future<bool> isFavorite(String placeId) async {
    if (!isUserLoggedIn) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .doc(placeId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }
  
  Future<void> addToHistory(String placeId) async {
    if (!isUserLoggedIn) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .doc(placeId)
          .set({
            'placeId': placeId,
            'timestamp': DateTime.now().toIso8601String(),
            'visitCount': FieldValue.increment(1),
          }, SetOptions(merge: true));
      print('Added place to history: $placeId');
    } catch (e) {
      print('Error adding to history: $e');
      rethrow;
    }
  }
  
  Future<List<String>> getFavoritePlaceIds() async {
    if (!isUserLoggedIn) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('favorites')
          .get();
      
      return snapshot.docs
          .map((doc) => doc.id)
          .toList();
    } catch (e) {
      print('Error fetching favorite IDs: $e');
      return [];
    }
  }
  
  Future<List<String>> getHistoryPlaceIds() async {
    if (!isUserLoggedIn) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => doc.id)
          .toList();
    } catch (e) {
      print('Error fetching history IDs: $e');
      return [];
    }
  }
  
  Future<List<Place>> fetchPlacesByIds(List<String> placeIds) async {
    final List<Place> places = [];
    
    for (String id in placeIds) {
      try {
        final result = await _placeService.getPlaceDetails(id);
      } catch (e) {
        print('Error fetching details for place $id: $e');
      }
    }
    
    return places;
  }
  
  Future<List<Place>> getFavoritePlaces() async {
    final ids = await getFavoritePlaceIds();
    return fetchPlacesByIds(ids);
  }
  
  Future<List<Place>> getHistoryPlaces({int limit = 20}) async {
    final ids = await getHistoryPlaceIds();
    final limitedIds = ids.length > limit ? ids.sublist(0, limit) : ids;
    return fetchPlacesByIds(limitedIds);
  }
  
  Future<void> tagPlace(String placeId, String tag) async {
    if (!isUserLoggedIn) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('tagged_places')
          .doc(placeId)
          .set({
            'placeId': placeId,
            'tags': FieldValue.arrayUnion([tag]),
            'timestamp': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
      print('Tagged place $placeId with $tag');
    } catch (e) {
      print('Error tagging place: $e');
      rethrow;
    }
  }
  
  Future<void> removeTag(String placeId, String tag) async {
    if (!isUserLoggedIn) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('tagged_places')
          .doc(placeId)
          .update({
            'tags': FieldValue.arrayRemove([tag]),
          });
      print('Removed tag $tag from place $placeId');
    } catch (e) {
      print('Error removing tag: $e');
      rethrow;
    }
  }
  
  Future<List<Place>> getPlacesByTag(String tag) async {
    if (!isUserLoggedIn) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('tagged_places')
          .where('tags', arrayContains: tag)
          .get();
      
      final placeIds = snapshot.docs
          .map((doc) => doc.id)
          .toList();
          
      return fetchPlacesByIds(placeIds);
    } catch (e) {
      print('Error fetching places by tag: $e');
      return [];
    }
  }
}