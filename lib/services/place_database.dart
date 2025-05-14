import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../commons.dart';

class PlaceDatabase {
  // firebase and service instances needed for database operations
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PlaceService _placeService;
  
  // constructor
  PlaceDatabase({PlaceService? placeService}) 
    : _placeService = placeService ?? PlaceService(client: http.Client());
  
  // get the current user ID or null if not logged in
  String? get _userId => _auth.currentUser?.uid;
  
  // check if user is currently authenticated
  bool get isUserLoggedIn => _userId != null;
  
  // adds a restaurant to the user's favorites collection
  // idk if this is how youre gonna organize it on the actual db
  // input: placeId
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
  
  // removes a restaurant from user's favorites
  // input: placeId
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
  
  // checks if a place is in the user's favorites
  // input:   placeId
  // returns: true if favorited, false otherwise
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
  
  // adds a place to user's view history and increments visit count
  // idk if we need the visit count? maybe it'll be helpful for ai? idk
  // input: placeId - the Google Place ID the user viewed
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
  
  // gets the IDs of all places in user's favorites
  // returns: list of place IDs (empty if no favorites or not logged in)
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
  
  // gets the IDs of all places in user's history, sorted by most recent first
  // returns: list of place IDs (empty if no history or not logged in)
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
  
  // gets complete Place objects for all favorites
  // you'll have to implement this on the favs page that we alr have
  // returns: list of Place objects with full details
  Future<List<Place>> getFavoritePlaces() async {
    final ids = await getFavoritePlaceIds();
    return fetchPlacesByIds(ids);
  }
  
  // gets complete Place objects for recently viewed places
  // input:   limitmax number of places to return (defaults to 20)
  // returns: list of Place objects with full details
  Future<List<Place>> getHistoryPlaces({int limit = 20}) async {
    final ids = await getHistoryPlaceIds();
    final limitedIds = ids.length > limit ? ids.sublist(0, limit) : ids;
    return fetchPlacesByIds(limitedIds);
  }

  // fetches detailed information for a list of place IDs using the Google Places API
  // input:    placeIds List of Google Place IDs to fetch
  // returns:  list of fully populated Place objects
  Future<List<Place>> fetchPlacesByIds(List<String> placeIds) async {
    final List<Place> places = [];
    
    for (String id in placeIds) {
      try {
        // use the existing PlaceService to get details for each place
        final details = await _placeService.getPlaceDetails(id);
        
        // convert the raw API data into a Place object
        final place = Place.fromGooglePlace({'place_id': id}, details);
        places.add(place);
      } catch (e) {
        print('Error fetching details for place $id: $e');
      }
    }
    
    return places;
  }
}

/* 
DATABASE INTEGRATION GUIDE:

most(?) required database functions are implemented:

1. for favorites:
   - saveFavorite(placeId) - adds a place to user's favorites in Firestore
   - removeFavorite(placeId) - removes a place from favorites 
   - isFavorite(placeId) - checks if a place is in user's favorites
   - getFavoritePlaces() - gets complete Place objects for all favorites

2. history:
   - addToHistory(placeId) - records when a user views a place and increments visit count
   - getHistoryPlaces() - gets recently viewed places, sorted by most recent first

HOW TO USE THIS CODE:

1. first make sure the user is logged in with Firebase Auth
   - all methods check isUserLoggedIn internally
   - if user is not logged in, favorites and history won't work, duhh

2. connect to key points in the UI:
   - when a restaurant card is tapped: placeDatabase.addToHistory(place.id)
   - in RestaurantDetailScreen's initState: placeDatabase.addToHistory(place.id)
   - when map marker is tapped: placeDatabase.addToHistory(place.id)
   - for like button: toggle between placeDatabase.saveFavorite() and removeFavorite()

3. to implement history screen etc:
   - create screen similar to RestaurantListContainer
   - use getHistoryPlaces() to fetch the data
   - pass to RestaurantCardListHorizontal to display
*/