import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AIRecommendationService {
  final PlaceService placeService;
  final RestaurantProvider restaurantProvider;
  final FirebaseFunctions functions;

  AIRecommendationService({
    required this.placeService,
    required this.restaurantProvider,
    FirebaseFunctions? firebaseFunctions,
  }) : functions = firebaseFunctions ?? FirebaseFunctions.instance;

  Future<void> fetchAndRecommendNearbyPlaces(Position position, BuildContext context) async {
    final cacheKey = '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}_1000';
    print('Fetching places for location: ${position.latitude}, ${position.longitude}');
    print('Using cache key: $cacheKey for nearby places');

    try {
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude,
        lng: position.longitude,
        radius: 1000.0,
        apiKey: MapsConstants.mapsKey,
      );

      if (response.success && response.data != null) {
        print('Successfully loaded ${response.data!.length} places');

        final placesList = await placeService.exportCachedPlacesAsList(context);

        final HttpsCallable callable = functions.httpsCallable('mainPick');
        final aiResponse = await callable.call({'data': placesList});
        final List<dynamic> recommendations = aiResponse.data['result'];
        if(recommendations.isEmpty) {
          log('AI returned no recommendations. Falling back to raw places.');
          
        }
        final List<Place> allCachedPlaces = placeService.cachedPlaces.values.expand((list) => list).toList();

        final Map<String, List<Place>> newCache = {};

        for (var rec in recommendations) {
          final String recId = rec['id'];
          final List<String> recTags = List<String>.from(rec['tags']);
          final String recCat = rec['pictureCategory'];
          print("recCat: $recCat");

          Place? match = allCachedPlaces.where((p) => p.id == recId).firstOrNull;

          if (match != null) {
            final updatedPlace = match.copyWith(
              tags: recTags, 
              pictureCategory: recCat
            );
            newCache.putIfAbsent('recommended', () => []).add(updatedPlace);
          }
        }

        restaurantProvider.setPlaces(newCache['recommended'] ?? []);

        if (response.message.contains('cache') == true) {
          print('Used cache with ${response.data!.length} places');
        }
      } else {
        print('Failed to load places: ${response.message}');
      }
    } catch (e) {
      print('Error fetching nearby places: $e');
      rethrow; 
    }
  }
}
