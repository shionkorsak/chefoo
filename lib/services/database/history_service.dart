import 'package:chefoo/commons.dart' as http;
import 'package:chefoo/models/user/meal.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/services/auth/auth_service.dart';
import 'package:chefoo/services/maps.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class HistoryService {
  final _auth = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _placeService = PlaceService(client: http.Client());
  String? get uid => _auth.getCurrentUserUID();

  Future<void> addMealInputs({
    required Map<String, dynamic> restaurant,
    required List<Map<String, String>> meals,
    double rating = 5.0
  }) async {
    String getFormattedTimestamp() {
      final now = DateTime.now().toUtc();
      final formatted = now.toIso8601String();

      final match = RegExp(r'^(.+\.\d{3})').firstMatch(formatted);
      final timestamp = match != null ? match.group(1)! : formatted;

      return '${timestamp}Z';
    }

    final isoTimestamp = getFormattedTimestamp();


    if (uid == null) throw Exception('[HISTORY] User not logged in.');

    for(final meal in meals) {
      final mealName = meal['meal'] ?? '';

      String formatRealName(String name) {
        return name
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '-') // keep only alphanumerics, replace others with hyphens
            .replaceAll(RegExp(r'-+'), '-')         // compress multiple dashes
            .replaceAll(RegExp(r'^-+|-+$'), '');    // trim leading/trailing dashes
      }

      final formattedName = formatRealName(mealName);
      final mealId = '${isoTimestamp}_$formattedName';
      final comment = meal['comment'] ?? '';


      final data = {
        'profile': {
          'time': isoTimestamp,
          'restaurant': {
            'id': restaurant['id'],
            'tags': restaurant['tags'],
            'pictureCategory': restaurant['pictureCategory'],
          },
          'mealId': mealId,
          'name': mealName,
        },
        'feedback': {
          'rating': rating,
          if(comment.isNotEmpty) 'notes': comment,
        },
      };

      try {
        final docRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('mealHistory')
          .doc(mealId);

        await docRef.set(data);
        print('[HISTORY] Meal input added: $mealId');

        try {
          final callable = FirebaseFunctions.instance.httpsCallable('processMealAnalysis');
          final result = await callable.call({
            'uid': uid,
            'mealId': mealId,
          });
          print('[HISTORY] Called processMealAnalysis: ${result.data}');
        } catch (e) {
          print('[HISTORY] Error calling processMealAnalysis: $e');
        }

        
      } catch (e) {
        print('[HISTORY] Failed to store meal input.');
      }
    }
  }

  Future<List<Meal>> fetchMeals() async {
    if (uid == null) throw Exception('[HISTORY] User not logged in.');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('mealHistory')
          .orderBy('profile.time', descending: true)
          .get();

      final List<Meal> meals = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final restaurant = data['profile']?['restaurant'];
        final restaurantId = restaurant['id'];
        final restaurantTags = restaurant['tags'];
        final restaurantPic = restaurant['pictureCategory'];

        if (restaurant == null) continue;

        try {
          final placeDetails = await _placeService.getFullPlaceDetails(restaurantId);
          placeDetails['tags'] = restaurantTags;
          placeDetails['pictureCategory'] = restaurantPic;
          final place = Place.fromPlaceDetails(placeDetails);
          final meal = Meal.fromFirestoreAndPlace(data: data, restaurant: place);
          meals.add(meal);
        } catch (e) {
          print('[HISTORY] Error fetching place $restaurantId: $e');
        }
      }

      return meals;
    } catch (e) {
      print('[HISTORY] Error fetching meal inputs: $e');
      throw Exception('Failed to fetch meal history.');
    }
  }
}