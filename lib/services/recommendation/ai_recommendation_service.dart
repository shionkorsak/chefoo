import 'dart:async';

import 'package:chefoo/commons.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RecommendationService  {
  final RestaurantProvider restaurantProvider;
  final FirebaseFunctions functions;

  RecommendationService ({
    required this.restaurantProvider,
    FirebaseFunctions? firebaseFunctions,
  }) : functions = firebaseFunctions ?? FirebaseFunctions.instance;

  Future<Map<String, List<Place>>> fetchRecommendedPlaces(
    List<Place> availablePlaces,
    BuildContext context,
  ) async {
    print('[AI] Start AI recommendation');
    try {
      print('[AI] Places provided: ${availablePlaces.map((p) => p.toJson()).toList()}');
      final allPlaces = availablePlaces;
      final enrichedPlaceMap = 
        await _enrichPlacesWithTagsAndBanner(allPlaces);

      final placesList = enrichedPlaceMap.values.map((p) => p.toJson()).toList();

      final List<Place> recommendedPlaces = 
        await _getRecommendedPlacesFromAI(placesList, enrichedPlaceMap);
      print('[DEBUG] recommendedPlaces: ${recommendedPlaces.length}');

      final Set<String> recommendedIds = recommendedPlaces.map((p) => p.id).toSet();
      final List<Place> filteredEnriched = enrichedPlaceMap.values
          .where((p) => !recommendedIds.contains(p.id))
          .toList();

      return {
        'recommended': recommendedPlaces,
        'enriched': filteredEnriched,
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
      final List<Map<String, dynamic>> enrichedListForAI = [];

      // 🧠 Copy enriched fields before sending to AI
      for (final placeJson in placesList) {
        final String id = placeJson['id'];
        final Place? enriched = enrichedPlaceMap[id];

        enrichedListForAI.add({
          'id': id,
          'name': placeJson['name'],
          'rating': placeJson['rating'],
          'tags': enriched?.tags ?? [],
          'pictureCategory': enriched?.pictureCategory ?? 'default',
          'isFavorite': placeJson['isFavorite'] ?? false,
        });
      }

      final HttpsCallable mainPick = functions.httpsCallable('mainPick');
      print('[LIST PASSED TO AI], $enrichedListForAI');
      final HttpsCallableResult aiResponse = await mainPick.call({
        'data': enrichedListForAI,
      });

      final dynamic recommendation = aiResponse.data['result'];
      print(recommendation);

      if (recommendation == null || recommendation.isEmpty) {
        print('[AI] RECOMMENDATION EMPTY');
        return [];
      }

      print('[AI] RECOMMENDATION RECEIVED: ${recommendation['id']}');

      final String recId = recommendation['id'];
      // final List<String> recTags = List<String>.from(recommendation['tags'] ?? []);
      // final String recCat = recommendation['pictureCategory'] ?? 'default';

      final Place? matched = enrichedPlaceMap[recId];
      if (matched == null) {
        print('[AI] No match found for recommended ID: $recId');
        return [];
      }

      // final updatedPlace = matched.copyWith(
      //   tags: recTags,
      //   pictureCategory: recCat,
      // );

      return [matched];
    } catch (e) {
      print('[ERROR AI] Failed to get AI recommendations: $e');
      return [];
    }
  }

  Future<void> waitForPlacesReady(RestaurantProvider provider) async {
    if (provider.places.isNotEmpty) {
        print('[AI] Places are provided');
        return;
    }

    print('[AI] Waiting for provider');
    final completer = Completer<void>();

    late VoidCallback listener; 

    listener = () {
      if (provider.places.isNotEmpty && !completer.isCompleted) {
        completer.complete();
        provider.removeListener(listener);
      }
    };

    provider.addListener(listener);
    return completer.future;
  }
}
