import 'dart:developer';

import 'package:chefoo/commons.dart' as http;
import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/services/maps.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant.dart';

class FavoritesService {
  final _auth = AuthService();
  final _placeService = PlaceService(client: http.Client());
  String? get uid => _auth.getCurrentUserUID();
  final _firestore = FirebaseFirestore.instance;

  Future<List<Place>> fetchFavorites() async {
    final snapshot = await _firestore
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .get();

    final List<Place> places = [];

    for(final doc in snapshot.docs) {
      
        final placeId = doc.id;
        final data = doc.data();
        final List<String> tags = List<String>.from(data['tags'] ?? []);
        final String pictureCat = data['pictureCategory'] ?? '';
        try {
          final details = await _placeService.getFullPlaceDetails(placeId);
          details['tags'] = tags;
          details['pictureCategory'] = pictureCat;
          final place = Place.fromPlaceDetails(details);
          places.add(place);
        } catch (e) {
          throw Exception('Error fetching details for $placeId: $e');
        }
    }
    return places;
  }

  Future<void> addFavorite(Place place) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(place.id)
          .set({
            'placeId': place.id,
            'tags': place.tags,
            'pictureCategory': place.pictureCategory
          });
    } catch (e) {
      throw Exception('Error saving favorite.');
    }
  }

  Future<void> removeFavorite(String placeId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(placeId)
          .delete();
    } catch (e) {
      throw Exception('Error removing favorite.');
    }
  }

  Future<bool> isFavorite(String placeId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('favorites')
          .doc(placeId)
          .get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check favorite.');
    }
  }
}