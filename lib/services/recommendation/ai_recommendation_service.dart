import 'dart:async';
import 'package:chefoo/commons.dart';
import 'package:chefoo/models/restaurant.dart';
import 'package:chefoo/providers/restaurant.dart';
import 'package:chefoo/services/maps.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class RecommendationService {
  final RestaurantProvider restaurantProvider;
  final PlaceService placeService;
  final FirebaseFunctions functions;

  RecommendationService({
    required this.restaurantProvider,
    required this.placeService,
    FirebaseFunctions? firebaseFunctions,
  }) : functions = firebaseFunctions ?? FirebaseFunctions.instance;

  Map<String, List<Place>> _emptyResult() => {
        'recommended': [],
        'enriched': [],
      };

  Future<Map<String, Place>> _enrichPlacesWithTagsAndBanner(
    List<Place> places, {
    int batchSize = 5,
  }) async {
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
      final enrichedListForAI = placesList.map((placeJson) {
        final enriched = enrichedPlaceMap[placeJson['id']];
        return {
          'id': placeJson['id'],
          'name': placeJson['name'],
          'rating': placeJson['rating'],
          'tags': enriched?.tags ?? [],
          'pictureCategory': enriched?.pictureCategory ?? 'default',
          'isFavorite': placeJson['isFavorite'] ?? false,
        };
      }).toList();

      final aiCall = functions.httpsCallable('mainPick');
      print('[AI INPUT] $enrichedListForAI');
      final response = await aiCall.call({'data': enrichedListForAI});

      final recommendation = response.data['result'];
      if (recommendation == null || recommendation.isEmpty) {
        print('[AI] No recommendation received.');
        return [];
      }

      print('[AI] Recommendation received: ${recommendation['id']}');

      final matched = enrichedPlaceMap[recommendation['id']];
      if (matched == null) {
        print('[AI] No match found for recommended ID.');
        return [];
      }

      return [
        matched.copyWith(
          tags: List<String>.from(recommendation['tags'] ?? []),
          pictureCategory: recommendation['pictureCategory'] ?? 'default',
        )
      ];
    } catch (e) {
      print('[ERROR AI] $e');
      return [];
    }
  }

  Future<Map<String, List<Place>>> fetchRecommendedFromProvider({
    required double lat,
    required double lng,
    double radiusMeters = 3000.0,
  }) async {
    print('[AI] Fetching from provider...');

    try {
      final combined = [...restaurantProvider.routePlaces, ...restaurantProvider.places];
      final Set<String> seen = {};
      final List<Place> filtered = [];

      for (final place in combined) {
        if (seen.add(place.id)) {
          final dist = calculateGeoDistance(lat, lng, place.lat, place.lng);
          if (dist <= radiusMeters) {
            place.walkingDistance = dist / 1000;
            filtered.add(place);
          }
        }
      }

      if (filtered.isEmpty) return _emptyResult();

      final enrichedMap = await _enrichPlacesWithTagsAndBanner(filtered);
      final placesList = enrichedMap.values.map((p) => p.toJson()).toList();
      final recommended = await _getRecommendedPlacesFromAI(placesList, enrichedMap);

      final recommendedIds = recommended.map((p) => p.id).toSet();
      final enrichedOnly = enrichedMap.values.where((p) => !recommendedIds.contains(p.id)).toList();

      return {
        'recommended': recommended,
        'enriched': enrichedOnly,
      };
    } catch (e) {
      print('[ERROR FETCH] $e');
      return _emptyResult();
    }
  }

  Future<void> waitForPlacesReady(RestaurantProvider provider) async {
    if (provider.places.isNotEmpty || provider.routePlaces.isNotEmpty) return;
    final completer = Completer<void>();

    late VoidCallback listener;
    listener = () {
      if ((provider.places.isNotEmpty || provider.routePlaces.isNotEmpty) && !completer.isCompleted) {
        completer.complete();
        provider.removeListener(listener);
      }
    };

    provider.addListener(listener);
    return completer.future;
  }

  Future<Place?> fetchSingleRecommendationFromAIQuery({
    required String message,
    required String uid,
    bool includeRoutePlaces = true,
  }) async {
    try {
      final List<Place> combined = includeRoutePlaces
          ? [...restaurantProvider.routePlaces, ...restaurantProvider.places]
          : [...restaurantProvider.places];

      final Set<String> seen = {};
      final List<Place> unique = [];
      for (final place in combined) {
        if (seen.add(place.id)) {
          unique.add(place);
        }
      }

      if (unique.isEmpty) {
        print('[msgAI] No available places to evaluate.');
        return null;
      }

      final enrichedMap = await _enrichPlacesWithTagsAndBanner(unique);

      final restaurants = unique.map((place) {
        final enriched = enrichedMap[place.id];
        return {
          'id': place.id,
          'name': place.name,
          'rating': place.rating,
          'tags': enriched?.tags ?? [],
          'isFavorite': false, // Optional: link with FavoritesProvider if needed
        };
      }).toList();

      final msgAiCall = functions.httpsCallable('msgAI');
      final response = await msgAiCall.call({
        'message': message,
        'restaurants': restaurants,
      });

      final result = response.data;
      if (result == null || result['id'] == null) {
        print('[msgAI] No valid recommendation from AI.');
        return null;
      }

      final matched = enrichedMap[result['id']];
      if (matched == null) {
        print('[msgAI] Could not find matching place for ID ${result['id']}');
        return null;
      }

      return matched.copyWith(
        tags: List<String>.from(result['tags'] ?? matched.tags),
        pictureCategory: result['pictureCategory'] ?? matched.pictureCategory,
      );
    } catch (e) {
      print('[msgAI ERROR] Failed to fetch AI recommendation: $e');
      return null;
    }
  }
}


// import 'dart:async';

// import 'package:chefoo/commons.dart';
// import 'package:chefoo/models/restaurant.dart';
// import 'package:chefoo/providers/restaurant.dart';
// import 'package:chefoo/services/maps.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:cloud_functions/cloud_functions.dart';

// class RecommendationService  {
//   final RestaurantProvider restaurantProvider;
//   final PlaceService placeService;
//   final FirebaseFunctions functions;

//   RecommendationService ({
//     required this.restaurantProvider,
//     required this.placeService,
//     FirebaseFunctions? firebaseFunctions,
//   }) : functions = firebaseFunctions ?? FirebaseFunctions.instance;

//   Map<String, List<Place>> _emptyResult() {
//     return {
//         'recommended': [],
//         'enriched': [],
//     };
//   }

//   Future<Map<String, Place>> _enrichPlacesWithTagsAndBanner(
//     List<Place> places,
//     {int batchSize = 5}
//     ) async {
//     final Map<String, Place> enrichedMap = {};

//     for (int i = 0; i < places.length; i += batchSize) {
//         final batch = places.sublist(
//             i,
//             (i + batchSize > places.length) ? places.length : i + batchSize,
//         );

//       final List<Future<void>> tasks = batch.map((place) async {
//         try {
//             final tagCall = functions.httpsCallable('generateTagsAndBanner');
//             final result = await tagCall.call({'name': place.name});
//             final tags = List<String>.from(result.data['tags']);
//             final category = result.data['pictureCategory'];

//             enrichedMap[place.id] = place.copyWith(
//                 tags: tags,
//                 pictureCategory: category,
//             );

//             print('[ENRICH] ${place.name} => Tags: $tags, Category: $category');
//         } catch (e) {
//             print('[ENRICH] Failed to enrich ${place.name}: $e');
//             enrichedMap[place.id] = place;
//         }
//       }).toList();

//     await Future.wait(tasks);
//     }
//     print('[ENRICH] Done with enriching places.');
//     return enrichedMap;
//   }

//     Future<List<Place>> _getRecommendedPlacesFromAI(
//     List<Map<String, dynamic>> placesList,
//     Map<String, Place> enrichedPlaceMap,
//   ) async {
//     try {
//       final List<Map<String, dynamic>> enrichedListForAI = [];

//       for (final placeJson in placesList) {
//         final String id = placeJson['id'];
//         final Place? enriched = enrichedPlaceMap[id];

//         enrichedListForAI.add({
//           'id': id,
//           'name': placeJson['name'],
//           'rating': placeJson['rating'],
//           'tags': enriched?.tags ?? [],
//           'pictureCategory': enriched?.pictureCategory ?? 'default',
//           'isFavorite': placeJson['isFavorite'] ?? false,
//         });
//       }

//       final HttpsCallable mainPick = functions.httpsCallable('mainPick');
//       print('[LIST PASSED TO AI], $enrichedListForAI');
//       final HttpsCallableResult aiResponse = await mainPick.call({
//         'data': enrichedListForAI,
//       });

//       final dynamic recommendation = aiResponse.data['result'];
//       print(recommendation);

//       if (recommendation == null || recommendation.isEmpty) {
//         print('[AI] RECOMMENDATION EMPTY');
//         return [];
//       }

//       print('[AI] RECOMMENDATION RECEIVED: ${recommendation['id']}');

//       final String recId = recommendation['id'];
//       final List<String> recTags = List<String>.from(recommendation['tags'] ?? []);
//       final String recCat = recommendation['pictureCategory'] ?? 'default';

//       final Place? matched = enrichedPlaceMap[recId];
//       if (matched == null) {
//         print('[AI] No match found for recommended ID: $recId');
//         return [];
//       }

//       final updatedPlace = matched.copyWith(
//         tags: recTags,
//         pictureCategory: recCat,
//       );

//       return [updatedPlace];
//     } catch (e) {
//       print('[ERROR AI] Failed to get AI recommendations: $e');
//       return [];
//     }
//   }

//   Future<Map<String, List<Place>>>fetchRecommendedPlacesFromCache({
//     required double lat,
//     required double lng,
//   }) async {
//     print('[AI] Start AI recommendation using cached places');

//     try {
//       final availablePlaces = await getCachedPlacesByPriority(lat: lat, lng: lng);

//       if (availablePlaces.isEmpty) {
//         return _emptyResult();
//       }

//       print('[AI] Cached Places (${availablePlaces.length}) provided: ${availablePlaces.map((p) => p.toJson()).toList()}');

//       final enrichedPlaceMap = await _enrichPlacesWithTagsAndBanner(availablePlaces);

//       final placesList = enrichedPlaceMap.values.map((p) => p.toJson()).toList();

//       final List<Place> recommendedPlaces =
//           await _getRecommendedPlacesFromAI(placesList, enrichedPlaceMap);

//       final Set<String> recommendedIds = recommendedPlaces.map((p) => p.id).toSet();
//       final List<Place> filteredEnriched = enrichedPlaceMap.values
//           .where((p) => !recommendedIds.contains(p.id))
//           .toList();

//       return {
//         'recommended': recommendedPlaces,
//         'enriched': filteredEnriched,
//       };
//     } catch (e) {
//       print('[ERROR FETCH] Exception during fetchFromCache: $e');
//       return _emptyResult();
//     }
//   }


//   Future<void> waitForPlacesReady(RestaurantProvider provider) async {
//     if (provider.places.isNotEmpty) {
//         print('[AI] Places are provided');
//         return;
//     }

//     print('[AI] Waiting for provider');
//     final completer = Completer<void>();

//     late VoidCallback listener; 

//     listener = () {
//       if ((provider.places.isNotEmpty || provider.routePlaces.isNotEmpty) && !completer.isCompleted) {
//         completer.complete();
//         provider.removeListener(listener);
//       }
//     };

//     provider.addListener(listener);
//     print('[AI] Completing the wait...');
//     return completer.future;
//   }

  // Future<List<Place>> getCachedPlacesByPriority({
  //   required double lat,
  //   required double lng,
  //   List<double> radiusPriority = const [3000.0, 2000.0, 1500.0, 1000.0],
  // }) async {
  //   final baseKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  //   final List<Place> allPlaces = [];
  //   final Set<String> seenPlaceIds = {};

  //   for (final radius in radiusPriority) {
  //     final cacheKey = '${baseKey}_${radius.toStringAsFixed(1)}';
  //     final places = placeService.cachedPlaces[cacheKey];

  //     if (places != null && places.isNotEmpty) {
  //       for (final place in places) {
  //         if (seenPlaceIds.add(place.id)) {
  //           allPlaces.add(place);
  //         }
  //       }
  //       print('[CACHE] Added places from $cacheKey (${places.length} entries, ${allPlaces.length} unique so far)');
  //     }
  //   }

  //   if (allPlaces.isEmpty) {
  //     print('[CACHE] No cached places found for any radius at location: $baseKey');
  //   }

  //   return allPlaces;
  // }
//   Future<List<Place>> getCachedPlacesByPriority({
//     required double lat,
//     required double lng,
//     double radiusMeters = 3000.0, // You can customize this if needed
//   }) async {
//     final List<Place> allPlaces = [];
//     final Set<String> seenPlaceIds = {};

//     final combinedPlaces = [
//       ...restaurantProvider.routePlaces,
//       ...restaurantProvider.places,
//     ];

//     for (final place in combinedPlaces) {
//       if (seenPlaceIds.add(place.id)) {
//         final distance = calculateGeoDistance(lat, lng, place.lat, place.lng);
//         if (distance <= radiusMeters) {
//           place.walkingDistance = distance / 1000;
//           allPlaces.add(place);
//         }
//       }

//       print('[AI] Place ${place.name} has distance: ${place.walkingDistance}.');
//     }

//     if (allPlaces.isEmpty) {
//       print('[CACHE] No suitable places found near: $lat, $lng');
//     } else {
//       print('[CACHE] Filtered ${allPlaces.length} places within $radiusMeters meters.');
//     }

//     return allPlaces;
//   }
// }
