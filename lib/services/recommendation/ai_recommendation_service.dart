import 'dart:developer';
import 'package:chefoo/commons.dart';
import 'package:chefoo/constants.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RecommendationService  {
  final PlaceService placeService;
  final RestaurantProvider restaurantProvider;
  final FirebaseFunctions functions;

  RecommendationService ({
    required this.placeService,
    required this.restaurantProvider,
    FirebaseFunctions? firebaseFunctions,
  }) : functions = firebaseFunctions ?? FirebaseFunctions.instance;

  Future<Map<String, List<Place>>> fetchAndRecommendNearbyPlaces(
    Position position,
    BuildContext context,
  ) async {
    final cacheKey = '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}_1000';
    print('[PLACE] Fetching places for location: ${position.latitude}, ${position.longitude}');
    print('[PLACE] Using cache key: $cacheKey for nearby places');

    try {
      final response = await placeService.getNearbyPlaces(
        lat: position.latitude, 
        lng: position.longitude, 
        radius: 1000.0, 
        apiKey: MapsConstants.mapsKey);

      if(!response.success || response.data == null) {
        print('[ERROR FETCH] Failed to load places: ${response.message}');
        return _emptyResult();
      }

      print('[PLACE] Successfully loaded ${response.data!.length} places');

      final allCachedPlaces = 
        placeService.cachedPlaces.values.expand((list) => list).toList();
      final enrichedPlaceMap = 
        await _enrichPlacesWithTagsAndBanner(allCachedPlaces);

      final placesList = enrichedPlaceMap.values.map((p) => p.toJson()).toList();

      final List<Place> recommendedPlaces = 
        await _getRecommendedPlacesFromAI(placesList, enrichedPlaceMap);
      print('[DEBUG] recommendedPlaces: ${recommendedPlaces.length}');

      return {
        'recommended': recommendedPlaces,
        'enriched': enrichedPlaceMap.values.toList()
      };
    } catch (e) {
      print('[ERROR FETCH] Exception during fetchAndRecommendNearbyPlaces: $e');
      return _emptyResult();
    }
  }

  Map<String, List<Place>> _emptyResult() {
    return {
        'recommended': [],
        'enriched': [],
    };
  }

  Future<Map<String, Place>> _enrichPlacesWithTagsAndBanner(
    List<Place> places,
    {int batchSize = 5}
    ) async {
    final Map<String, Place> enrichedMap = {};

    for (int i = 0; i < places.length; i += batchSize) {
        final batch = places.sublist(
            i,
            (i + batchSize > places.length) ? places.length : i + batchSize,
        );

      final List<Future<void>> tasks = batch.map((place) async {
        try {
            final tagCall = functions.httpsCallable('generateTagsAndBanner');
            final result = await tagCall.call({'name': place.name});
            final tags = List<String>.from(result.data['tags']);
            final category = result.data['pictureCategory'];

            enrichedMap[place.id] = place.copyWith(
                tags: tags,
                pictureCategory: category,
            );

            print('[ENRICH] ${place.name} => Tags: $tags, Category: $category');
        } catch (e) {
            print('[ENRICH] Failed to enrich ${place.name}: $e');
            enrichedMap[place.id] = place;
        }
      }).toList();

    await Future.wait(tasks);
    }
    print('[ENRICH] Done with enriching places.');
    return enrichedMap;
  }

    Future<List<Place>> _getRecommendedPlacesFromAI(
        List<Map<String, dynamic>> placesList,
        Map<String, Place> enrichedPlaceMap,
    ) async {
        try {
        final HttpsCallable mainPick = functions.httpsCallable('mainPick');
        final HttpsCallableResult aiResponse = await mainPick.call({
            'data': placesList.map((p) => {
                'id': p['id'],
                'name': p['name'],
                'rating': p['rating'],
                'tags': p['tags'],
                'isFavorite': p['isFavorite'] ?? false,
            }).toList()
        });

        final dynamic recommendation = aiResponse.data['result'];
        print(recommendation);

        if (recommendation == null || recommendation.isEmpty) {
            print('[AI] RECOMMENDATION EMPTY');
            return [];
        }

        print('[AI] RECOMMENDATION RECEIVED: ${recommendation['id']}');

        final String recId = recommendation['id'];
        final List<String> recTags = List<String>.from(recommendation['tags'] ?? []);
        final String recCat = recommendation['pictureCategory'] ?? 'default';

        final Place? matched = enrichedPlaceMap[recId];
        if (matched == null) {
            print('[AI] No match found for recommended ID: $recId');
            return [];
        }

        final updatedPlace = matched.copyWith(
            tags: recTags,
            pictureCategory: recCat,
        );

        return [updatedPlace];
        } catch (e) {
        print('[ERROR AI] Failed to get AI recommendations: $e');
        return [];
        }
    }
}
